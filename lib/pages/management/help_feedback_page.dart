import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('帮助与反馈')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.headset_mic_outlined, color: AppTheme.primaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('随管科技', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            SizedBox(height: 2),
                            Text('智能工厂管理解决方案', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone_outlined, '客服电话', '400-888-9999'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email_outlined, '技术支持', 'support@suiguan.net'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.language_outlined, '官方网站', 'www.suiguan.net'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time_outlined, '服务时间', '周一至周五 9:00-18:00'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('常见问题', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _buildFaqItem('如何添加工人？', '进入管理中心 > 人工管理 > 工人管理，点击右上角添加按钮即可创建新工人。'),
                  _buildFaqItem('工人如何登录APP？', '工人使用企业编码 + 工号 + PIN码登录。PIN码可在工人管理页面中配置。'),
                  _buildFaqItem('如何创建生产工单？', '进入管理中心 > 生产管理 > 生产订单，点击新建按钮填写订单信息。'),
                  _buildFaqItem('计件工资如何录入？', '工人可在APP端提交计件记录，管理员在审批中心审核后自动计入工资。'),
                  _buildFaqItem('数据如何备份？', '系统数据由平台自动备份，您也可以联系技术支持进行手动备份。'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('意见反馈', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  const Text('如果您在使用过程中遇到任何问题或有改进建议，请通过工单支持提交反馈，我们会尽快处理。', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/management/tickets'),
                      icon: const Icon(Icons.support_agent_outlined, size: 20),
                      label: const Text('提交工单'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text('随管科技 v1.0.0', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      children: [
        Text(answer, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.6)),
      ],
    );
  }
}
