import type { JwtAccessPayload } from '../interfaces/jwt-payload.interface';

/**
 * Dependency-inversion boundary between DriversModule (assisted-delivery orchestration)
 * and OrdersModule (order cancellation & delivery-group recomputation).
 * DriversModule imports OrdersModule directly and injects this port instead of
 * depending on OrdersStateService with forwardRef().
 */
export const ORDER_ASSIST_CANCELLATION_PORT = Symbol(
  'ORDER_ASSIST_CANCELLATION_PORT',
);

export interface OrderAssistCancellationPort {
  cancelOrder(
    actor: JwtAccessPayload | null,
    orderId: string,
    reason: string,
  ): Promise<unknown>;

  recomputeGroupedOrderStatusAfterCancel(
    orderId: string,
    extraDriverIds?: Array<string | null | undefined>,
  ): Promise<void>;

  cancelDeliveryGroupAfterAssistFailure(
    orderId: string,
    deliveryGroupId: string,
    reason: string,
    extraDriverIds?: Array<string | null | undefined>,
  ): Promise<void>;
}
