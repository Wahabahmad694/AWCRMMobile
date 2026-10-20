import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../models/response/team_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/string_helpers.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import '../../widget/status_badge.dart';
import 'team_vm.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => TeamViewModel()..loadMembers(),
      child: Consumer<TeamViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Team',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/team'),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
              label: const Text('Invite Member', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showInviteDialog(context, vm),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadMembers(refresh: true),
              color: AppColors.primary,
              child: vm.isBusy && vm.members.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : vm.members.isEmpty
                      ? EmptyStateCard(
                          title: 'No team members found',
                          description: 'Invite salespeople, accountants, and managers to your organization.',
                          icon: Icons.group_outlined,
                          buttonText: 'Invite Member',
                          onPressed: () => _showInviteDialog(context, vm),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: vm.members.length,
                          itemBuilder: (context, index) {
                            final member = vm.members[index];
                            return _buildMemberCard(context, member);
                          },
                        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, TeamMember m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFD8E9FA),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                StringHelpers.initials(m.name),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(m.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            StatusBadge(status: m.role),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, TeamViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    String role = 'sales';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(bContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Invite Member', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bContext)),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address *'),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'sales', child: Text('Sales')),
                    DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  ],
                  onChanged: (v) => setModalState(() => role = v ?? 'sales'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(bContext);
                    final ok = await vm.inviteMember(email: emailCtrl.text.trim(), role: role);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitation sent successfully!')),
                      );
                    }
                  },
                  child: const Text('Send Invitation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
