import { Global, Module } from '@nestjs/common';
import { OrderEarningsCalculator } from './order-earnings.calculator';
import { OrderWorkflowDispatcher } from './order-workflow.dispatcher';
import { DriverWorkloadHelper } from './driver-workload.helper';

@Global()
@Module({
  providers: [
    OrderEarningsCalculator,
    OrderWorkflowDispatcher,
    DriverWorkloadHelper,
  ],
  exports: [
    OrderEarningsCalculator,
    OrderWorkflowDispatcher,
    DriverWorkloadHelper,
  ],
})
export class OrderSharedModule {}
