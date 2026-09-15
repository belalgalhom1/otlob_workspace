import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  Logger,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { OrdersRepository, CreateOrderData, OrderItemData } from './orders.repository';
import { OrdersStateService } from './orders-state.service';
import { CartService } from '../cart/cart.service';
import { DispatchService } from '../dispatch/dispatch.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  PlaceOrderDto,
  UpdateOrderStatusDto,
  QueryOrdersDto,
  RespondToDispatchDto,
  AdminAssignDriverDto,
  PlaceCustomOrderDto,
  EditOrderItemsDto,
  PlaceDirectOrderDto,
} from './dto/order.dto';
import {
  OrderCreatedEvent,
  OrderStatusChangedEvent,
  OrderCancelledEvent,
  OrderDispatchRespondedEvent,
  OrderPaymentStatusChangedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  Prisma,
  OrderStatus,
  Role,
  PaymentMethod,
  DispatchStatus,
  Permission,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  CartErrors,
  ProductErrors,
  OrderErrors,
  CustomerErrors,
  DriverErrors,
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
    @Inject(forwardRef(() => OrdersStateService))
    private readonly stateService: OrdersStateService,
  ) {}

async placeOrder(actor: JwtAccessPayload, dto: PlaceOrderDto) {
    const { customerId, coinBalance, cart } =
      await this.cartService.validateForCheckout(actor.sub, dto.vendorId);

    await this.validateActiveOrderLimit(customerId);

    const money = await this.computeStandardOrderMoney(
      dto.vendorId,
      cart.subtotal,
      dto.deliveryLocation,
      dto.paymentMethod,
      dto.coinsToUse,
      coinBalance,
    );

    const items: OrderItemData[] = cart.items.map((item: any) => ({
      productId: item.productId,
      variantId: item.variantId ?? null,
      productName: item.product.name ?? 'Unknown Product',
      variantName: item.variant?.name ?? null,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      totalPrice: item.totalPrice,
      specialRequest: item.specialRequest ?? null,
      options: item.options.map((opt) => ({
        optionId: opt.id,
        optionName: opt.name,
        priceAdded: Number(opt.priceAdded),
      })),
    }));

    const orderNumber = await this.ordersRepository.generateOrderNumber();
    const created = await this.ordersRepository.createOrder(
      {
        orderNumber,
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
        pickupAddress: null,
        pickupLng: money.branch?.lng ?? null,
        pickupLat: money.branch?.lat ?? null,
        itemDetails: null,
        requestedVehicleType: null,
      },
      items,
      actor.sub,
    );

    // The cart listener will catch ORDER_CREATED and clear the cart automatically.

    const vendorUserIds = await this.ordersRepository.getVendorUserIds(
      dto.vendorId,
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
      ),
    );

    this.logger.log(
      `Order placed: ${created.orderNumber} by user ${actor.sub}`,
    );
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

  private async computeStandardOrderMoney(
    vendorId: string,
    subtotal: number,
    deliveryLocation: [number, number],
    paymentMethod: PaymentMethod,
    coinsToUse: number | undefined,
    coinBalance: number | null,
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
    const minOrder = Number(settings.minOrderAmount);
    if (minOrder > 0 && subtotal < minOrder) {
      throw new BadRequestException(OrderErrors.MIN_ORDER_AMOUNT_NOT_MET);
    }

    const [lng, lat] = deliveryLocation;
    const zone = await this.ordersRepository.getZoneAtLocation(lng, lat);
    if (!zone) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    const branch = await this.ordersRepository.getNearestOpenBranchLocation(
      vendorId,
      lng,
      lat,
    );
    const distanceKm = branch
      ? await this.ordersRepository.getDistanceKm(
          branch.lng,
          branch.lat,
          lng,
          lat,
        )
      : (Number(settings.fallbackOrderDistanceKm) ?? 3);

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

    const vendorCommission = vendor.commissionRate != null
      ? Number(vendor.commissionRate)
      : Number(settings.defaultCommissionRate ?? 10);
    const commissionRate = vendorCommission / 100;

    const serviceFee = !vendor.isContracted
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
    const coinsEarned = amountSpentPerCoin > 0 ? Math.floor(
      grandTotal / amountSpentPerCoin,
    ) : 0;

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
    const coinsEarned = amountSpentPerCoin > 0 ? Math.floor(
      grandTotal / amountSpentPerCoin,
    ) : 0;

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
    };
  }

