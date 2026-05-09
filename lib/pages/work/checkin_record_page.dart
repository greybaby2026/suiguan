import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class CheckinRecordPage extends StatefulWidget {
  const CheckinRecordPage({super.key});

  @override
  State<CheckinRecordPage> createState() => _CheckinRecordPageState();
}

class _CheckinRecordPageState extends State<CheckinRecordPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  dynamic _error;

  List<Map<String, dynamic>> _dailySummary = [];
  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> _allRecords = [];

  DateTime _selectedDate = DateTime.now();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      dynamic dailyResult = <String, dynamic>{}, monthlyResult = <String, dynamic>{}, recordsResult = <String, dynamic>{};
      try {
        dailyResult = await ApiService.instance.get(
          '${ApiConfig.workerCheckinsDailySummary}?date=${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
        );
      } catch (_) {}
      try {
        monthlyResult = await ApiService.instance.get(
          '${ApiConfig.workerCheckinsMonthlyStats}?month=$_selectedMonth',
        );
      } catch (_) {}
      try {
        recordsResult = await ApiService.instance.get(
          '${ApiConfig.workerCheckins}?date=${DateFormat('yyyy-MM-dd').format(_selectedDate)}&per_page=50',
        );
      } catch (_) {}

      setState(() {
        _dailySummary = _parseList(dailyResult);
        _monthlyStats = _parseList(monthlyResult);
        _allRecords = _parseList(recordsResult);
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic response) {
    if (response is List) return response.cast<Map<String, dynamic>>();
    if (response is Map) {
      final data = response['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('考勤记录'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '今日汇总'),
            Tab(text: '月度统计'),
            Tab(text: '签到明细'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadAllData)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailySummary(),
                    _buildMonthlyStats(),
                    _buildAllRecords(),
                  ],
                ),
    );
  }

  Widget _buildDailySummary() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return Column(
      children: [
        _buildDatePicker(
          label: dateStr,
          onPrev: () {
            setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
            _loadAllData();
          },
          onNext: () {
            setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
            _loadAllData();
          },
        ),
        Expanded(
          child: _dailySummary.isEmpty
              ? _buildEmpty('今日暂无考勤记录')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dailySummary.length,
                  itemBuilder: (context, index) {
                    final item = _dailySummary[index];
                    return _buildDailyCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDailyCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'absent';
    final statusInfo = _getStatusInfo(status);
    final workHours = item['work_hours'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              (item['worker_name'] ?? '-').substring(0, 1),
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item['worker_name'] ?? '-',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['worker_code'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.login, size: 14, color: AppTheme.successColor),
                    const SizedBox(width: 4),
                    Text(
                      item['checkin_time'] != null
                          ? _formatTime(item['checkin_time'])
                          : '未签到',
                      style: TextStyle(
                        fontSize: 13,
                        color: item['checkin_time'] != null ? AppTheme.textSecondary : AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.logout, size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 4),
                    Text(
                      item['checkout_time'] != null
                          ? _formatTime(item['checkout_time'])
                          : '未签退',
                      style: TextStyle(
                        fontSize: 13,
                        color: item['checkout_time'] != null ? AppTheme.textSecondary : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusInfo['label'],
                  style: TextStyle(fontSize: 12, color: statusInfo['color']),
                ),
              ),
              if (workHours != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${workHours}h',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats() {
    return Column(
      children: [
        _buildMonthPicker(
          label: _selectedMonth,
          onPrev: () {
            setState(() {
              final parts = _selectedMonth.split('-');
              final date = DateTime(int.parse(parts[0]), int.parse(parts[1]) - 1);
              _selectedMonth = DateFormat('yyyy-MM').format(date);
            });
            _loadAllData();
          },
          onNext: () {
            setState(() {
              final parts = _selectedMonth.split('-');
              final date = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1);
              _selectedMonth = DateFormat('yyyy-MM').format(date);
            });
            _loadAllData();
          },
        ),
        Expanded(
          child: _monthlyStats.isEmpty
              ? _buildEmpty('本月暂无考勤数据')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _monthlyStats.length,
                  itemBuilder: (context, index) {
                    final item = _monthlyStats[index];
                    return _buildMonthlyCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.infoColor.withOpacity(0.1),
            child: Text(
              (item['worker_name'] ?? '-').substring(0, 1),
              style: const TextStyle(color: AppTheme.infoColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item['worker_name'] ?? '-',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['worker_code'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildStatBadge('出勤', '${item['checkin_days'] ?? 0}天', AppTheme.successColor),
              const SizedBox(width: 8),
              _buildStatBadge('工时', '${item['total_hours'] ?? 0}h', AppTheme.infoColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
      ],
    );
  }

  Widget _buildAllRecords() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return Column(
      children: [
        _buildDatePicker(
          label: dateStr,
          onPrev: () {
            setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
            _loadAllData();
          },
          onNext: () {
            setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
            _loadAllData();
          },
        ),
        Expanded(
          child: _allRecords.isEmpty
              ? _buildEmpty('暂无签到明细')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allRecords.length,
                  itemBuilder: (context, index) {
                    final item = _allRecords[index];
                    return _buildRecordCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> item) {
    final type = item['type'] ?? 'checkin';
    final isCheckin = type == 'checkin';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCheckin ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCheckin ? Icons.login : Icons.logout,
              size: 20,
              color: isCheckin ? AppTheme.successColor : AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['worker']?['name'] ?? item['worker_name'] ?? '-',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  isCheckin ? '签到' : '签退',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCheckin ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(item['checkin_time']),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(item['checkin_time']),
                style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }

  Widget _buildMonthPicker({
    required String label,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'checked_out':
        return {'label': '已签退', 'color': AppTheme.successColor};
      case 'checked_in':
        return {'label': '在岗', 'color': AppTheme.infoColor};
      case 'absent':
        return {'label': '缺勤', 'color': AppTheme.dangerColor};
      default:
        return {'label': '未知', 'color': AppTheme.textHint};
    }
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '--:--';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.month}-${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
