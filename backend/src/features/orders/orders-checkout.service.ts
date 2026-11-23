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
import { DeliveryFeeCalculator } from '../platform-settings/delivery-fee.calculator';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';
import { OrderActivePolicyHelper } from './helpers/order-active-policy.helper';
import {
  applyOrderCoinsAndUpfront,
  resolveActiveDriverBonusFee,
  resolveCustomerDeliveryBreakdown,
} from './helpers/order-pricing.helper';
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
  OrderType,
  OrderVendorFulfillmentStatus,
  PaymentMethod,
  Role,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  OrderErrors,
  CustomerErrors,
} from '../../common/constants/response.constants';
import { DispatchSearchTracker } from '../dispatch/dispatch-search-tracker.service';
import { DriverSearchPhase } from '../dispatch/dispatch-search.types';
import {
  buildVehicleAvailabilitySettings,
  isVehicleTypeActiveInSettings,
  isVehicleTypeAllowedForOrderType,
} from '../../common/orders/vehicle-eligibility.helper';

@Injectable()
export class OrdersCheckoutService {
  private readonly logger = new Logger(OrdersCheckoutService.name);
  private readonly feeCalculator = new DeliveryFeeCalculator();

  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly cartService: CartService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    @Optional() private readonly multiVendorService?: OrdersMultiVendorService,
    @Optional() private readonly activePolicyHelper?: OrderActivePolicyHelper,
    @Optional() private readonly searchTracker?: DispatchSearchTracker,
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
        this.logger.log(
          `Order checkout idempotent replay: ${existing.orderNumber ?? existing.id} by user ${actor.sub}`,
        );
        return existing;
      }
    }

    const { customerId, coinBalance, cart } =
      await this.cartService.validateForCheckout(actor.sub, dto.vendorId);

    const activeOrderPolicy = await this.validateActiveOrderLimit(customerId);

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
      throw new BadRequestException(
        OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
      );
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
        goldSurchargeAmount: money.goldSurchargeAmount,
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
      return this.multiVendorService.estimateSingleVendorMultiBranch(
        actor,
        dto,
      );
    }
    if (money.requiresMultiBranch) {
      throw new BadRequestException(
        OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
      );
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
      driverBonusPaidByCustomer: money.driverBonusPaidByCustomer,
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
      select: { coinBalance: true, canOrder: true },
    });
    if (!customer)
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
    if ((customer as { canOrder?: boolean }).canOrder === false) {
      throw new ForbiddenException(CustomerErrors.CANNOT_ORDER);
    }

    const money = await this.computeCustomOrderMoney(dto, customer.coinBalance);

    return {
      distanceKm: money.distanceKm,
      deliveryFee: money.deliveryFee,
      serviceFee: money.serviceFee,
      driverBonusFee: money.driverBonusFee,
      driverBonusPaidByCustomer: money.driverBonusPaidByCustomer,
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
      if (
        allowMultiBranchFallback &&
        productIds.length > 0 &&
        this.multiVendorService
      ) {
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

    const { deliveryFee, goldSurchargeAmount } =
      await resolveCustomerDeliveryBreakdown(this.platformSettings, {
        distanceKm,
        zoneBaseDeliveryFeeOverride: zone?.baseDeliveryFeeOverride ?? null,
        perKmOverride: null,
        isStandardOrder: true,
        settings,
      });

    const branchCommission =
      typeof branch !== 'undefined' && branch?.commissionRate != null
        ? Number(branch.commissionRate)
        : null;
    const vendorCommission =
      branchCommission != null
        ? branchCommission
        : vendor.commissionRate != null
          ? Number(vendor.commissionRate)
          : Number(settings.defaultCommissionRate ?? 10);
    const commissionRate = vendorCommission / 100;
    const isContracted =
      typeof branch !== 'undefined' && branch?.isContracted != null
        ? branch.isContracted
        : vendor.isContracted;

    const serviceFee = !isContracted
      ? Math.round(subtotal * commissionRate)
      : 0;

    const taxRate = Number(settings.defaultTaxRate) / 100;
    const tax = Math.round((subtotal + serviceFee) * taxRate);

    const driverBonusFee = resolveActiveDriverBonusFee(settings);

    let preDiscountTotal = subtotal + deliveryFee + serviceFee + tax;
    if (settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      preDiscountTotal += driverBonusFee;
    }

    const { coinsUsed, discount, grandTotal, coinsEarned, upfrontAmount } =
      applyOrderCoinsAndUpfront({
        preDiscountTotal,
        coinsToUse,
        coinBalance: Number(coinBalance ?? 0),
        paymentMethod,
        settings,
      });

    return {
      requiresMultiBranch: false as const,
      vendor,
      zone,
      branch,
      distanceKm,
      deliveryFee,
      goldSurchargeAmount,
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
    if (
      dto.type !== OrderType.RIDE &&
      dto.type !== OrderType.CUSTOM_DELIVERY
    ) {
      throw new BadRequestException(
        OrderErrors.VEHICLE_TYPE_NOT_ALLOWED_FOR_SERVICE,
      );
    }

    if (!isVehicleTypeAllowedForOrderType(dto.type, dto.vehicleType)) {
      throw new BadRequestException(
        OrderErrors.VEHICLE_TYPE_NOT_ALLOWED_FOR_SERVICE,
      );
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

    const vehicleSettings = buildVehicleAvailabilitySettings(settings);
    if (!isVehicleTypeActiveInSettings(dto.vehicleType, vehicleSettings)) {
      throw new BadRequestException(OrderErrors.VEHICLE_TYPE_DISABLED);
    }

    const perKm = this.feeCalculator.getVehiclePerKm(settings, dto.vehicleType);
    if (perKm == null) {
      throw new BadRequestException(
        OrderErrors.VEHICLE_TYPE_NOT_ALLOWED_FOR_SERVICE,
      );
    }

    const { deliveryFee, goldSurchargeAmount } =
      await resolveCustomerDeliveryBreakdown(this.platformSettings, {
        distanceKm,
        zoneBaseDeliveryFeeOverride: null,
        perKmOverride: perKm,
        isStandardOrder: false,
        settings,
        vehicleType: dto.vehicleType,
      });

    const serviceFee = Number(settings.customOrderPlatformFee) || 0;
    const taxRate = Number(settings.defaultTaxRate) / 100;
    const tax = Math.round(serviceFee * taxRate);

    const driverBonusFee = resolveActiveDriverBonusFee(settings);

    let preDiscountTotal = deliveryFee + serviceFee + tax;
    if (settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      preDiscountTotal += driverBonusFee;
    }

    const { coinsUsed, discount, grandTotal, coinsEarned, upfrontAmount } =
      applyOrderCoinsAndUpfront({
        preDiscountTotal,
        coinsToUse: dto.coinsToUse,
        coinBalance,
        paymentMethod: dto.paymentMethod,
        settings,
      });

    return {
      pickupLng,
      pickupLat,
      deliveryLng,
      deliveryLat,
      distanceKm,
      deliveryFee,
      goldSurchargeAmount,
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
        this.logger.log(
          `Order checkout idempotent replay: ${existing.orderNumber ?? existing.id} by user ${actor.sub}`,
        );
        return existing;
      }
    }

    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true, coinBalance: true, canOrder: true },
    });
    if (!customer)
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
    if ((customer as { canOrder?: boolean }).canOrder === false) {
      throw new ForbiddenException(CustomerErrors.CANNOT_ORDER);
    }
    const customerId = customer.id;

    const activeOrderPolicy = await this.validateActiveOrderLimit(customerId);

    const money = await this.computeCustomOrderMoney(dto, customer.coinBalance);
    const {
      pickupLng,
      pickupLat,
      deliveryLng,
      deliveryLat,
      distanceKm,
      deliveryFee,
      goldSurchargeAmount,
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
    // Custom Delivery & Ride orders have no vendor to accept them: create them
    // atomically in LOOKING_FOR_DRIVER (order + delivery group + outbox v0) so
    // a single ORDER_CREATED event triggers dispatch with zero crash window.
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
        goldSurchargeAmount,
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
        initialStatus: OrderStatus.LOOKING_FOR_DRIVER,
        activeOrderPolicy,
      },
      [], // No items
      actor.sub,
    );

    if (created.created) {
      await this.searchTracker?.publishPhase({
        orderId: created.id,
        orderNumber: created.orderNumber,
        orderType: dto.type,
        orderStatus: OrderStatus.LOOKING_FOR_DRIVER,
        revision: 0,
        customerUserId: actor.sub,
        phase: DriverSearchPhase.QUEUED,
        attempt: 1,
        contactedCount: 0,
        waveExpiresAt: null,
        resetHistory: true,
      });

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
          0, // revision of the created row (v0); matches outbox row in createOrder
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

    const activeOrderPolicy = await this.validateActiveOrderLimit(customer.id);

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: dto.vendorId },
    });
    if (!vendor) throw new NotFoundException(OrderErrors.NOT_AUTHORIZED_VENDOR);

    const hasDeliveryCoords =
      Array.isArray(dto.deliveryLocation) &&
      dto.deliveryLocation.length === 2 &&
      Number.isFinite(Number(dto.deliveryLocation[0])) &&
      Number.isFinite(Number(dto.deliveryLocation[1]));
    const deliveryLng = hasDeliveryCoords
      ? Number(dto.deliveryLocation![0])
      : 0;
    const deliveryLat = hasDeliveryCoords
      ? Number(dto.deliveryLocation![1])
      : 0;

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
      customerUserId: customer.userId,
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

      this.logger.log(
        `Direct order placed: ${orderData.orderNumber} by user ${actor.sub} for customer ${customer.id}`,
      );
    }

    return this.ordersRepository.findById(order.id);
  }

  async validateActiveOrderLimit(customerId: string) {
    return this.activePolicy.validateActiveOrderLimit(customerId);
  }
}
