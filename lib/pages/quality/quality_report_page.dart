import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class QualityReportPage extends StatefulWidget {
  const QualityReportPage({super.key});

  @override
  State<QualityReportPage> createState() => _QualityReportPageState();
}

class _QualityReportPageState extends State<QualityReportPage> {
  final ApiService _api = ApiService.instance;
  bool _isLoading = true;
  dynamic _error;
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get(ApiConfig.dashboardQualityRate);
      setState(() { _summary = response['data'] ?? response; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('质量报表')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadData)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatCard('合格率', '${_summary['quality_rate'] ?? _summary['rate'] ?? 0}%', AppTheme.successColor, Icons.verified_outlined),
                      const SizedBox(height: 12),
                      _buildStatCard('总检验数', '${_summary['total'] ?? _summary['total_count'] ?? 0}', AppTheme.primaryColor, Icons.fact_check_outlined),
                      const SizedBox(height: 12),
                      _buildStatCard('合格数', '${_summary['passed'] ?? _summary['pass_count'] ?? 0}', AppTheme.successColor, Icons.check_circle_outline),
                      const SizedBox(height: 12),
                      _buildStatCard('不合格数', '${_summary['failed'] ?? _summary['fail_count'] ?? 0}', AppTheme.dangerColor, Icons.cancel_outlined),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
