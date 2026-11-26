/**
 * Helpers for timestamp-based user-wide token revocation (`revoked:user:<userId>`).
 *
 * Storing the revocation epoch timestamp in milliseconds instead of a flat `'1'`
 * guarantees that:
 * - Access tokens issued BEFORE or AT the revocation remain rejected for their
 *   full lifespan (`tokenIssuedAtMs <= revokedAtMs`).
 * - Access tokens minted AFTER the revocation (for example, when the user
 *   immediately logs back in after a password reset, admin update, logout-all,
 *   or unverified OAuth account takeover cleanup) are accepted immediately.
 * - Legacy `'1'` values already present in Redis continue rejecting old tokens
 *   until they expire or are migrated by a newly created session.
 */

const MIN_EPOCH_MS_MARKER = 1_000_000_000_000;

export function createUserRevocationMarker(nowMs: number = Date.now()): string {
  return String(nowMs);
}

export function isUserTokenRevoked(
  revokedMarker: string | null | undefined,
  payload: { iatMs?: number; iat?: number },
): boolean {
  if (!revokedMarker) return false;

  const revokedAtMs = Number(revokedMarker);
  // Treat legacy `'1'` or any non-timestamp marker as revoking all tokens.
  if (!Number.isFinite(revokedAtMs) || revokedAtMs < MIN_EPOCH_MS_MARKER) {
    return true;
  }

  const tokenIssuedAtMs =
    typeof payload.iatMs === 'number' && Number.isFinite(payload.iatMs)
      ? payload.iatMs
      : typeof payload.iat === 'number' && Number.isFinite(payload.iat)
        ? payload.iat * 1000
        : 0;

  return tokenIssuedAtMs <= revokedAtMs;
}

export function computeFreshTokenIssuedAtMs(
  revokedMarker: string | null | undefined,
  nowMs: number = Date.now(),
): { iatMs: number; migratedMarker?: string } {
  if (!revokedMarker) {
    return { iatMs: nowMs };
  }

  const revokedAtMs = Number(revokedMarker);
  if (!Number.isFinite(revokedAtMs) || revokedAtMs < MIN_EPOCH_MS_MARKER) {
    // Migrate legacy `'1'` marker to `nowMs - 1` so all previously issued
    // tokens remain rejected while this newly created session (`nowMs`) works.
    return {
      iatMs: nowMs,
      migratedMarker: String(nowMs - 1),
    };
  }

  return {
    iatMs: nowMs <= revokedAtMs ? revokedAtMs + 1 : nowMs,
  };
}