async placeCustomOrder(actor: JwtAccessPayload, dto: PlaceCustomOrderDto) {
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true, coinBalance: true },
    });
    if (!customer)
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
    const customerId = customer.id;

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
      },
      [], // No items
      actor.sub,
    );

    // Custom Orders have no vendor to accept them:
    // If no upfront payment is required, dispatch immediately;
    // if upfront payment is required, order stays in PENDING_PAYMENT until customer pays.
    if (upfrontAmount === 0) {
      await this.ordersRepository.updateStatus(
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
        ),
      );
    }

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
      ),
    );

    this.logger.log(
      `${dto.type} order placed: ${created.orderNumber} by user ${actor.sub}`,
    );
    return this.ordersRepository.findById(created.id);
  }

async editOrderItems(
    actor: JwtAccessPayload,
    orderId: string,
    dto: EditOrderItemsDto,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { vendor: true, items: { include: { selectedOptions: true } } },
    });
    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);

    if (actor.role === 'VENDOR_MEMBER') {
      const member = await this.prisma.vendorMember.findFirst({
        where: { userId: actor.sub, vendorId: order.vendorId ?? '' },
      });
      if (!member) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
      }
    } else if (actor.role === 'ADMIN') {
      const canManage = await this.canManageOrders(actor.sub, actor.role);
      if (!canManage)
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    }

    if (
      order.status !== OrderStatus.PENDING &&
      order.status !== OrderStatus.ACCEPTED
    ) {
      throw new BadRequestException(OrderErrors.CANNOT_EDIT_ITEMS);
    }

    let newSubtotal = 0;
    const newItems: any[] = [];

    const productIds = dto.items.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      include: {
        variants: {
          include: {
            optionGroups: { include: { options: true } },
          },
        },
        optionGroups: { include: { options: true } },
      },
    });
    const productMap = new Map(products.map((p) => [p.id, p]));

    for (const itemDto of dto.items) {
      const product = productMap.get(itemDto.productId);
      if (!product) throw new BadRequestException(ProductErrors.NOT_FOUND);

      let basePrice = Number(product.basePrice ?? 0);
      let variantName: string | null = null;

      if (itemDto.variantId) {
        const variant = product.variants.find(
          (v) => v.id === itemDto.variantId,
        );
        if (!variant)
          throw new BadRequestException(ProductErrors.VARIANT_NOT_FOUND);
        basePrice = Number(variant.basePrice);
        variantName = variant.name;
      }

      const oldItem = order.items.find(
        (i) => i.productId === itemDto.productId && i.variantId === (itemDto.variantId ?? null)
      );

      if (oldItem) {
        const oldOptionsTotal = oldItem.selectedOptions.reduce(
          (sum, opt) => sum + Number(opt.priceAdded),
          0,
        );
        basePrice = oldItem.unitPrice - oldOptionsTotal;
      }

      let optionsTotal = 0;
      const selectedOptions: any[] = [];
      if (itemDto.optionIds?.length) {
        let allOptions = product.optionGroups.flatMap((g) => g.options);
        if (itemDto.variantId) {
          const variant = product.variants.find(
            (v) => v.id === itemDto.variantId,
          );
          if (variant && variant.optionGroups) {
            allOptions = allOptions.concat(
              variant.optionGroups.flatMap((g) => g.options),
            );
          }
        }
        for (const optId of itemDto.optionIds) {
          const opt = allOptions.find((o) => o.id === optId);
          if (!opt)
            throw new BadRequestException(ProductErrors.OPTION_NOT_FOUND);
          optionsTotal += Number(opt.priceAdded);
          selectedOptions.push({
            optionId: opt.id,
            optionName: opt.name,
            priceAdded: Number(opt.priceAdded),
          });
        }
      }

      const unitPrice = basePrice + optionsTotal;
      const totalPrice = unitPrice * itemDto.quantity;
      newSubtotal += totalPrice;

      newItems.push({
        productId: product.id,
        variantId: itemDto.variantId ?? null,
        productName: product.name ?? 'Unknown Product',
        variantName,
        unitPrice,
        quantity: itemDto.quantity,
        totalPrice,
        specialRequest: itemDto.specialRequest ?? null,
        selectedOptions,
      });
    }

    const settings = await this.platformSettings.getSettings();
    const vendorCommission = order.vendor?.commissionRate != null
      ? Number(order.vendor.commissionRate)
      : Number(settings.defaultCommissionRate ?? 10);
    const serviceFee =
      order.vendor && !order.vendor.isContracted
        ? Math.round(newSubtotal * (vendorCommission / 100))
        : 0;
    const taxRate = Number(settings.defaultTaxRate) / 100;
    const tax = Math.round((newSubtotal + serviceFee) * taxRate);
    const discount = Number(order.discount ?? 0);
    const driverBonus = (settings.driverBonusPaidByCustomer && Number(order.driverBonusFee ?? 0) > 0)
      ? Number(order.driverBonusFee)
      : 0;
    const grandTotal = Math.max(
      0,
      newSubtotal + Number(order.deliveryFee) + serviceFee + tax + driverBonus - discount,
    );
    const amountSpentPerCoin = Number(settings.amountSpentPerCoin) || 0;
    const coinsEarned = amountSpentPerCoin > 0 ? Math.floor(grandTotal / amountSpentPerCoin) : 0;

    await this.prisma.$transaction(async (tx) => {
      // delete old
      await tx.orderItem.deleteMany({ where: { orderId: order.id } });

      // insert new
      const orderItemsData: Prisma.OrderItemCreateManyInput[] = [];
      const orderItemOptionsData: Prisma.OrderItemOptionCreateManyInput[] = [];

      for (const item of newItems) {
        const orderItemId = randomUUID();
        orderItemsData.push({
          id: orderItemId,
          orderId: order.id,
          productId: item.productId,
          variantId: item.variantId,
          productName: item.productName,
          variantName: item.variantName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          totalPrice: item.totalPrice,
          specialRequest: item.specialRequest,
        });

        if (item.selectedOptions.length > 0) {
          for (const o of item.selectedOptions) {
            orderItemOptionsData.push({
              orderItemId: orderItemId,
              optionId: o.optionId,
              optionName: o.optionName,
              priceAdded: o.priceAdded,
            });
          }
        }
      }

      if (orderItemsData.length > 0) {
        await tx.orderItem.createMany({ data: orderItemsData });
      }
      if (orderItemOptionsData.length > 0) {
        await tx.orderItemOption.createMany({ data: orderItemOptionsData });
      }

      await tx.order.update({
        where: { id: order.id },
        data: {
          subtotal: newSubtotal,
          serviceFee,
          tax,
          grandTotal,
          coinsEarned,
          status: OrderStatus.CHANGES_REQUESTED,
        },
      });

      await tx.orderStatusEvent.create({
        data: {
          orderId: order.id,
          status: OrderStatus.CHANGES_REQUESTED,
          note: 'Vendor modified order items',
          createdBy: actor.sub,
        },
      });
    });

    const customer = await this.prisma.customer.findUnique({
      where: { id: order.customerId },
      select: { userId: true },
    });
    const vendorUserIds = await this.ordersRepository.getVendorUserIds(
      order.vendorId,
    );

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        order.orderNumber,
        order.status as OrderStatus,
        OrderStatus.CHANGES_REQUESTED,
        order.customerId,
        customer?.userId ?? '',
        order.vendorId,
        vendorUserIds,
        order.driverId,
        null,
        actor.sub,
        'Vendor modified order items',
      ),
    );

    return { message: 'Order items updated and awaiting customer approval' };
  }

