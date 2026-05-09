import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class QualityInspectionPage extends StatefulWidget {
  const QualityInspectionPage({super.key});

  @override
  State<QualityInspectionPage> createState() => _QualityInspectionPageState();
}

class _QualityInspectionPageState extends State<QualityInspectionPage> {
  final ApiService _api = ApiService.instance;
  bool _isLoading = true;
  dynamic _error;
  List<Map<String, dynamic>> _inspections = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get(ApiConfig.qualityInspections);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }
      setState(() { _inspections = list.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = e; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('质检列表')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadData)
              : _inspections.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.verified_outlined, size: 48, color: AppTheme.textHint),
                        const SizedBox(height: 8),
                        const Text('暂无质检记录', style: TextStyle(color: AppTheme.textHint)),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: _inspections.length,
                        itemBuilder: (context, index) => _buildCard(_inspections[index]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final status = item['status'] ?? item['result'] ?? '';
    final statusColor = status == 'passed' || status == 'pass' ? AppTheme.successColor : status == 'failed' || status == 'fail' ? AppTheme.dangerColor : AppTheme.warningColor;
    final statusLabel = status == 'passed' || status == 'pass' ? '合格' : status == 'failed' || status == 'fail' ? '不合格' : '待检';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.verified_outlined, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['order_no'] ?? item['inspection_no'] ?? '质检#${item['id'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item['inspector_name'] ?? item['inspector'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
