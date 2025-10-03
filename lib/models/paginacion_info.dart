class PaginacionInfo {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginacionInfo({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginacionInfo.fromJson(Map<String, dynamic> json) {
    return PaginacionInfo(
      page: json['page'],
      pageSize: json['page_size'],
      total: json['total'],
      totalPages: json['total_pages'],
      hasNext: json['has_next'],
      hasPrev: json['has_prev'],
    );
  }
}