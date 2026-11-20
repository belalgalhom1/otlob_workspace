export const DRIVER_WALLET_TX_SELECT = {
  id: true,
  driverId: true,
  orderId: true,
  deliveryGroupId: true,
  driverShiftId: true,
  type: true,
  amount: true,
  balanceAfter: true,
  description: true,
  note: true,
  isManualAdjustment: true,
  referenceId: true,
  createdAt: true,
} as const;

const GENERIC_DEFAULT_DESCRIPTIONS = new Set([
  '',
  'manual admin transaction',
  'manual admin adjustment',
  'manual driver manager transaction',
]);

export function resolveDriverFacingAdjustmentNote(tx: {
  note?: string | null;
  description?: string | null;
  isManualAdjustment?: boolean | null;
  idempotencyKey?: string | null;
  type?: string | null;
}): string | null {
  const explicit = tx.note?.trim();
  if (explicit) return explicit;

  const isManual =
    Boolean(tx.isManualAdjustment) ||
    Boolean(tx.idempotencyKey?.startsWith('admin:driver:'));
  if (!isManual) return null;

  const desc = tx.description?.trim();
  if (!desc) return null;
  if (GENERIC_DEFAULT_DESCRIPTIONS.has(desc.toLowerCase())) {
    return null;
  }
  return desc;
}

export function isManualAdjustmentTransaction(tx: {
  isManualAdjustment?: boolean | null;
  note?: string | null;
  idempotencyKey?: string | null;
  type?: string | null;
  orderId?: string | null;
  referenceId?: string | null;
  description?: string | null;
}): boolean {
  if (tx.isManualAdjustment) return true;
  if (tx.idempotencyKey?.startsWith('admin:driver:')) return true;
  if (tx.note?.trim()) return true;
  if (
    tx.type === 'ADJUSTMENT' &&
    !tx.orderId &&
    !(tx.description ?? '').toLowerCase().includes('top-up')
  ) {
    return true;
  }
  return false;
}

export interface DriverWalletTxInput {
  note?: string | null;
  description?: string | null;
  isManualAdjustment?: boolean | null;
  idempotencyKey?: string | null;
  type?: string | null;
  orderId?: string | null;
  referenceId?: string | null;
}

export function sanitizeDriverWalletTransactionForDriver<
  T extends DriverWalletTxInput,
>(
  tx: T,
): Omit<T, 'idempotencyKey'> & {
  note: string | null;
  isManualAdjustment: boolean;
} {
  const { idempotencyKey, ...rest } = tx;
  const isManual = isManualAdjustmentTransaction({ ...tx, idempotencyKey });
  const note = resolveDriverFacingAdjustmentNote({
    ...tx,
    idempotencyKey,
    isManualAdjustment: isManual,
  });

  // Never leak raw admin fallback markers as user-facing adjustment notes,
  // and omit internal idempotencyKey from driver responses.
  return {
    ...rest,
    note,
    isManualAdjustment: isManual,
  };
}
