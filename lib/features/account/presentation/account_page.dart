import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/session.dart';
import '../../../core/design_system/error_banner.dart';
import '../../../app/theme/app_theme.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPasswords = false;
  bool _passwordBusy = false;
  String? _passwordSuccess;
  Object? _passwordError;

  List<AuthSession>? _sessions;
  bool _sessionsLoading = false;
  Object? _sessionsError;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final session = context.read<Session>();
    if (session.previewMode) return;
    setState(() {
      _sessionsLoading = true;
      _sessionsError = null;
    });
    try {
      final list = await session.getSessions();
      if (!mounted) return;
      setState(() => _sessions = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sessionsError = e);
    } finally {
      if (mounted) setState(() => _sessionsLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final session = context.read<Session>();
    if (session.previewMode) {
      setState(() {
        _passwordSuccess = 'Password change simulated (preview mode).';
        _passwordError = null;
      });
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      return;
    }

    setState(() {
      _passwordBusy = true;
      _passwordSuccess = null;
      _passwordError = null;
    });

    try {
      final msg = await session.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _passwordSuccess = msg;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordError = e);
    } finally {
      if (mounted) setState(() => _passwordBusy = false);
    }
  }

  Future<void> _revokeSession(AuthSession s) async {
    final session = context.read<Session>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.isCurrent ? 'Terminate current session?' : 'Revoke session?'),
        content: Text(s.isCurrent
            ? 'This will sign you out on this device. You will need to sign in again.'
            : 'This device will be logged out immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isCurrent ? 'Sign out' : 'Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (session.previewMode) {
      setState(() {
        _sessions?.removeWhere((item) => item.id == s.id);
      });
      return;
    }

    try {
      await session.revokeSession(s.id);
      if (!mounted) return;
      if (s.isCurrent) {
        await session.signOut();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session revoked successfully')),
        );
        _loadSessions();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to revoke session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;
    final membership = session.currentMembership;

    return RefreshIndicator(
      onRefresh: () async {
        await session.loadProfile();
        await _loadSessions();
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Account & Organization',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Manage your profile credentials, active sessions, and workspace access.'),
          const SizedBox(height: 24),

          // User Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? (session.previewMode ? 'Preview User' : 'User Profile'),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? (session.previewMode ? 'preview@awcrm.test' : 'No email loaded'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTokens.muted),
                            ),
                            if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.phone!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTokens.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Organization & Access',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.business, size: 18),
                        label: Text('Org: ${membership?.name ?? 'Organization'}'),
                      ),
                      if (membership?.role != null)
                        Chip(
                          avatar: const Icon(Icons.badge_outlined, size: 18),
                          label: Text('Role: ${membership!.role}'),
                        ),
                      Chip(
                        avatar: Icon(
                          session.readOnly ? Icons.lock_outline : Icons.check_circle_outline,
                          size: 18,
                          color: session.readOnly ? Colors.orange : Colors.green,
                        ),
                        label: Text(session.readOnly ? 'Subscription: Read-Only' : 'Subscription: Active'),
                      ),
                    ],
                  ),
                  if (membership != null && membership.permissions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Permissions (${membership.permissions.length}):',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final perm in membership.permissions)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              perm,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Change Password Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text('Update your password to keep your account secure.'),
                    const SizedBox(height: 16),
                    if (_passwordSuccess != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade800, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _passwordSuccess!,
                                style: TextStyle(color: Colors.green.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_passwordError != null) ...[
                      ApiErrorBanner(
                        error: _passwordError!,
                        onDismiss: () => setState(() => _passwordError = null),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _currentPasswordController,
                      enabled: !_passwordBusy,
                      obscureText: !_showPasswords,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_showPasswords ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showPasswords = !_showPasswords),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      enabled: !_passwordBusy,
                      obscureText: !_showPasswords,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !_passwordBusy,
                      obscureText: !_showPasswords,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Confirm new password';
                        if (val != _newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: _passwordBusy ? null : _changePassword,
                        child: _passwordBusy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Update password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active Sessions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Sessions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text('Devices currently authenticated into this account.'),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Refresh sessions',
                        icon: const Icon(Icons.refresh),
                        onPressed: _sessionsLoading ? null : _loadSessions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_sessionsError != null) ...[
                    ApiErrorBanner(
                      error: _sessionsError!,
                      onDismiss: () => setState(() => _sessionsError = null),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_sessionsLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_sessions == null || _sessions!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        session.previewMode
                            ? 'Preview mode: No live sessions.'
                            : 'No active session records returned.',
                        style: const TextStyle(color: AppTokens.muted),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sessions!.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final s = _sessions![index];
                        final df = DateFormat('MMM d, y • h:mm a');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: s.isCurrent
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.devices_rounded,
                              size: 20,
                              color: s.isCurrent
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.userAgent ?? 'Unknown client',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (s.isCurrent)
                                const Chip(
                                  label: Text('Current session', style: TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.ipAddress != null && s.ipAddress!.isNotEmpty)
                                Text('IP: ${s.ipAddress}'),
                              if (s.createdAt != null)
                                Text('Signed in: ${df.format(s.createdAt!)}'),
                              if (s.lastActiveAt != null)
                                Text('Last active: ${df.format(s.lastActiveAt!)}'),
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: s.isCurrent ? 'Terminate session' : 'Revoke session',
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _revokeSession(s),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
