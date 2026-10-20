import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import 'activities_vm.dart';

class ActivitiesView extends StatefulWidget {
  const ActivitiesView({super.key});

  @override
  State<ActivitiesView> createState() => _ActivitiesViewState();
}

class _ActivitiesViewState extends State<ActivitiesView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => ActivitiesViewModel()..loadData(),
      child: Consumer<ActivitiesViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Activities',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/activities'),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 20),
              label: Text(vm.selectedTab == 0 ? 'Log Activity' : 'Add Reminder', style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showAddActionDialog(context, vm),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadData(refresh: true),
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => vm.selectTab(0),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: vm.selectedTab == 0 ? AppColors.primarySubtle : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Activity Log (${vm.activities.length})',
                                style: TextStyle(
                                  color: vm.selectedTab == 0 ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: vm.selectedTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => vm.selectTab(1),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: vm.selectedTab == 1 ? AppColors.primarySubtle : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Follow-up Reminders (${vm.reminders.length})',
                                style: TextStyle(
                                  color: vm.selectedTab == 1 ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: vm.selectedTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: vm.isBusy && vm.activities.isEmpty && vm.reminders.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : vm.selectedTab == 0
                            ? _buildActivitiesList(context, vm)
                            : _buildRemindersList(context, vm),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitiesList(BuildContext context, ActivitiesViewModel vm) {
    if (vm.activities.isEmpty) {
      return EmptyStateCard(
        title: 'No logged activities',
        description: 'Keep track of phone calls, meetings, WhatsApp follow-ups, and notes.',
        icon: Icons.checklist_outlined,
        buttonText: 'Log Activity',
        onPressed: () => _showAddActionDialog(context, vm),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: vm.activities.length,
      itemBuilder: (context, index) {
        final act = vm.activities[index];
        IconData icon = Icons.note_outlined;
        if (act.type == 'call') icon = Icons.phone_outlined;
        if (act.type == 'meeting') icon = Icons.groups_outlined;
        if (act.type == 'whatsapp') icon = Icons.chat_bubble_outline;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(act.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      if (act.customerName != null)
                        Text('Customer: ${act.customerName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (act.body != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(act.body!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                        ),
                    ],
                  ),
                ),
                if (!act.isCompleted)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.textMuted),
                    tooltip: 'Mark as completed',
                    onPressed: () => vm.completeActivity(act.id, act.version),
                  )
                else
                  const Icon(Icons.check_circle_rounded, color: AppColors.greenIcon, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemindersList(BuildContext context, ActivitiesViewModel vm) {
    if (vm.reminders.isEmpty) {
      return EmptyStateCard(
        title: 'No pending reminders',
        description: 'Set follow-up reminders to call back clients or review quotation status.',
        icon: Icons.alarm_outlined,
        buttonText: 'Add Reminder',
        onPressed: () => _showAddActionDialog(context, vm),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: vm.reminders.length,
      itemBuilder: (context, index) {
        final rem = vm.reminders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.orangeIconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.alarm_outlined, color: AppColors.orangeIcon, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rem.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      if (rem.dueAt != null)
                        Text('Due: ${Extractor.formatDateTime(rem.dueAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      if (rem.body != null)
                        Text(rem.body!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddActionDialog(BuildContext context, ActivitiesViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String type = 'call';

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
                    Text(vm.selectedTab == 0 ? 'Log Activity' : 'Add Reminder', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bContext)),
                  ],
                ),
                const SizedBox(height: 14),
                if (vm.selectedTab == 0)
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Activity Type'),
                    items: const [
                      DropdownMenuItem(value: 'call', child: Text('Phone Call')),
                      DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                      DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                      DropdownMenuItem(value: 'note', child: Text('Note / Memo')),
                    ],
                    onChanged: (v) => setModalState(() => type = v ?? 'call'),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: bodyCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Details / Discussion Notes'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(bContext);
                    if (vm.selectedTab == 0) {
                      await vm.createActivity({
                        'type': type,
                        'subject': subjectCtrl.text.trim(),
                        if (bodyCtrl.text.isNotEmpty) 'body': bodyCtrl.text.trim(),
                      });
                    } else {
                      await vm.createReminder({
                        'subject': subjectCtrl.text.trim(),
                        'due_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                        if (bodyCtrl.text.isNotEmpty) 'body': bodyCtrl.text.trim(),
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
