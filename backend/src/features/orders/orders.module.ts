import { Module, forwardRef } from '@nestjs/common';

import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrdersCheckoutService } from './orders-checkout.service';
import { OrdersStateService } from './orders-state.service';
import { OrdersPaymentService } from './orders-payment.service';
import { OrdersRepository } from './orders.repository';
import { OrderGroupingService } from './order-grouping.service';
import { OrderVendorDecisionService } from './order-vendor-decision.service';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';
import { OrdersDispatchWorkflowAdapter } from './orders-dispatch-workflow.adapter';
import { StockService } from './helpers/stock.service';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import { DeliveryGroupTransitionService } from './transitions/delivery-group-transition.service';
import { FulfillmentTransitionService } from './transitions/fulfillment-transition.service';
import { CartModule } from '../cart/cart.module';
import { DispatchModule } from '../dispatch/dispatch.module';
import { StatisticsModule } from '../statistics/statistics.module';
import { DriversModule } from '../drivers/drivers.module';
import { OrderSharedModule } from '../../common/orders/order-shared.module';
import { DISPATCH_ORDER_WORKFLOW_PORT } from '../../common/orders/order-dispatch.ports';

@Module({
  imports: [
    CartModule,
    DispatchModule,
    StatisticsModule,
    forwardRef(() => DriversModule),
    OrderSharedModule,
  ],
  controllers: [OrdersController],
  providers: [
    OrdersService,
    OrdersCheckoutService,
    OrdersStateService,
    OrdersPaymentService,
    OrdersRepository,
    OrderGroupingService,
    OrderVendorDecisionService,
    OrdersMultiVendorService,
    StockService,
    OrderAuthorizationHelper,
    OrderCancellationService,
    DeliveryGroupTransitionService,
    FulfillmentTransitionService,
    OrdersDispatchWorkflowAdapter,
    {
      provide: DISPATCH_ORDER_WORKFLOW_PORT,
      useExisting: OrdersDispatchWorkflowAdapter,
    },
  ],
  exports: [
    OrdersService,
    OrdersCheckoutService,
    OrdersStateService,
    OrdersPaymentService,
    OrdersRepository,
    OrderGroupingService,
    OrderVendorDecisionService,
    OrdersMultiVendorService,
    StockService,
    OrderAuthorizationHelper,
    OrderCancellationService,
    DeliveryGroupTransitionService,
    FulfillmentTransitionService,
    DISPATCH_ORDER_WORKFLOW_PORT,
  ],
})
export class OrdersModule {}
