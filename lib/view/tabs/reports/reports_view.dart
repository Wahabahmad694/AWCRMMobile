import 'package:flutter/material.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/dashboard_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/sales_chart_widget.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _dashRepo = sl<DashboardRepository>();
  final _authRepo = sl<AuthRepository>();

  bool _loading = true;
  dynamic _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _dashRepo.getDashboardSummary(isPreview: _authRepo.isPreviewMode);
    if (mounted) {
      setState(() {
        _loading = false;
        _summary = res.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Reports & Analytics',
        isSignedIn: _authRepo.isSignedIn,
        userInitials: _authRepo.currentUser?.name ?? 'AW',
      ),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_summary != null)
                  SalesChartWidget(
                    points: _summary.salesTrends,
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Performance Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 14),
                      _reportRow('Total Sales (MTD)', Extractor.formatPkr(_summary?.salesThisMonthPaisa ?? 12550)),
                      const Divider(),
                      _reportRow('Cash Collected (MTD)', Extractor.formatPkr(_summary?.cashCollectedPaisa ?? 0)),
                      const Divider(),
                      _reportRow('Outstanding Receivables', Extractor.formatPkr(_summary?.receivablesPaisa ?? 12550)),
                      const Divider(),
                      _reportRow('Estimated Operating Profit', Extractor.formatPkr(_summary?.operatingProfitPaisa ?? 12550)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Export', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      const Text(
                        'Download CSV records for accounting, audits, and tax reconciliation.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _exportChip('Export Orders CSV'),
                          _exportChip('Export Customers CSV'),
                          _exportChip('Export Payments CSV'),
                          _exportChip('Export Expenses CSV'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _exportChip(String title) {
    return ActionChip(
      avatar: const Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
      label: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFEFF5FC),
      side: const BorderSide(color: AppColors.border),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title generated and queued for download.')),
        );
      },
    );
  }
}