async adminPlaceDirectOrder(
    actor: JwtAccessPayload,
    dto: PlaceDirectOrderDto,
  ) {
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
    if (!customer) throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);

    await this.validateActiveOrderLimit(customer.id);

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: dto.vendorId },
    });
    if (!vendor) throw new NotFoundException(OrderErrors.NOT_AUTHORIZED_VENDOR);

    const settings = await this.platformSettings.getSettings();

    const subtotal = dto.price * (dto.quantity ?? 1);
    const vendorCommission = vendor.commissionRate != null
      ? Number(vendor.commissionRate)
      : Number(settings.defaultCommissionRate ?? 10);
    const commissionRate = vendorCommission / 100;
    const serviceFee = !vendor.isContracted
      ? Math.round(subtotal * commissionRate)
      : 0;
    const taxRate = Number(settings.defaultTaxRate) / 100;
    const tax = Math.round((subtotal + serviceFee) * taxRate);
    const grandTotal = subtotal + serviceFee + tax;

    const orderId = randomUUID();

    const orderNumber = await this.ordersRepository.generateOrderNumber();
    const orderData: CreateOrderData = {
      orderNumber,
      customerId: customer.id,
      vendorId: dto.vendorId,
      vendorBranchId: null,
      zoneId: null,
      paymentMethod: dto.paymentMethod ?? PaymentMethod.CASH_ON_DELIVERY,
      deliveryAddress: dto.deliveryAddress ?? 'Pending Customer Update',
      deliveryLng: dto.deliveryLocation?.[0] ?? 0,
      deliveryLat: dto.deliveryLocation?.[1] ?? 0,
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
      distanceKm: 0,
      pickupAddress: null,
      pickupLng: null,
      pickupLat: null,
      itemDetails: null,
      requestedVehicleType: null,
    };

    const itemsData: OrderItemData[] = [
      {
        productId: dto.productId ?? null,
        variantId: null,
        productName: dto.productName ?? 'Custom Item',
        variantName: null,
        unitPrice: dto.price,
        quantity: dto.quantity ?? 1,
        totalPrice: subtotal,
        specialRequest: null,
        options: [],
      },
    ];

    const order = await this.ordersRepository.createOrder(orderData, itemsData, actor.sub);

    // Update the created order's status to CHANGES_REQUESTED (createOrder sets to PENDING/PENDING_PAYMENT by default)
    await this.prisma.order.update({
      where: { id: order.id },
      data: { status: OrderStatus.CHANGES_REQUESTED }
    });

    // Also update the status event to CHANGES_REQUESTED instead of whatever createOrder created
    await this.prisma.orderStatusEvent.updateMany({
      where: { orderId: order.id },
      data: { status: OrderStatus.CHANGES_REQUESTED, note: 'Order created by Vendor/Admin directly from chat' }
    });

    const vendorUserIds = orderData.vendorId ? await this.ordersRepository.getVendorUserIds(orderData.vendorId) : [];

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        orderData.orderNumber,
        OrderStatus.PENDING,
        OrderStatus.CHANGES_REQUESTED,
        orderData.customerId,
        customer.userId,
        orderData.vendorId,
        vendorUserIds,
        null,
        null,
        actor.sub,
        'Order created by Vendor/Admin directly from chat',
      ),
    );

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
        orderData.type
      ),
    );

    return order;
  }

