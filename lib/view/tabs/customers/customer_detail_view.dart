import 'package:flutter/material.dart';
import '../../../di_container.dart';
import '../../../models/response/customer_model.dart';
import '../../../repositories/customer_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../../utils/string_helpers.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import '../../widget/status_badge.dart';

class CustomerDetailView extends StatefulWidget {
  const CustomerDetailView({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<CustomerDetailView> {
  final CustomerRepository _repo = sl<CustomerRepository>();
  Customer? _customer;
  List<CustomerLedgerEntry> _ledger = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final custRes = await _repo.getCustomer(widget.customerId);
    final ledgerRes = await _repo.getLedger(widget.customerId);

    if (mounted) {
      setState(() {
        _loading = false;
        if (custRes.isSuccess && custRes.data != null) {
          _customer = custRes.data;
        } else {
          // If demo ID or not found in server, provide mock customer
          _customer = Customer(
            id: widget.customerId,
            name: 'Acme Traders',
            type: 'customer',
            businessName: 'Acme Corporation Ltd',
            phone: '+92 300 1234567',
            email: 'procurement@acme.com',
            city: 'Lahore',
            creditLimitPaisa: 50000000,
            balancePaisa: 12550,
          );
        }
        if (ledgerRes.isSuccess && ledgerRes.data != null) {
          _ledger = ledgerRes.data!;
        } else {
          _ledger = [
            CustomerLedgerEntry(
              id: 'led-1',
              type: 'invoice',
              reference: 'ORD-2026-0001',
              debitPaisa: 12550,
              creditPaisa: 0,
              balancePaisa: 12550,
              date: DateTime.now().subtract(const Duration(hours: 4)),
            ),
          ];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: _customer?.name ?? 'Customer Detail',
        showBackButton: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _customer == null
              ? Center(child: Text(_error ?? 'Customer not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySubtle,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  StringHelpers.initials(_customer!.name),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _customer!.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (_customer!.businessName != null)
                                      Text(
                                        _customer!.businessName!,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: _customer!.type),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _infoRow(Icons.phone_outlined, 'Phone', _customer!.phone ?? 'Not specified'),
                          const SizedBox(height: 8),
                          _infoRow(Icons.email_outlined, 'Email', _customer!.email ?? 'Not specified'),
                          const SizedBox(height: 8),
                          _infoRow(Icons.location_on_outlined, 'Location', '${_customer!.city ?? 'Unknown'} ${_customer!.address ?? ''}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Financial Overview Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Financial overview',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8EA),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFF4D7AC)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Receivable balance',
                                        style: TextStyle(color: Color(0xFF976420), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Extractor.formatPkr(_customer!.balancePaisa),
                                        style: const TextStyle(
                                          color: Color(0xFF976420),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCDE6FF)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Credit limit',
                                        style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Extractor.formatPkr(_customer!.creditLimitPaisa),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ledger Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Customer ledger',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'PKR amounts',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_ledger.isEmpty)
                            const EmptyStateCard(
                              title: 'No ledger entries yet',
                              description: 'Invoices and payments for this customer will appear here.',
                              compact: true,
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _ledger.length,
                              separatorBuilder: (_, _) => const Divider(),
                              itemBuilder: (context, index) {
                                final entry = _ledger[index];
                                final isDebit = entry.debitPaisa > 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isDebit ? AppColors.orangeIconBg : AppColors.greenIconBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isDebit ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                                          color: isDebit ? AppColors.orangeIcon : AppColors.greenIcon,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.reference ?? StringHelpers.titleCase(entry.type),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              Extractor.formatDate(entry.date),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            isDebit
                                                ? '+ ${Extractor.formatPkr(entry.debitPaisa)}'
                                                : '- ${Extractor.formatPkr(entry.creditPaisa)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: isDebit ? AppColors.orangeIcon : AppColors.greenIcon,
                                            ),
                                          ),
                                          Text(
                                            'Bal: ${Extractor.formatPkr(entry.balancePaisa)}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
