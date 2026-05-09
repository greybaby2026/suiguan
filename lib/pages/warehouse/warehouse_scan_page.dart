import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/warehouse_provider.dart';
import 'package:provider/provider.dart';

class WarehouseScanPage extends StatefulWidget {
  const WarehouseScanPage({super.key});

  @override
  State<WarehouseScanPage> createState() => _WarehouseScanPageState();
}

class _WarehouseScanPageState extends State<WarehouseScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  String? _lastScannedCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    _lastScannedCode = code;
    _scannerController.stop();

    _handleScanResult(code);
  }

  Future<void> _handleScanResult(String code) async {
    final provider = context.read<WarehouseProvider>();
    final success = await provider.scanItem(code);

    if (!mounted) return;

    if (success && provider.scannedItem != null) {
      _showItemDetail(provider.scannedItem!);
    } else {
      _showScanError(code, provider.error ?? '未找到对应库存信息');
    }
  }

  void _showItemDetail(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppTheme.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName ?? '未知物品',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.itemCode ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('规格', item.itemSpec ?? '-'),
                  _buildDetailRow('单位', item.itemUnit ?? '-'),
                  _buildDetailRow(
                    '库存数量',
                    '${item.quantity.toStringAsFixed(0)}',
                    valueColor: item.isLowStock ? AppTheme.dangerColor : AppTheme.successColor,
                  ),
                  if (item.safetyStock != null)
                    _buildDetailRow(
                      '安全库存',
                      '${item.safetyStock!.toStringAsFixed(0)}',
                      valueColor: AppTheme.warningColor,
                    ),
                  _buildDetailRow('仓库', item.warehouseName ?? '-'),
                  if (item.isLowStock) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.dangerColor.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '库存不足，低于安全库存',
                            style: TextStyle(
                              color: AppTheme.dangerColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetScanner();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('继续扫码'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/warehouse/inventory');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('查看库存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showScanError(String code, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('扫码结果: $code\n$error'),
        backgroundColor: AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: _resetScanner,
        ),
      ),
    );
    _resetScanner();
  }

  void _resetScanner() {
    _lastScannedCode = null;
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('仓库扫码', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          _buildScanOverlay(),
          _buildManualInput(),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              '将二维码放入框内',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 60,
      child: Column(
        children: [
          TextButton.icon(
            onPressed: () {
              _showManualInputDialog();
            },
            icon: const Icon(Icons.keyboard_outlined, color: Colors.white70),
            label: const Text(
              '手动输入编码',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickNavButton(
                icon: Icons.inventory_2_outlined,
                label: '库存查询',
                onTap: () => context.push('/warehouse/inventory'),
              ),
              const SizedBox(width: 24),
              _QuickNavButton(
                icon: Icons.swap_horiz,
                label: '出入库',
                onTap: () => context.push('/warehouse/movements'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('输入物料编码'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入物料编码',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              Navigator.pop(context);
              if (code.isNotEmpty) {
                _handleScanResult(code);
              }
            },
            child: const Text('查询'),
          ),
        ],
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
