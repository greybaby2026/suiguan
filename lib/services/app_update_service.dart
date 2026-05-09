import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  int _currentVersionCode = 0;
  String _currentVersionName = '';

  Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _currentVersionName = info.version;
    _currentVersionCode = int.tryParse(info.buildNumber) ?? 1;
  }

  int get currentVersionCode => _currentVersionCode;
  String get currentVersionName => _currentVersionName;

  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final response = await ApiService.instance.get(
        ApiConfig.appVersionCheck,
        queryParameters: {
          'version_code': _currentVersionCode,
          'platform': 'android',
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final data = response['data'] ?? response;
      if (data is Map && data['need_update'] == true) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> showUpdateDialog(BuildContext context, {Map<String, dynamic>? updateInfo}) async {
    if (updateInfo == null) {
      updateInfo = await checkUpdate();
    }
    if (!context.mounted) return;

    if (updateInfo == null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('检查更新'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('当前已是最新版本', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text('版本 v$_currentVersionName ($_currentVersionCode)', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final latest = updateInfo['latest_version'] as Map<String, dynamic>?;
    if (latest == null) return;

    final forceUpdate = updateInfo['force_update'] == true || latest['force_update'] == true;
    final versionName = latest['version_name']?.toString() ?? '';
    final updateContent = latest['update_content']?.toString() ?? '';
    final downloadUrl = latest['download_url']?.toString() ?? '';
    final fileSize = latest['file_size'] as int? ?? 0;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogContext) => _UpdateDialog(
        versionName: versionName,
        updateContent: updateContent,
        downloadUrl: downloadUrl,
        fileSize: fileSize,
        forceUpdate: forceUpdate,
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String versionName;
  final String updateContent;
  final String downloadUrl;
  final int fileSize;
  final bool forceUpdate;

  const _UpdateDialog({
    required this.versionName,
    required this.updateContent,
    required this.downloadUrl,
    required this.fileSize,
    required this.forceUpdate,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _statusText = '';
  bool _downloadComplete = false;
  String? _apkPath;

  @override
  void initState() {
    super.initState();
    _statusText = widget.fileSize > 0
        ? '下载安装包 (${_formatFileSize(widget.fileSize)})'
        : '下载安装包';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forceUpdate && !_isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.system_update_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('发现新版本 v${widget.versionName}')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.forceUpdate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('此版本为强制更新', style: TextStyle(fontSize: 12, color: AppTheme.dangerColor, fontWeight: FontWeight.w600)),
              ),
            if (widget.forceUpdate) const SizedBox(height: 12),
            if (widget.updateContent.isNotEmpty) ...[
              const Text('更新内容：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(
                    widget.updateContent,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                  ),
                ),
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 6),
              Text(
                _statusText,
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.forceUpdate && !_isDownloading && !_downloadComplete)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后再说'),
            ),
          if (!_isDownloading && !_downloadComplete)
            ElevatedButton(
              onPressed: widget.downloadUrl.isEmpty ? null : _startDownload,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('立即更新'),
            ),
          if (_downloadComplete)
            ElevatedButton(
              onPressed: _installApk,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
              child: const Text('安装'),
            ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    if (widget.downloadUrl.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _statusText = '准备下载...';
    });

    try {
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final fileName = 'suiguan_v${widget.versionName}.apk';
      final savePath = '${dir.path}/$fileName';

      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      await Dio().download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _progress = received / total;
              _statusText = '${(_progress * 100).toStringAsFixed(1)}% (${_formatFileSize(received)}/${_formatFileSize(total)})';
            });
          } else {
            setState(() {
              _statusText = '已下载 ${_formatFileSize(received)}';
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadComplete = true;
        _apkPath = savePath;
        _statusText = '下载完成，点击安装';
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _progress = 0;
        _statusText = '下载失败: $e';
      });
    }
  }

  Future<void> _installApk() async {
    if (_apkPath == null) return;

    final file = File(_apkPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('安装包文件不存在，请重新下载'), backgroundColor: AppTheme.dangerColor),
        );
      }
      return;
    }

    try {
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          final result = await Permission.requestInstallPackages.request();
          if (!result.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('需要允许安装未知应用权限才能安装更新'),
                  backgroundColor: AppTheme.warningColor,
                  duration: Duration(seconds: 5),
                ),
              );
            }
            await openAppSettings();
            return;
          }
        }
      }

      final result = await OpenFilex.open(_apkPath!, type: 'application/vnd.android.package-archive');

      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('安装失败: ${result.message}'),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('安装异常: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
