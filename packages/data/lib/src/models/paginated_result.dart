class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  int get totalItems => total;
  int get pageSize => limit;

  PaginatedResult({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory PaginatedResult.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PaginatedResult<T>(
      items: (json['items'] as List?)?.map((e) => fromJsonT(e)).toList() ?? [],
      total: json['totalItems'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }

  factory PaginatedResult.empty() => PaginatedResult(items: [], total: 0);
}
