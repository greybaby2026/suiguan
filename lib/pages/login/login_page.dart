import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _tenantCodeController = TextEditingController();
  final _workerCodeController = TextEditingController();
  final _pinController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isWorkerMode = true;
  bool _obscurePassword = true;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.savedTenantCode.isNotEmpty) {
        _tenantCodeController.text = authProvider.savedTenantCode;
      }
    });
  }

  @override
  void dispose() {
    _tenantCodeController.dispose();
    _workerCodeController.dispose();
    _pinController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final tenantCode = _tenantCodeController.text.trim();

    bool success;
    if (_isWorkerMode) {
      success = await authProvider.workerLogin(
        tenantCode: tenantCode,
        code: _workerCodeController.text.trim(),
        pin: _pinController.text,
      );
    } else {
      success = await authProvider.adminLogin(
        account: _accountController.text.trim(),
        password: _passwordController.text,
        tenantCode: tenantCode,
      );
    }

    if (!mounted) return;

    if (success) {
      context.go('/dashboard');
    } else {
      _showError(authProvider.error ?? '登录失败');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.accentColor.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildModeSwitch(),
                  const SizedBox(height: 24),
                  _buildForm(authProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: AppTheme.gradientDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.precision_manufacturing_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '随管科技',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '智能工厂管理系统',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isWorkerMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _isWorkerMode
                      ? LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '工人登录',
                    style: TextStyle(
                      color: _isWorkerMode ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isWorkerMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: !_isWorkerMode
                      ? LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '管理登录',
                    style: TextStyle(
                      color: !_isWorkerMode ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 租户代码（两种模式都需要）
          TextFormField(
            controller: _tenantCodeController,
            decoration: const InputDecoration(
              hintText: '企业编码',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (v) => v?.isEmpty == true ? '请输入企业编码' : null,
          ),
          const SizedBox(height: 14),

          if (_isWorkerMode) ...[
            // 工人模式：工号 + PIN
            TextFormField(
              controller: _workerCodeController,
              decoration: const InputDecoration(
                hintText: '工号',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => v?.isEmpty == true ? '请输入工号' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'PIN码（6位数字）',
                prefixIcon: const Icon(Icons.pin_outlined),
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textHint,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) {
                if (v?.isEmpty == true) return '请输入PIN码';
                if (v!.length != 6) return 'PIN码为6位数字';
                return null;
              },
            ),
          ] else ...[
            // 管理模式：手机号 + 密码
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                hintText: '请输入手机号',
                prefixIcon: Icon(Icons.phone_android_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty == true ? '请输入手机号' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '密码',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textHint,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v?.isEmpty == true ? '请输入密码' : null,
            ),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleLogin,
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('登录'),
            ),
          ),
        ],
      ),
    );
  }
}
