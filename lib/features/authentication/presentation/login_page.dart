import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/session.dart';
import '../../../core/design_system/error_banner.dart';
import '../../../app/theme/app_theme.dart';

enum AuthView { signIn, register, forgotPassword, resetPassword }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthView currentView = AuthView.signIn;

  final signInFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();
  final forgotFormKey = GlobalKey<FormState>();
  final resetFormKey = GlobalKey<FormState>();

  // Sign in controllers
  final signInIdentifier = TextEditingController();
  final signInPassword = TextEditingController();

  // Register controllers
  final registerName = TextEditingController();
  final registerEmail = TextEditingController();
  final registerPhone = TextEditingController();
  final registerOrgName = TextEditingController();
  final registerPassword = TextEditingController();

  // Forgot password controllers
  final forgotIdentifier = TextEditingController();

  // Reset password controllers
  final resetToken = TextEditingController();
  final resetNewPassword = TextEditingController();
  final resetConfirmPassword = TextEditingController();

  bool showPassword = false;
  bool showRegisterPassword = false;
  bool showResetPassword = false;
  bool localBusy = false;
  String? localSuccessMessage;
  Object? localError;

  @override
  void dispose() {
    signInIdentifier.dispose();
    signInPassword.dispose();
    registerName.dispose();
    registerEmail.dispose();
    registerPhone.dispose();
    registerOrgName.dispose();
    registerPassword.dispose();
    forgotIdentifier.dispose();
    resetToken.dispose();
    resetNewPassword.dispose();
    resetConfirmPassword.dispose();
    super.dispose();
  }

  void switchView(AuthView view) {
    setState(() {
      currentView = view;
      localError = null;
      localSuccessMessage = null;
    });
  }

  Future<void> handleForgotPassword() async {
    if (!forgotFormKey.currentState!.validate()) return;
    setState(() {
      localBusy = true;
      localError = null;
      localSuccessMessage = null;
    });
    try {
      final msg = await context
          .read<Session>()
          .forgotPassword(forgotIdentifier.text.trim());
      if (!mounted) return;
      setState(() {
        localSuccessMessage = msg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        localError = e;
      });
    } finally {
      if (mounted) setState(() => localBusy = false);
    }
  }

  Future<void> handleResetPassword() async {
    if (!resetFormKey.currentState!.validate()) return;
    setState(() {
      localBusy = true;
      localError = null;
      localSuccessMessage = null;
    });
    try {
      final msg = await context.read<Session>().resetPassword(
            token: resetToken.text.trim(),
            newPassword: resetNewPassword.text,
          );
      if (!mounted) return;
      setState(() {
        localSuccessMessage = msg;
        currentView = AuthView.signIn;
        signInPassword.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        localError = e;
      });
    } finally {
      if (mounted) setState(() => localBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final isBusy = session.busy || localBusy;
    final displayedError = session.lastFailure ?? session.error ?? localError;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.business_center_rounded,
                        size: 48,
                        color: AppTokens.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        switch (currentView) {
                          AuthView.signIn => 'Welcome to AW CRM',
                          AuthView.register => 'Create Account',
                          AuthView.forgotPassword => 'Forgot Password',
                          AuthView.resetPassword => 'Reset Password',
                        },
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (currentView) {
                          AuthView.signIn => 'Sign in to your business workspace',
                          AuthView.register => 'Set up your business workspace & organization',
                          AuthView.forgotPassword =>
                            'Enter your email or phone to receive reset instructions',
                          AuthView.resetPassword =>
                            'Enter your reset token and your new password',
                        },
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      if (localSuccessMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.green.shade800, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localSuccessMessage!,
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (displayedError != null) ...[
                        ApiErrorBanner(
                          error: displayedError,
                          onDismiss: () {
                            setState(() {
                              localError = null;
                              session.error = null;
                              session.lastFailure = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      switch (currentView) {
                        AuthView.signIn => _buildSignInForm(context, session, isBusy),
                        AuthView.register => _buildRegisterForm(context, session, isBusy),
                        AuthView.forgotPassword =>
                          _buildForgotPasswordForm(context, session, isBusy),
                        AuthView.resetPassword =>
                          _buildResetPasswordForm(context, session, isBusy),
                      },
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(
      BuildContext context, Session session, bool isBusy) {
    return Form(
      key: signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: signInIdentifier,
            enabled: !isBusy,
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Email or phone',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your email or phone'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: signInPassword,
            enabled: !isBusy,
            obscureText: !showPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => showPassword = !showPassword),
                icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your password' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isBusy ? null : () => switchView(AuthView.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isBusy
                ? null
                : () {
                    if (signInFormKey.currentState!.validate()) {
                      session.signIn(
                        signInIdentifier.text,
                        signInPassword.text,
                      );
                    }
                  },
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("Don't have an account?"),
              TextButton(
                onPressed: isBusy ? null : () => switchView(AuthView.register),
                child: const Text('Register'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(
      BuildContext context, Session session, bool isBusy) {
    return Form(
      key: registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: registerName,
            enabled: !isBusy,
            keyboardType: TextInputType.name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your name'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: registerEmail,
            enabled: !isBusy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your email'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: registerPhone,
            enabled: !isBusy,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number (optional)',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '03001234567',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: registerOrgName,
            enabled: !isBusy,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Organization name',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your business or organization name'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: registerPassword,
            enabled: !isBusy,
            obscureText: !showRegisterPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: showRegisterPassword ? 'Hide password' : 'Show password',
                onPressed: () =>
                    setState(() => showRegisterPassword = !showRegisterPassword),
                icon: Icon(showRegisterPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
            ),
            validator: (value) =>
                value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isBusy
                ? null
                : () {
                    if (registerFormKey.currentState!.validate()) {
                      session.register(
                        name: registerName.text,
                        email: registerEmail.text,
                        phone: registerPhone.text,
                        organizationName: registerOrgName.text,
                        password: registerPassword.text,
                      );
                    }
                  },
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create account'),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Already have an account?'),
              TextButton(
                onPressed: isBusy ? null : () => switchView(AuthView.signIn),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm(
      BuildContext context, Session session, bool isBusy) {
    return Form(
      key: forgotFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: forgotIdentifier,
            enabled: !isBusy,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Email or phone',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your email or phone'
                : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isBusy ? null : handleForgotPassword,
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send reset code'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isBusy ? null : () => switchView(AuthView.resetPassword),
            child: const Text('Have a reset token? Reset password'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isBusy ? null : () => switchView(AuthView.signIn),
            child: const Text('Back to Sign in'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm(
      BuildContext context, Session session, bool isBusy) {
    return Form(
      key: resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: resetToken,
            enabled: !isBusy,
            decoration: const InputDecoration(
              labelText: 'Reset token / code',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the reset token'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: resetNewPassword,
            enabled: !isBusy,
            obscureText: !showResetPassword,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: showResetPassword ? 'Hide password' : 'Show password',
                onPressed: () =>
                    setState(() => showResetPassword = !showResetPassword),
                icon: Icon(
                    showResetPassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) =>
                value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: resetConfirmPassword,
            enabled: !isBusy,
            obscureText: !showResetPassword,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_reset),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm your new password';
              }
              if (value != resetNewPassword.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isBusy ? null : handleResetPassword,
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update password'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: isBusy ? null : () => switchView(AuthView.signIn),
            child: const Text('Back to Sign in'),
          ),
        ],
      ),
    );
  }
}
