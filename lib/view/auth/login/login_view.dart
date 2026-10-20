import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import 'login_vm.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regOrgController = TextEditingController();
  final _regPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regOrgController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Consumer<LoginViewModel>(
                    builder: (context, vm, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'AW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AW CRM',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'Built for your next chapter',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Tab switcher
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF3F8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textSecondary,
                              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Sign in'),
                                Tab(text: 'Register'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Error Message if present
                          if (vm.hasError)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.redIconBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.redIcon.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.redIcon, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      vm.errorMessage!,
                                      style: const TextStyle(color: AppColors.redIcon, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Tabs Content
                          SizedBox(
                            height: _tabController.index == 0 ? 270 : 420,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: Sign in
                                _buildLoginForm(context, vm),
                                // Tab 2: Register
                                _buildRegisterForm(context, vm),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginViewModel vm) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginIdentifierController,
            decoration: const InputDecoration(
              labelText: 'Email or phone',
              hintText: 'user@company.com',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: !vm.isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  vm.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: vm.togglePasswordVisibility,
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context, vm),
              child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: vm.isBusy
                ? null
                : () async {
                    if (!_loginFormKey.currentState!.validate()) return;
                    final ok = await vm.login(
                      _loginIdentifierController.text,
                      _loginPasswordController.text,
                    );
                    if (ok && context.mounted) {
                      context.go('/dashboard');
                    }
                  },
            child: vm.isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Sign in to Workspace'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, LoginViewModel vm) {
    return Form(
      key: _registerFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _regNameController,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline, size: 20)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline, size: 20)),
              validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regOrgController,
              decoration: const InputDecoration(labelText: 'Business name', prefixIcon: Icon(Icons.business_outlined, size: 20)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regPasswordController,
              obscureText: !vm.isPasswordVisible,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
              validator: (v) => v == null || v.length < 6 ? 'At least 6 characters' : null,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: vm.isBusy
                  ? null
                  : () async {
                      if (!_registerFormKey.currentState!.validate()) return;
                      final ok = await vm.register(
                        name: _regNameController.text,
                        email: _regEmailController.text,
                        phone: _regPhoneController.text,
                        organizationName: _regOrgController.text,
                        password: _regPasswordController.text,
                      );
                      if (ok && context.mounted) {
                        context.go('/dashboard');
                      }
                    },
              child: vm.isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Create Workspace Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, LoginViewModel vm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forgot password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address or phone number and we will send you password reset instructions.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Email or phone'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              final msg = await vm.forgotPassword(controller.text);
              if (msg != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}
