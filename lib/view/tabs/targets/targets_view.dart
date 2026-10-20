import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../models/response/target_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import 'targets_vm.dart';

class TargetsView extends StatefulWidget {
  const TargetsView({super.key});

  @override
  State<TargetsView> createState() => _TargetsViewState();
}

class _TargetsViewState extends State<TargetsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => TargetsViewModel()..loadTargets(),
      child: Consumer<TargetsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Sales Targets',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/targets'),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Target', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showAddTargetDialog(context, vm),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadTargets(refresh: true),
              color: AppColors.primary,
              child: vm.isBusy && vm.targets.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : vm.targets.isEmpty
                      ? EmptyStateCard(
                          title: 'No sales targets set',
                          description: 'Set monthly revenue goals for your sales team to track progress.',
                          icon: Icons.track_changes_outlined,
                          buttonText: 'Set Target',
                          onPressed: () => _showAddTargetDialog(context, vm),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: vm.targets.length,
                          itemBuilder: (context, index) {
                            final target = vm.targets[index];
                            return _buildTargetCard(context, target);
                          },
                        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetCard(BuildContext context, SalesTarget target) {
    final pct = target.progressPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  target.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pct.toStringAsFixed(1)}% Achieved',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100.0,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Achieved', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      Extractor.formatPkr(target.currentSalesPaisa),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.greenIcon),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Target Goal', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      Extractor.formatPkr(target.amountPaisa),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTargetDialog(BuildContext context, TargetsViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: 'Monthly Sales Target');
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bContext) => Padding(
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
                  const Text('Set Sales Target', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bContext)),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Target Name *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Amount (PKR) *', prefixText: 'Rs '),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(bContext);
                  final ok = await vm.createTarget({
                    'name': nameCtrl.text.trim(),
                    'scope': 'organization',
                    'amount_paisa': Extractor.toPaisa(amountCtrl.text),
                    'month': DateTime.now().toIso8601String().substring(0, 7),
                  });
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Target created successfully!')),
                    );
                  }
                },
                child: const Text('Save Target'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
