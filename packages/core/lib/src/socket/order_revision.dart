/// Client-side mirror of the backend's monotonic `Order.revision` counter.
///
/// The backend bumps `Order.revision` in the same transaction as every status
/// write and stamps the resulting value on every realtime `order.status` /
/// `order.new` payload. Socket.IO does not guarantee per-client ordering, and
/// the background/resume/FCM paths can replay an older transition after a newer
/// one, so a naive client can walk an order's status backwards.
///
/// This tracker remembers the highest revision seen per order and lets callers
/// drop anything older. Equal revisions are accepted on purpose: one backend
/// revision can legitimately produce several events (per-stop pickup,
/// per-delivery completion) that all carry the same revision.
class OrderRevisionTracker {
  final Map<String, int> _latest = <String, int>{};

  /// Highest revision seen for [orderId], or null when nothing was seen yet.
  int? latest(String orderId) => _latest[orderId];

  /// Whether an event carrying [revision] is still fresh enough to apply.
  ///
  /// * `null` (payloads from before the revision rollout, FCM data messages)
  ///   is always accepted, because there is nothing to order it by.
  /// * a revision lower than the highest seen is stale: the UI already moved
  ///   past it, so applying it would roll the status back.
  bool accept(String orderId, int? revision) {
    if (revision == null) return true;
    final seen = _latest[orderId];
    if (seen != null && revision < seen) return false;
    if (seen == null || revision > seen) {
      _latest[orderId] = revision;
    }
    return true;
  }

  /// Records a revision read from an authoritative source (REST list/detail)
  /// without filtering it. This keeps the tracker above any socket event that
  /// was already in flight while the snapshot was fetched.
  void observe(String orderId, int? revision) {
    if (revision == null) return;
    final seen = _latest[orderId];
    if (seen == null || revision > seen) {
      _latest[orderId] = revision;
    }
  }

  /// Convenience for seeding from a raw order map (`id` + `revision`).
  void observeOrder(Object? order) {
    if (order is! Map) return;
    final id = order['id']?.toString();
    if (id == null || id.isEmpty) return;
    observe(id, orderRevisionOf(order));
  }

  void forget(String orderId) => _latest.remove(orderId);

  void clear() => _latest.clear();
}

/// Reads the `revision` field from a raw order / socket / push payload.
///
/// JSON numbers can arrive as `int` or `double`, and a couple of transports
/// stringify them, so handle all three shapes.
int? orderRevisionOf(Object? payload) {
  if (payload is! Map) return null;
  final raw = payload['revision'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}
