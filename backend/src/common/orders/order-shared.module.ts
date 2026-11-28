import { Global, Module } from '@nestjs/common';
import { OrderEarningsCalculator } from './order-earnings.calculator';
import { OrderWorkflowDispatcher } from './order-workflow.dispatcher';
import { DriverWorkloadHelper } from './driver-workload.helper';
import { StaleOrderAlertService } from './stale-order-alert.service';

@Global()
@Module({
  providers: [
    OrderEarningsCalculator,
    OrderWorkflowDispatcher,
    DriverWorkloadHelper,
    StaleOrderAlertService,
  ],
  exports: [
    OrderEarningsCalculator,
    OrderWorkflowDispatcher,
    DriverWorkloadHelper,
    StaleOrderAlertService,
  ],
})
export class OrderSharedModule {}
