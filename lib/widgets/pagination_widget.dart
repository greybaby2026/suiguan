import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class PaginationWidget<T> extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(int page, int pageSize) fetchData;
  final Widget Function(List<T> items) builder;
  final String dataKey;
  final int pageSize;
  final Widget? emptyWidget;

  const PaginationWidget({
    super.key,
    required this.fetchData,
    required this.builder,
    this.dataKey = 'data',
    this.pageSize = 15,
    this.emptyWidget,
  });

  @override
  State<PaginationWidget<T>> createState() => _PaginationWidgetState<T>();
}

class _PaginationWidgetState<T> extends State<PaginationWidget<T>> {
  List<T> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  bool get _hasMore => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final response = await widget.fetchData(1, widget.pageSize);
      _parseResponse(response);
      _currentPage = 1;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await widget.fetchData(nextPage, widget.pageSize);
      final newItems = _extractItems(response);
      final pagination = _extractPagination(response);

      _currentPage = nextPage;
      _items = [..._items, ...newItems];
      if (pagination != null) {
        _total = pagination['total'] ?? _items.length;
        final lastPage = pagination['last_page'] ?? pagination['total_pages'] ?? 1;
        _totalPages = lastPage;
      }

      if (mounted) setState(() => _isLoadingMore = false);
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _parseResponse(Map<String, dynamic> response) {
    _items = _extractItems(response);
    final pagination = _extractPagination(response);
    if (pagination != null) {
      _total = pagination['total'] ?? _items.length;
      final lastPage = pagination['last_page'] ?? pagination['total_pages'] ?? 1;
      _totalPages = lastPage;
    } else {
      _total = _items.length;
      _totalPages = _items.length >= widget.pageSize ? 2 : 1;
    }
  }

  List<T> _extractItems(Map<String, dynamic> response) {
    final data = response[widget.dataKey];
    if (data is List) {
      return data.cast<T>();
    }
    if (data is Map && data.containsKey('data')) {
      final inner = data['data'];
      if (inner is List) return inner.cast<T>();
    }
    if (response.containsKey('data')) {
      final d = response['data'];
      if (d is List) return d.cast<T>();
      if (d is Map && d.containsKey('data')) {
        final inner = d['data'];
        if (inner is List) return inner.cast<T>();
      }
    }
    return [];
  }

  Map<String, dynamic>? _extractPagination(Map<String, dynamic> response) {
    if (response.containsKey('pagination')) {
      return response['pagination'] as Map<String, dynamic>?;
    }
    final data = response['data'];
    if (data is Map && data.containsKey('pagination')) {
      return data['pagination'] as Map<String, dynamic>?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
            const SizedBox(height: 12),
            Text('加载失败', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFirstPage,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmpty();
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          Expanded(child: widget.builder(_items)),
          if (_hasMore || _isLoadingMore) _buildLoadMore(),
          _buildPageInfo(),
        ],
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无数据', style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
              )
            : TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more, size: 18),
                label: const Text('加载更多'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              ),
      ),
    );
  }

  Widget _buildPageInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '共 $_total 条',
              style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 20,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_currentPage/$_totalPages',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                  ),
                ),
                IconButton(
                  onPressed: _hasMore ? () => _goToPage(_currentPage + 1) : null,
                  icon: const Icon(Icons.chevron_right, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToPage(int page) async {
    setState(() => _isLoading = true);
    try {
      final response = await widget.fetchData(page, widget.pageSize);
      _parseResponse(response);
      _currentPage = page;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
