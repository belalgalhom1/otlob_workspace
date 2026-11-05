import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/data.dart';

class LegalDocumentsState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> termsDocuments;
  final List<Map<String, dynamic>> privacyDocuments;
  final Map<String, dynamic>? activeDocumentStats;

  const LegalDocumentsState({
    this.isLoading = false,
    this.error,
    this.termsDocuments = const [],
    this.privacyDocuments = const [],
    this.activeDocumentStats,
  });

  LegalDocumentsState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? termsDocuments,
    List<Map<String, dynamic>>? privacyDocuments,
    Map<String, dynamic>? activeDocumentStats,
    bool clearError = false,
  }) {
    return LegalDocumentsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      termsDocuments: termsDocuments ?? this.termsDocuments,
      privacyDocuments: privacyDocuments ?? this.privacyDocuments,
      activeDocumentStats: activeDocumentStats ?? this.activeDocumentStats,
    );
  }
}

class LegalDocumentsNotifier extends Notifier<LegalDocumentsState> {
  @override
  LegalDocumentsState build() => const LegalDocumentsState();

  AdminLegalDocumentsRepository get _repo =>
      ref.read(adminLegalDocumentsRepositoryProvider);

  Future<void> fetchAllDocuments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final terms = await _repo.getAllDocuments(type: 'TERMS_OF_USE');
      final privacy = await _repo.getAllDocuments(type: 'PRIVACY_POLICY');

      state = state.copyWith(
        isLoading: false,
        termsDocuments: terms,
        privacyDocuments: privacy,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createDocument({
    required String type,
    required String title,
    required String titleAr,
    required String content,
    required String contentAr,
    required String version,
  }) async {
    try {
      await _repo.createDocument(
        type: type,
        title: title,
        titleAr: titleAr,
        content: content,
        contentAr: contentAr,
        version: version,
      );
      await fetchAllDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateDocument(
    String id, {
    String? title,
    String? titleAr,
    String? content,
    String? contentAr,
    String? version,
  }) async {
    try {
      await _repo.updateDocument(
        id,
        title: title,
        titleAr: titleAr,
        content: content,
        contentAr: contentAr,
        version: version,
      );
      await fetchAllDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> publishDocument(String id) async {
    try {
      await _repo.publishDocument(id);
      await fetchAllDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await _repo.deleteDocument(id);
      await fetchAllDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchDocumentStats(String id) async {
    try {
      final stats = await _repo.getDocumentStats(id);
      state = state.copyWith(activeDocumentStats: stats);
      return stats;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final legalDocumentsProvider =
    NotifierProvider<LegalDocumentsNotifier, LegalDocumentsState>(
  LegalDocumentsNotifier.new,
);
