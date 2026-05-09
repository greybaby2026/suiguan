import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class WorkCheckinPage extends StatefulWidget {
  const WorkCheckinPage({super.key});

  @override
  State<WorkCheckinPage> createState() => _WorkCheckinPageState();
}

class _WorkCheckinPageState extends State<WorkCheckinPage> {
  bool _hasCheckedIn = false;
  DateTime? _checkinTime;
  DateTime? _checkoutTime;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  Future<void> _loadTodayStatus() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.instance.get(ApiConfig.workerCheckinToday);
      final data = result['data'];
      if (data != null && data is Map<String, dynamic>) {
        final checkinData = data['checkin'] as Map<String, dynamic>?;
        final checkoutData = data['checkout'] as Map<String, dynamic>?;
        if (checkinData != null && checkinData['checkin_time'] != null) {
          setState(() {
            _hasCheckedIn = true;
            _checkinTime = DateTime.tryParse(checkinData['checkin_time'].toString());
          });
        }
        if (checkoutData != null && checkoutData['checkin_time'] != null) {
          setState(() {
            _checkoutTime = DateTime.tryParse(checkoutData['checkin_time'].toString());
          });
        }
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckin() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.instance.post(
        ApiConfig.workerCheckin,
        data: {'type': 'checkin'},
      );
      final data = result['data'];
      final checkinAt = data?['checkin_time'] ?? data?['created_at'];
      setState(() {
        _hasCheckedIn = true;
        _checkinTime = checkinAt != null ? DateTime.tryParse(checkinAt.toString()) ?? DateTime.now() : DateTime.now();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上班打卡成功 ${_formatTime(_checkinTime!)}'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打卡失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleCheckout() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.instance.post(
        ApiConfig.workerCheckin,
        data: {'type': 'checkout'},
      );
      final data = result['data'];
      final checkoutAt = data?['checkin_time'] ?? data?['created_at'];
      setState(() {
        _checkoutTime = checkoutAt != null ? DateTime.tryParse(checkoutAt.toString()) ?? DateTime.now() : DateTime.now();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下班打卡成功 ${_formatTime(_checkoutTime!)}'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打卡失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('打卡')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildClock(now),
                  const SizedBox(height: 32),
                  _buildCheckinButton(),
                  const SizedBox(height: 24),
                  _buildRecords(),
                ],
              ),
            ),
    );
  }

  Widget _buildClock(DateTime now) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: AppTheme.gradientDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _formatDate(now),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final current = DateTime.now();
              return Text(
                _formatTime(current),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinButton() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _hasCheckedIn ? null : _handleCheckin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _hasCheckedIn ? AppTheme.successColor.withOpacity(0.1) : AppTheme.successColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _isSubmitting && !_hasCheckedIn
                      ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(
                          Icons.login_rounded,
                          color: _hasCheckedIn ? AppTheme.successColor : Colors.white,
                          size: 32,
                        ),
                  const SizedBox(height: 8),
                  Text(
                    _hasCheckedIn ? '已打卡' : '上班打卡',
                    style: TextStyle(
                      color: _hasCheckedIn ? AppTheme.successColor : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_checkinTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(_checkinTime!),
                      style: TextStyle(
                        color: _hasCheckedIn ? AppTheme.successColor.withOpacity(0.7) : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _hasCheckedIn && _checkoutTime == null ? _handleCheckout : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _checkoutTime != null
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : _hasCheckedIn
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _isSubmitting && _hasCheckedIn && _checkoutTime == null
                      ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(
                          Icons.logout_rounded,
                          color: _checkoutTime != null
                              ? AppTheme.primaryColor
                              : _hasCheckedIn
                                  ? Colors.white
                                  : Colors.white54,
                          size: 32,
                        ),
                  const SizedBox(height: 8),
                  Text(
                    _checkoutTime != null ? '已签退' : '下班打卡',
                    style: TextStyle(
                      color: _checkoutTime != null
                          ? AppTheme.primaryColor
                          : _hasCheckedIn
                              ? Colors.white
                              : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_checkoutTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(_checkoutTime!),
                      style: TextStyle(
                        color: AppTheme.primaryColor.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecords() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日打卡记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_checkinTime == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '暂无打卡记录',
                  style: TextStyle(color: AppTheme.textHint),
                ),
              ),
            )
          else ...[
            _buildRecordItem(
              icon: Icons.login_rounded,
              label: '上班打卡',
              time: _formatTime(_checkinTime!),
              color: AppTheme.successColor,
            ),
            if (_checkoutTime != null) ...[
              const SizedBox(height: 12),
              _buildRecordItem(
                icon: Icons.logout_rounded,
                label: '下班打卡',
                time: _formatTime(_checkoutTime!),
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              _buildDurationItem(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRecordItem({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
        const Spacer(),
        Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildDurationItem() {
    if (_checkinTime == null || _checkoutTime == null) return const SizedBox.shrink();
    final duration = _checkoutTime!.difference(_checkinTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18, color: AppTheme.infoColor),
          const SizedBox(width: 8),
          const Text('工作时长', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(
            '$hours小时$minutes分钟',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.infoColor,
            ),
          ),
        ],
      ),
    );
  }
}
