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
import { CartModule } from '../cart/cart.module';
import { DispatchModule } from '../dispatch/dispatch.module';
import { StatisticsModule } from '../statistics/statistics.module';
import { DriversModule } from '../drivers/drivers.module';

@Module({
  imports: [CartModule, forwardRef(() => DispatchModule), StatisticsModule, forwardRef(() => DriversModule)],
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
  ],
})
export class OrdersModule {}
