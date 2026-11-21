import { Module } from '@nestjs/common';

import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrdersCheckoutService } from './orders-checkout.service';
import { OrdersStateService } from './orders-state.service';
import { OrdersPaymentService } from './orders-payment.service';
import { OrdersRepository } from './orders.repository';
import { OrderSearchService } from './order-search.service';
import { OrderRouteService } from './order-route.service';
import { OrderQueriesRepository } from './repositories/order-queries.repository';
import { OrderGeoRepository } from './repositories/order-geo.repository';
import { OrderRoleProjector } from './projections/order-role.projector';
import { OrderGroupingService } from './order-grouping.service';
import { OrderVendorDecisionService } from './order-vendor-decision.service';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';
import { OrdersDispatchWorkflowAdapter } from './orders-dispatch-workflow.adapter';
import { OrderSettlementService } from './order-settlement.service';
import { StockService } from './helpers/stock.service';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import { OrderRejectionRecomputor } from './helpers/order-rejection-recomputor';
import { OrderActivePolicyHelper } from './helpers/order-active-policy.helper';
import { BranchAllocatorHelper } from './helpers/branch-allocator.helper';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import { DeliveryGroupTransitionService } from './transitions/delivery-group-transition.service';
import { FulfillmentTransitionService } from './transitions/fulfillment-transition.service';
import { CartModule } from '../cart/cart.module';
import { DispatchModule } from '../dispatch/dispatch.module';
import { OrderSharedModule } from '../../common/orders/order-shared.module';
import { DISPATCH_ORDER_WORKFLOW_PORT } from '../../common/orders/order-dispatch.ports';
import { ORDER_ASSIST_CANCELLATION_PORT } from '../../common/orders/order-assist.ports';

@Module({
  imports: [CartModule, DispatchModule, OrderSharedModule],
  controllers: [OrdersController],
  providers: [
    OrdersService,
    OrdersCheckoutService,
    OrdersStateService,
    OrdersPaymentService,
    OrdersRepository,
    OrderSearchService,
    OrderRouteService,
    OrderQueriesRepository,
    OrderGeoRepository,
    OrderRoleProjector,
    OrderGroupingService,
    OrderVendorDecisionService,
    OrdersMultiVendorService,
    StockService,
    OrderAuthorizationHelper,
    OrderRejectionRecomputor,
    OrderActivePolicyHelper,
    BranchAllocatorHelper,
    OrderCancellationService,
    DeliveryGroupTransitionService,
    FulfillmentTransitionService,
    OrderSettlementService,
    OrdersDispatchWorkflowAdapter,
    {
      provide: DISPATCH_ORDER_WORKFLOW_PORT,
      useExisting: OrdersDispatchWorkflowAdapter,
    },
    {
      provide: ORDER_ASSIST_CANCELLATION_PORT,
      useExisting: OrdersStateService,
    },
  ],
  exports: [
    OrdersService,
    OrdersCheckoutService,
    OrdersStateService,
    OrdersPaymentService,
    OrdersRepository,
    OrderSearchService,
    OrderRouteService,
    OrderQueriesRepository,
    OrderGeoRepository,
    OrderRoleProjector,
    OrderGroupingService,
    OrderVendorDecisionService,
    OrdersMultiVendorService,
    StockService,
    OrderAuthorizationHelper,
    OrderRejectionRecomputor,
    OrderActivePolicyHelper,
    BranchAllocatorHelper,
    OrderCancellationService,
    DeliveryGroupTransitionService,
    FulfillmentTransitionService,
    OrderSettlementService,
    DISPATCH_ORDER_WORKFLOW_PORT,
    ORDER_ASSIST_CANCELLATION_PORT,
  ],
})
export class OrdersModule {}
