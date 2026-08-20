import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:data/data.dart';

part 'ticket_provider.g.dart';

class TicketStateData {
  final List<dynamic> tickets;
  final int total;
  final int page;
  final Map<String, dynamic> counts;
  TicketStateData(
    this.tickets,
    this.total,
    this.page, {
    this.counts = const {},
  });
}

@Riverpod(keepAlive: true)
class TicketNotifier extends _$TicketNotifier {
  @override
  AsyncValue<TicketStateData> build() {
    return const AsyncValue.loading();
  }

  Future<void> fetchTickets({Map<String, dynamic> params = const {}}) async {
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }
    try {
      final repository = ref.read(sharedSupportTicketsRepositoryProvider);
      final result = await repository.getTickets(
        page: params['page'] ?? 1,
        limit: params['limit'] ?? 20,
        status: params['status'],
      );
      state = AsyncValue.data(
        TicketStateData(
          result['tickets'] as List<dynamic>,
          result['total'] as int,
          result['page'] as int? ?? 1,
          counts: result['counts'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (e, st) {
      if (isInitialLoad) {
        state = AsyncValue.error(e.toString(), st);
      }
    }
  }
}