async acceptOrderChanges(actor: JwtAccessPayload, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { driver: true, customer: true },
    });
    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);
    if (order.customer.userId !== actor.sub)
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    if (order.status !== OrderStatus.CHANGES_REQUESTED)
      throw new BadRequestException(OrderErrors.NO_PENDING_CHANGES);

    const hasDriver = !!order.driverId;
    let nextStatus: OrderStatus = OrderStatus.ACCEPTED;
    if (hasDriver) {
      nextStatus =
        order.paymentMethod === 'MOBILE_WALLET'
          ? OrderStatus.PENDING_PAYMENT
          : OrderStatus.DRIVER_ASSIGNED;
    }

    const updated = await this.ordersRepository.updateStatus(
      orderId,
      nextStatus,
      actor.sub,
      'Customer approved order changes',
      {},
      OrderStatus.CHANGES_REQUESTED,
    );

    const vendorUserIds = await this.ordersRepository.getVendorUserIds(
      order.vendorId,
    );
    const driverUserId = order.driver?.userId ?? null;

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        order.orderNumber,
        OrderStatus.CHANGES_REQUESTED,
        nextStatus,
        order.customerId,
        actor.sub,
        order.vendorId,
        vendorUserIds,
        order.driverId,
        driverUserId,
        actor.sub,
        'Customer approved order changes',
      ),
    );
    return { message: 'Order changes accepted' };
  }

  async rejectOrderChanges(actor: JwtAccessPayload, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { driver: true, customer: true },
    });
    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);
    if (order.customer.userId !== actor.sub)
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    if (order.status !== OrderStatus.CHANGES_REQUESTED)
      throw new BadRequestException(OrderErrors.NO_PENDING_CHANGES);

    await this.stateService.cancelOrder(
      actor,
      orderId,
      'Customer rejected order changes',
    );

    return { message: 'Order changes rejected and order cancelled' };
  }

private async validateActiveOrderLimit(customerId: string) {
    const settings = await this.platformSettings.getSettings();

    // 1. Get the current active order count
    const activeCount = await this.prisma.order.count({
      where: {
        customerId,
        status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
      },
    });

    // Fast path: if 0 active orders, they are always allowed to place a new one
    if (activeCount === 0) return;

    if (activeCount >= settings.maxActiveOrdersPerCustomer) {
      throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
    }

    if (settings.requirePriorDeliveryForMultipleOrders) {
      const hasCompletedOrder = await this.prisma.order.findFirst({
        where: {
          customerId,
          status: OrderStatus.DELIVERED,
        },
        select: { id: true },
      });

      if (!hasCompletedOrder) {
        throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
      }
    }
  }

private async canManageOrders(userId: string, role: Role): Promise<boolean> {
    if (role === Role.SUPER_ADMIN) return true;
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { permissions: true },
    });
    return !!user?.permissions.includes(Permission.MANAGE_ORDERS);
  }

}
