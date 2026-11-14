/**
 * Dependency-inversion boundaries between OrdersModule and DispatchModule.
 * Both modules depend only on these tokens and contracts instead of importing
 * each other's concrete classes with forwardRef().
 */

export const DISPATCH_PORT = Symbol('DISPATCH_PORT');

export interface DispatchPort {
  verifyPendingDispatch(
    dispatchId: string,
    driverId: string,
  ): Promise<string | null>;
  handleAcceptance(dispatchId: string, driverId: string): Promise<boolean>;
  getPendingForDriver(driverUserId: string): Promise<any[]>;
}

export const DISPATCH_ORDER_WORKFLOW_PORT = Symbol(
  'DISPATCH_ORDER_WORKFLOW_PORT',
);

export interface DispatchOrderWorkflowPort {
  /**
   * Move a legacy single-vendor order from ACCEPTED to LOOKING_FOR_DRIVER and
   * emit ORDER_STATUS_CHANGED when automated dispatch begins.
   */
  transitionAcceptedOrderToSearching(orderId: string): Promise<void>;
}
