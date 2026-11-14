import { Global, Module } from '@nestjs/common';
import { OrderEarningsCalculator } from './order-earnings.calculator';
import { OrderWorkflowDispatcher } from './order-workflow.dispatcher';

@Global()
@Module({
  providers: [OrderEarningsCalculator, OrderWorkflowDispatcher],
  exports: [OrderEarningsCalculator, OrderWorkflowDispatcher],
})
export class OrderSharedModule {}
