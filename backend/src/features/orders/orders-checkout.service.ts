import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  Logger,
  Optional,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  OrdersRepository,
  CreateOrderData,
  OrderItemData,
} from './orders.repository';
import { CartService } from '../cart/cart.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';
import { OrderActivePolicyHelper } from './helpers/order-active-policy.helper';
import {
  PlaceOrderDto,
  PlaceCustomOrderDto,
  PlaceDirectOrderDto,
} from './dto/order.dto';
import {
  OrderCreatedEvent,
  OrderStatusChangedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  PaymentMethod,
  Role,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  OrderErrors,
  CustomerErrors,
} from '../../common/constants/response.constants';

@Injectable()
export class OrdersCheckoutService {
  private readonly logger = new Logger(OrdersCheckoutService.name);

  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly cartService: CartService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    @Optional() private readonly multiVendorService?: OrdersMultiVendorService,
    @Optional() private readonly activePolicyHelper?: OrderActivePolicyHelper,
  ) {}

  private get activePolicy(): OrderActivePolicyHelper {
    return (
      this.activePolicyHelper ??
      new OrderActivePolicyHelper(this.prisma, this.platformSettings)
    );
  }

  async placeOrder(
    actor: JwtAccessPayload,
    dto: PlaceOrderDto,
    idempotencyKey?: string,
  ) {
    const clientOrderKey = idempotencyKey?.trim() || null;
    if (clientOrderKey) {
      const existing = await this.ordersRepository.findByClientOrderKeyForUser(
        clientOrderKey,
        actor.sub,
      );
      if (existing) {
        return existing;
      }
    }

    const { customerId, coinBalance, cart } =
      await this.cartService.validateForCheckout(actor.sub, dto.vendorId);

    const activeOrderPolicy =
      await this.validateActiveOrderLimit(customerId);

    const money = await this.computeStandardOrderMoney(
      dto.vendorId,
      cart.subtotal,
      dto.deliveryLocation,
      dto.paymentMethod,
      dto.coinsToUse,
      coinBalance,
      this.productIdsFromItems(cart.items),
      true,
    );

    if (money.requiresMultiBranch && this.multiVendorService) {
      return this.multiVendorService.placeSingleVendorMultiBranch(
        actor,
        dto,
        idempotencyKey,
      );
    }
    if (money.requiresMultiBranch) {
      throw new BadRequestException(OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH);
    }

    await this.cartService.assertItemsAvailableAtBranch(
      cart.items,
      money.branch.id,
    );

    const items: OrderItemData[] = cart.items.map((item: any) => {
      const itemOptions = item.options.map((opt) => ({
        optionId: opt.id,
        optionName: opt.name,
        groupName: opt.groupName ?? null,
        priceAdded: Math.round(Number(opt.priceAdded)),
      }));
      const optionsTotal = itemOptions.reduce((s, o) => s + o.priceAdded, 0);
      return {
        productId: item.productId,
        variantId: item.variantId ?? null,
        productName: item.product.name ?? 'Unknown Product',
        variantName: item.variant?.name ?? null,
        unitPrice: Math.round(item.unitPrice),
        quantity: item.quantity,
        selectedUnit: item.selectedUnit ?? null,
        // Pre-options unit price (post-offer, post-strip): totalPrice must
        // always equal (baseUnitPrice + Σoptions) × quantity. Auditable forever.
        baseUnitPrice: Math.round(item.unitPrice) - optionsTotal,
        totalPrice: Math.round(item.totalPrice),
        specialRequest: item.specialRequest ?? null,
        options: itemOptions,
      };
    });

    const orderNumber = await this.ordersRepository.generateOrderNumber();
    const created = await this.ordersRepository.createOrder(
      {
        orderNumber,
        clientOrderKey,
        customerId,
        vendorId: dto.vendorId ?? null,
        vendorBranchId: money.branch?.id ?? null,
        zoneId: money.zone?.id ?? null,
        paymentMethod: dto.paymentMethod,
        deliveryAddress: dto.deliveryAddress,
        deliveryLng: dto.deliveryLocation[0],
        deliveryLat: dto.deliveryLocation[1],
        subtotal: cart.subtotal,
        deliveryFee: money.deliveryFee,
        driverBonusFee: money.driverBonusFee,
        serviceFee: money.serviceFee,
        tax: money.tax,
        discount: money.discount,
        coinsUsed: money.coinsUsed,
        coinsEarned: money.coinsEarned,
        grandTotal: money.grandTotal,
        upfrontAmount: money.upfrontAmount,
        distanceKm: money.distanceKm,
        specialRequest: dto.specialRequest ?? null,
        type: 'STANDARD',
        pickupAddress: money.branch?.address ?? null,
        pickupLng: money.branch?.lng ?? null,
        pickupLat: money.branch?.lat ?? null,
        itemDetails: null,
        requestedVehicleType: null,
        activeOrderPolicy,
      },
      items,
      actor.sub,
    );

    // The cart listener will catch ORDER_CREATED and clear the cart automatically.

    if (created.created) {
      const vendorUserIds = await this.ordersRepository.getVendorUserIds(
        dto.vendorId,
        money.branch?.id ?? null,
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_CREATED,
        new OrderCreatedEvent(
          created.id,
          created.orderNumber,
          customerId,
          actor.sub,
          dto.vendorId,
          vendorUserIds,
          money.grandTotal,
          dto.paymentMethod,
          'STANDARD',
          0,
          [dto.vendorId],
        ),
      );

      this.logger.log(
        `Order placed: ${created.orderNumber} by user ${actor.sub}`,
      );
    }

    return this.ordersRepository.findById(created.id);
  }

  async estimateOrder(actor: JwtAccessPayload, dto: PlaceOrderDto) {
    const { coinBalance, cart } = await this.cartService.validateForCheckout(
      actor.sub,
      dto.vendorId,
    );

    const money = await this.computeStandardOrderMoney(
      dto.vendorId,
      cart.subtotal,
      dto.deliveryLocation,
      dto.paymentMethod,
      dto.coinsToUse,
      coinBalance,
      this.productIdsFromItems(cart.items),
      true,
    );

    if (money.requiresMultiBranch && this.multiVendorService) {
      return this.multiVendorService.estimateSingleVendorMultiBranch(actor, dto);
    }
    if (money.requiresMultiBranch) {
      throw new BadRequestException(OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH);
    }

    await this.cartService.assertItemsAvailableAtBranch(
      cart.items,
      money.branch.id,
    );

    return {
      distanceKm: money.distanceKm,
      deliveryFee: money.deliveryFee,
      serviceFee: money.serviceFee,
      driverBonusFee: money.driverBonusFee,
      tax: money.tax,
      coinsUsed: money.coinsUsed,
      discount: money.discount,
      coinsEarned: money.coinsEarned,
      grandTotal: money.grandTotal,
      upfrontAmount: money.upfrontAmount,
    };
  }

  async estimateCustomOrder(actor: JwtAccessPayload, dto: PlaceCustomOrderDto) {
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { coinBalance: true },
    });
    if (!customer)
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);

    const money = await this.computeCustomOrderMoney(dto, customer.coinBalance);

    return {
      distanceKm: money.distanceKm,
      deliveryFee: money.deliveryFee,
      serviceFee: money.serviceFee,
      driverBonusFee: money.driverBonusFee,
      tax: money.tax,
      coinsUsed: money.coinsUsed,
      discount: money.discount,
      coinsEarned: money.coinsEarned,
      grandTotal: money.grandTotal,
      upfrontAmount: money.upfrontAmount,
    };
  }

  private productIdsFromItems(
    items: Array<{ productId?: string | null }>,
  ): string[] {
    return [
      ...new Set(
        items
          .map((item) => item.productId)
          .filter((id): id is string => Boolean(id)),
      ),
    ];
  }

  private async computeStandardOrderMoney(
    vendorId: string,
    subtotal: number,
    deliveryLocation: [number, number],
    paymentMethod: PaymentMethod,
    coinsToUse: number | undefined,
    coinBalance: number | null,
    productIds: string[] = [],
    allowMultiBranchFallback = false,
  ) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      select: {
        id: true,
        status: true,
        commissionRate: true,
        isContracted: true,
      },
    });
    if (!vendor || vendor.status !== 'OPEN') {
      throw new BadRequestException(OrderErrors.VENDOR_NOT_ACCEPTING);
    }

    const settings = await this.platformSettings.getSettings();

    const [lng, lat] = deliveryLocation;
    const zone = await this.ordersRepository.getZoneAtLocation(lng, lat);
    if (!zone) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    const minOrder = Number(
      zone.minOrderAmountOverride ?? settings.minOrderAmount,
    );
    if (minOrder > 0 && subtotal < minOrder) {
      throw new BadRequestException(OrderErrors.MIN_ORDER_AMOUNT_NOT_MET);
    }

    const branch = await this.ordersRepository.getNearestOpenBranchLocation(
      vendorId,
      lng,
      lat,
      zone?.id,
      productIds,
    );
    // The branch lookup only considers open branches geometrically inside the
    // customer's delivery zone, so a returned branch is always in that zone.
    // It also requires every cart product to be available at that branch.
    if (!branch) {
      if (allowMultiBranchFallback && productIds.length > 0 && this.multiVendorService) {
        return { requiresMultiBranch: true as const };
      }
      if (productIds.length > 0) {
        const anyOpenBranch =
          await this.ordersRepository.getNearestOpenBranchLocation(
            vendorId,
            lng,
            lat,
            zone?.id,
          );
        if (anyOpenBranch) {
          throw new BadRequestException(
            OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
          );
        }
      }
      // Without an open branch there is no pickup point for the driver, so the
      // order cannot be fulfilled at all.
      throw new BadRequestException(OrderErrors.NO_OPEN_BRANCH);
    }
    const distanceKm = await this.ordersRepository.getDistanceKm(
      branch.lng,
      branch.lat,
      lng,
      lat,
    );

    const maxRadius = Number(settings.maxDeliveryRadiusKm ?? 1500);
    if (maxRadius > 0 && distanceKm > maxRadius) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    const deliveryFee = await this.platformSettings.calculateDeliveryFee(
      distanceKm,
      zone?.baseDeliveryFeeOverride ?? null,
      null,
      true,
      settings,
    );

    const branchCommission =
      typeof branch !== 'undefined' && branch?.commissionRate != null
        ? Number(branch.commissionRate)
        : null;
    const vendorCommission =
      branchCommission != null
        ? branchCommission
        : (vendor.commissionRate != null
            ? Number(vendor.commissionRate)
            : Number(settings.defaultCommissionRate ?? 10));
    const commissionRate = vendorCommission / 100;
    const isContracted =
      (typeof branch !== 'undefined' && branch?.isContracted != null)
        ? branch.isContracted
        : vendor.isContracted;

    const serviceFee = !isContracted
      ? Math.round(subtotal * commissionRate)
      : 0;

    const taxRate = Number(settings.defaultTaxRate) / 100;
    const tax = Math.round((subtotal + serviceFee) * taxRate);

    let driverBonusFee = 0;
    const now = new Date();
    if (
      settings.driverBonusActive &&
      settings.driverBonusAmount &&
      settings.driverBonusAmount > 0 &&
      settings.driverBonusStartDate &&
      settings.driverBonusEndDate &&
      now >= settings.driverBonusStartDate &&
      now <= settings.driverBonusEndDate
    ) {
      driverBonusFee = Number(settings.driverBonusAmount);
    }

    let preDiscountTotal = subtotal + deliveryFee + serviceFee + tax;
    if (settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      preDiscountTotal += driverBonusFee;
    }

    let coinsUsed = 0;
    let discount = 0;
    if (coinsToUse && coinsToUse > 0) {
      if (!coinBalance || coinBalance < Number(settings.minCoinsToUse)) {
        throw new BadRequestException(CustomerErrors.MINIMUM_COINS_REQUIRED);
      }
      if (coinBalance < coinsToUse) {
        throw new BadRequestException(CustomerErrors.INSUFFICIENT_COIN_BALANCE);
      }
      coinsUsed = coinsToUse;
      const coinValue = Number(settings.coinValue) || 0;
      discount = coinsUsed * coinValue;
      if (discount > preDiscountTotal) {
        discount = preDiscountTotal;
        coinsUsed = coinValue > 0 ? Math.ceil(discount / coinValue) : 0;
      }
    }

    const grandTotal = preDiscountTotal - discount;
    const amountSpentPerCoin = Number(settings.amountSpentPerCoin) || 0;
    const coinsEarned =
      amountSpentPerCoin > 0 ? Math.floor(grandTotal / amountSpentPerCoin) : 0;

    let upfrontAmount = 0;
    if (
      paymentMethod === 'CASH_ON_DELIVERY' &&
      settings.highValueOrderThreshold &&
      settings.highValueOrderThreshold > 0 &&
      grandTotal >= settings.highValueOrderThreshold
    ) {
      upfrontAmount = Math.round(
        grandTotal * (Number(settings.highValueUpfrontRate ?? 0) / 100),
      );
    }

    return {
      requiresMultiBranch: false as const,
      vendor,
      zone,
      branch,
      distanceKm,
      deliveryFee,
      serviceFee,
      driverBonusFee,
      tax,
      discount,
      coinsUsed,
      coinsEarned,
      grandTotal,
      upfrontAmount,
      driverBonusPaidByCustomer: Boolean(settings.driverBonusPaidByCustomer),
    };
  }

  private async computeCustomOrderMoney(
    dto: PlaceCustomOrderDto,
    coinBalance: number,
  ) {
    if (dto.type === 'RIDE' && dto.vehicleType !== 'CAR') {
      throw new BadRequestException(OrderErrors.RIDES_MUST_USE_CAR);
    }

    const [pickupLng, pickupLat] = dto.pickupLocation;
    const [deliveryLng, deliveryLat] = dto.deliveryLocation;

    const distanceKm = await this.ordersRepository.getDistanceKm(
      pickupLng,
      pickupLat,
      deliveryLng,
      deliveryLat,
    );

    const settings = await this.platformSettings.getSettings();
    const maxRadius = Number(settings.maxDeliveryRadiusKm ?? 1500);
    if (maxRadius > 0 && distanceKm > maxRadius) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    if (dto.vehicleType === 'BICYCLE') {
      const maxBicycleKm = Number(settings.maxKmForBicycle ?? 5.0);
      if (distanceKm > maxBicycleKm) {
        throw new BadRequestException(OrderErrors.BICYCLE_DISTANCE_EXCEEDED);
      }
    }

    let perKm = 0;
    switch (dto.vehicleType) {
      case 'BICYCLE':
        if (!settings.allowBicycle)
          throw new BadRequestException(OrderErrors.VEHICLE_TYPE_DISABLED);
        perKm = Number(settings.pricePerKmBicycle);
        break;
      case 'MOTORCYCLE':
        if (!settings.allowMotorcycle)
          throw new BadRequestException(OrderErrors.VEHICLE_TYPE_DISABLED);
        perKm = Number(settings.pricePerKmMotorcycle);
        break;
      case 'CAR':
        if (!settings.allowCar)
          throw new BadRequestException(OrderErrors.VEHICLE_TYPE_DISABLED);
        perKm = Number(settings.pricePerKmCar);
        break;
      case 'VAN':
        if (!settings.allowVan)
          throw new BadRequestException(OrderErrors.VEHICLE_TYPE_DISABLED);
        perKm = Number(settings.pricePerKmVan);
        break;
      case 'TRUCK':
        if (!settings.allowTruck)
          throw new BadRequestException(OrderErrors.VEHICLE_TYPE_DISABLED);
        perKm = Number(settings.pricePerKmTruck);
        break;
      case 'MOTOR_TRICYCLE':
        if (!settings.allowMotorTricycle)
          throw new BadRequestException(OrderErrors.VEHICLE_TYPE_DISABLED);
        perKm = Number(settings.pricePerKmMotorTricycle);
        break;
    }

    const deliveryFee = await this.platformSettings.calculateDeliveryFee(
      distanceKm,
      null, // no zone override
      perKm,
      false, // isStandardOrder
      settings,
      dto.vehicleType,
    );
    const serviceFee = Number(settings.customOrderPlatformFee) || 0;
    const taxRate = Number(settings.defaultTaxRate) / 100;
    const tax = Math.round(serviceFee * taxRate);

    let driverBonusFee = 0;
    const now = new Date();
    if (
      settings.driverBonusActive &&
      settings.driverBonusAmount &&
      settings.driverBonusAmount > 0 &&
      settings.driverBonusStartDate &&
      settings.driverBonusEndDate &&
      now >= settings.driverBonusStartDate &&
      now <= settings.driverBonusEndDate
    ) {
      driverBonusFee = Number(settings.driverBonusAmount);
    }

    let preDiscountTotal = deliveryFee + serviceFee + tax;
    if (settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      preDiscountTotal += driverBonusFee;
    }

    let coinsUsed = 0;
    let discount = 0;
    if (dto.coinsToUse && dto.coinsToUse > 0) {
      if (coinBalance < Number(settings.minCoinsToUse)) {
        throw new BadRequestException(CustomerErrors.MINIMUM_COINS_REQUIRED);
      }
      if (coinBalance < dto.coinsToUse) {
        throw new BadRequestException(CustomerErrors.INSUFFICIENT_COIN_BALANCE);
      }
      coinsUsed = dto.coinsToUse;
      const coinValue = Number(settings.coinValue) || 0;
      discount = coinsUsed * coinValue;
      if (discount > preDiscountTotal) {
        discount = preDiscountTotal;
        coinsUsed = coinValue > 0 ? Math.ceil(discount / coinValue) : 0;
      }
    }

    const grandTotal = preDiscountTotal - discount;
    const amountSpentPerCoin = Number(settings.amountSpentPerCoin) || 0;
    const coinsEarned =
      amountSpentPerCoin > 0 ? Math.floor(grandTotal / amountSpentPerCoin) : 0;

    let upfrontAmount = 0;
    if (
      dto.paymentMethod === 'CASH_ON_DELIVERY' &&
      settings.highValueOrderThreshold &&
      settings.highValueOrderThreshold > 0 &&
      grandTotal >= settings.highValueOrderThreshold
    ) {
      upfrontAmount = Math.round(
        grandTotal * (Number(settings.highValueUpfrontRate ?? 0) / 100),
      );
    }

    return {
      pickupLng,
      pickupLat,
      deliveryLng,
      deliveryLat,
      distanceKm,
      deliveryFee,
      serviceFee,
      driverBonusFee,
      tax,
      discount,
      coinsUsed,
      coinsEarned,
      grandTotal,
      upfrontAmount,
      driverBonusPaidByCustomer: Boolean(settings.driverBonusPaidByCustomer),
    };
  }

  async placeCustomOrder(
    actor: JwtAccessPayload,
    dto: PlaceCustomOrderDto,
    idempotencyKey?: string,
  ) {
    const clientOrderKey = idempotencyKey?.trim() || null;
    if (clientOrderKey) {
      const existing = await this.ordersRepository.findByClientOrderKeyForUser(
        clientOrderKey,
        actor.sub,
      );
      if (existing) {
        return existing;
      }
    }

    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true, coinBalance: true },
    });
    if (!customer)
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
    const customerId = customer.id;

    const activeOrderPolicy =
      await this.validateActiveOrderLimit(customerId);

    const money = await this.computeCustomOrderMoney(dto, customer.coinBalance);
    const {
      pickupLng,
      pickupLat,
      deliveryLng,
      deliveryLat,
      distanceKm,
      deliveryFee,
      serviceFee,
      driverBonusFee,
      tax,
      discount,
      coinsUsed,
      coinsEarned,
      grandTotal,
      upfrontAmount,
    } = money;

    const orderNumber = await this.ordersRepository.generateOrderNumber();
    const created = await this.ordersRepository.createOrder(
      {
        orderNumber,
        clientOrderKey,
        customerId,
        vendorId: null,
        vendorBranchId: null,
        zoneId: null, // Custom orders might not be restricted to zones
        paymentMethod: dto.paymentMethod,
        deliveryAddress: dto.deliveryAddress,
        deliveryLng,
        deliveryLat,
        subtotal: 0,
        deliveryFee,
        driverBonusFee,
        serviceFee,
        tax,
        discount,
        coinsUsed,
        coinsEarned,
        grandTotal,
        upfrontAmount,
        distanceKm,
        specialRequest: dto.specialRequest ?? null,
        type: dto.type,
        pickupAddress: dto.pickupAddress,
        pickupLng,
        pickupLat,
        itemDetails: dto.itemDetails ?? null,
        requestedVehicleType: dto.vehicleType,
        activeOrderPolicy,
      },
      [], // No items
      actor.sub,
    );

    // Custom Orders (CUSTOM_DELIVERY / RIDE) have no vendor to accept them:
    // Always advance immediately to LOOKING_FOR_DRIVER so dispatch assigns a driver;
    // when a driver accepts, DispatchService.handleAcceptance moves it to PENDING_PAYMENT
    // if MOBILE_WALLET or upfrontAmount > 0 is required.
    if (created.created) {
      await this.prisma.orderDeliveryGroup.updateMany({
        where: { orderId: created.id, status: DeliveryGroupStatus.PENDING },
        data: { status: DeliveryGroupStatus.LOOKING_FOR_DRIVER },
      });

      const advanced = await this.ordersRepository.updateStatus(
        created.id,
        'LOOKING_FOR_DRIVER',
        'system',
        'Auto-dispatched custom order',
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_STATUS_CHANGED,
        new OrderStatusChangedEvent(
          created.id,
          created.orderNumber,
          OrderStatus.PENDING,
          OrderStatus.LOOKING_FOR_DRIVER,
          customerId,
          actor.sub,
          null,
          [],
          null,
          null,
          'system',
          'Auto-dispatched custom order',
          advanced.revision,
        ),
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_CREATED,
        new OrderCreatedEvent(
          created.id,
          created.orderNumber,
          customerId,
          actor.sub,
          null, // No vendor
          [], // No vendor members
          grandTotal,
          dto.paymentMethod,
          dto.type,
          0, // revision of the created row (v0); must match outbox row at orders.repository.ts:1037
        ),
      );

      this.logger.log(
        `${dto.type} order placed: ${created.orderNumber} by user ${actor.sub}`,
      );
    }

    return this.ordersRepository.findById(created.id);
  }

  async adminPlaceDirectOrder(
    actor: JwtAccessPayload,
    dto: PlaceDirectOrderDto,
    idempotencyKey?: string,
  ) {
    const clientOrderKey = idempotencyKey?.trim() || null;
    if (actor.role !== Role.SUPER_ADMIN && actor.role !== Role.ADMIN) {
      const isVendorMember = await this.prisma.vendorMember.findUnique({
        where: {
          vendorId_userId: { vendorId: dto.vendorId, userId: actor.sub },
        },
      });
      if (
        !isVendorMember ||
        (isVendorMember.role !== 'OWNER' &&
          isVendorMember.role !== 'STAFF' &&
          isVendorMember.role !== 'MANAGER')
      ) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
      }
    }

    const customer = await this.prisma.customer.findUnique({
      where: { userId: dto.customerId },
    });
    if (!customer)
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);

    const activeOrderPolicy =
      await this.validateActiveOrderLimit(customer.id);

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: dto.vendorId },
    });
    if (!vendor) throw new NotFoundException(OrderErrors.NOT_AUTHORIZED_VENDOR);

    const hasDeliveryCoords =
      Array.isArray(dto.deliveryLocation) &&
      dto.deliveryLocation.length === 2 &&
      Number.isFinite(Number(dto.deliveryLocation[0])) &&
      Number.isFinite(Number(dto.deliveryLocation[1]));
    const deliveryLng = hasDeliveryCoords ? Number(dto.deliveryLocation![0]) : 0;
    const deliveryLat = hasDeliveryCoords ? Number(dto.deliveryLocation![1]) : 0;

    const zone = hasDeliveryCoords
      ? await this.ordersRepository.getZoneAtLocation(deliveryLng, deliveryLat)
      : null;

    let branch =
      (hasDeliveryCoords
        ? await this.ordersRepository.getNearestOpenBranchLocation(
            dto.vendorId,
            deliveryLng,
            deliveryLat,
            zone?.id,
            dto.productId ? [dto.productId] : [],
          )
        : null) ??
      (hasDeliveryCoords
        ? await this.ordersRepository.getNearestOpenBranchLocation(
            dto.vendorId,
            deliveryLng,
            deliveryLat,
          )
        : null);

    if (!branch) {
      const fallbackBranch = await this.prisma.vendorBranch.findFirst({
        where: { vendorId: dto.vendorId },
        orderBy: [{ isOpen: 'desc' }, { createdAt: 'asc' }],
        select: {
          id: true,
          zoneId: true,
          isContracted: true,
          commissionRate: true,
        },
      });
      if (!fallbackBranch) {
        throw new BadRequestException(OrderErrors.NO_OPEN_BRANCH);
      }
      branch = {
        id: fallbackBranch.id,
        zoneId: fallbackBranch.zoneId,
        isContracted: fallbackBranch.isContracted,
        commissionRate: fallbackBranch.commissionRate,
        lng: 0,
        lat: 0,
      };
    }

    const distanceKm =
      hasDeliveryCoords && (branch.lng !== 0 || branch.lat !== 0)
        ? await this.ordersRepository.getDistanceKm(
            branch.lng,
            branch.lat,
            deliveryLng,
            deliveryLat,
          )
        : 0;

    const settings = await this.platformSettings.getSettings();

    const subtotal = dto.price * (dto.quantity ?? 1);
    const vendorCommission =
      branch.commissionRate != null
        ? Number(branch.commissionRate)
        : vendor.commissionRate != null
          ? Number(vendor.commissionRate)
          : Number(settings.defaultCommissionRate ?? 10);
    const commissionRate = vendorCommission / 100;
    const isContracted =
      branch.isContracted != null ? branch.isContracted : vendor.isContracted;
    const serviceFee = !isContracted
      ? Math.round(subtotal * commissionRate)
      : 0;
    const taxRate = Number(settings.defaultTaxRate) / 100;
    const tax = Math.round((subtotal + serviceFee) * taxRate);
    const grandTotal = subtotal + serviceFee + tax;

    const orderNumber = await this.ordersRepository.generateOrderNumber();
    const orderData: CreateOrderData = {
      orderNumber,
      clientOrderKey,
      customerId: customer.id,
      vendorId: dto.vendorId,
      vendorBranchId: branch.id,
      zoneId: zone?.id ?? branch.zoneId ?? null,
      paymentMethod: dto.paymentMethod ?? PaymentMethod.CASH_ON_DELIVERY,
      deliveryAddress: dto.deliveryAddress ?? 'Pending Customer Update',
      deliveryLng,
      deliveryLat,
      subtotal,
      deliveryFee: 0,
      driverBonusFee: 0,
      serviceFee,
      tax,
      discount: 0,
      coinsUsed: 0,
      coinsEarned: 0,
      grandTotal,
      upfrontAmount: 0,
      specialRequest: dto.specialRequest ?? null,
      type: 'STANDARD',
      distanceKm,
      pickupAddress: null,
      pickupLng: null,
      pickupLat: null,
      itemDetails: null,
      requestedVehicleType: null,
      isContracted,
      commissionRate: vendorCommission,
      activeOrderPolicy,
    };

    const itemsData: OrderItemData[] = [
      {
        productId: dto.productId ?? null,
        variantId: null,
        productName: dto.productName ?? 'Custom Item',
        variantName: null,
        unitPrice: dto.price,
        quantity: dto.quantity ?? 1,
        selectedUnit: null,
        baseUnitPrice: dto.price,
        totalPrice: subtotal,
        specialRequest: null,
        options: [],
      },
    ];

    const order = await this.ordersRepository.createOrder(
      orderData,
      itemsData,
      actor.sub,
    );

    // Direct orders placed by a vendor/admin skip the customer-approval step and
    // are treated as accepted immediately (createOrder sets PENDING by default).
    if (order.created) {
      await this.prisma.orderVendorFulfillment.updateMany({
        where: {
          orderId: order.id,
          status: OrderVendorFulfillmentStatus.PENDING,
        },
        data: {
          status: OrderVendorFulfillmentStatus.ACCEPTED,
          decidedByUserId: actor.sub,
          decidedAt: new Date(),
        },
      });
      await this.prisma.orderDeliveryGroup.updateMany({
        where: { orderId: order.id, status: DeliveryGroupStatus.PENDING },
        data: { status: DeliveryGroupStatus.ACCEPTED },
      });

      const accepted = await this.ordersRepository.updateStatus(
        order.id,
        OrderStatus.ACCEPTED,
        actor.sub,
        'Order created by Vendor/Admin directly from chat',
        undefined,
        OrderStatus.PENDING,
      );

      const vendorUserIds = orderData.vendorId
        ? await this.ordersRepository.getVendorUserIds(
            orderData.vendorId,
            orderData.vendorBranchId,
          )
        : [];

      this.eventEmitter.emit(
        EVENTS.ORDER_CREATED,
        new OrderCreatedEvent(
          order.id,
          orderData.orderNumber,
          orderData.customerId,
          customer.userId,
          orderData.vendorId,
          vendorUserIds,
          orderData.grandTotal,
          orderData.paymentMethod,
          orderData.type,
          0,
          orderData.vendorId ? [orderData.vendorId] : [],
        ),
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_STATUS_CHANGED,
        new OrderStatusChangedEvent(
          order.id,
          orderData.orderNumber,
          OrderStatus.PENDING,
          OrderStatus.ACCEPTED,
          orderData.customerId,
          customer.userId,
          orderData.vendorId,
          vendorUserIds,
          null,
          null,
          actor.sub,
          'Order created by Vendor/Admin directly from chat',
          accepted.revision,
        ),
      );
    }

    return this.ordersRepository.findById(order.id);
  }

  async validateActiveOrderLimit(customerId: string) {
    return this.activePolicy.validateActiveOrderLimit(customerId);
  }
}
