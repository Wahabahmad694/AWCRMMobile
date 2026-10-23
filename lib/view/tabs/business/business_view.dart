import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/remote/api_service.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/business_repository.dart';
import '../../../core/api/formatters.dart';
import '../../../utils/app_colors.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import 'business_module.dart';
import 'business_editor.dart';
import 'business_detail.dart';

class BusinessView extends StatefulWidget {
  const BusinessView({super.key, required this.module});
  final BusinessModule module;
  @override
  State<BusinessView> createState() => _BusinessViewState();
}

class _BusinessViewState extends State<BusinessView> {
  final repo = BusinessRepository(sl<ApiService>());
  final search = TextEditingController();
  Timer? debounce;
  List<Map<String, dynamic>> rows = [];
  bool loading = true, hasMore = false;
  String? error, status;
  int page = 1, generation = 0, cashTab = 0;
  String date = formatKarachiDate();
  BusinessModule get module => widget.module;
  bool get preview => sl<AuthRepository>().isPreviewMode;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final request = ++generation;
    if (preview) {
      setState(() {
        loading = false;
        rows = [];
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      String path = module.endpoint;
      final query = <String, dynamic>{};
      if (module == BusinessModule.cashBank) {
        path = switch (cashTab) {
          0 => '/payment-accounts/balances',
          1 => '/account-transfers',
          _ => '/payment-accounts/daily-summary',
        };
        if (cashTab == 2) query['date'] = date;
        if (cashTab == 1) query.addAll({'page': page, 'limit': 20});
      } else {
        query.addAll({'page': page, 'limit': 20});
        if (module.searchable && search.text.trim().isNotEmpty) {
          query['search'] = search.text.trim();
        }
        if (status != null) {
          query[module == BusinessModule.leads ? 'source' : 'status'] = status;
        }
      }
      final data = await repo.get(path, query: query);
      final result = BusinessRepository.rows(data);
      if (!mounted || request != generation) return;
      setState(() {
        rows = result;
        final meta = BusinessRepository.record(data);
        hasMore = meta['has_more'] is bool
            ? meta['has_more'] as bool
            : result.length == 20;
        loading = false;
      });
    } catch (e) {
      if (mounted && request == generation) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> create({bool transfer = false}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusinessEditor(module: module, transfer: transfer),
      ),
    );
    if (saved == true && mounted) {
      page = 1;
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = sl<AuthRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: module.title,
        isSignedIn: auth.isSignedIn,
        userInitials: auth.currentUser?.name ?? 'AWC',
      ),
      drawer: AppDrawer(currentRoute: module.route),
      body: RefreshIndicator(
        onRefresh: load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF062B43), Color(0xFF0D547D)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            module.icon,
                            color: const Color(0xFF6CE0CF),
                            size: 30,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            module.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            module.description,
                            style: const TextStyle(
                              color: Color(0xFFC2D8E7),
                              height: 1.5,
                            ),
                          ),
                          if (module.createLabel.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: preview ? null : () => create(),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF075BA7),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(module.createLabel),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (module.searchable)
                      TextField(
                        controller: search,
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Search ${module.title.toLowerCase()}',
                          counterText: '',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) {
                          debounce?.cancel();
                          debounce = Timer(
                            const Duration(milliseconds: 350),
                            () {
                              page = 1;
                              load();
                            },
                          );
                        },
                      ),
                    if (module == BusinessModule.cashBank) ...[
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Accounts')),
                          ButtonSegment(value: 1, label: Text('Transfers')),
                          ButtonSegment(value: 2, label: Text('Daily close')),
                        ],
                        selected: {cashTab},
                        showSelectedIcon: false,
                        onSelectionChanged: (value) {
                          cashTab = value.first;
                          page = 1;
                          load();
                        },
                      ),
                      const SizedBox(height: 12),
                      if (cashTab == 1)
                        OutlinedButton.icon(
                          onPressed: preview
                              ? null
                              : () => create(transfer: true),
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Record transfer'),
                        ),
                      if (cashTab == 2)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(date),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null && mounted) {
                              date = picked.toIso8601String().substring(0, 10);
                              load();
                            }
                          },
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(date),
                        ),
                      if (cashTab == 0 && !loading && error == null && !preview)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total across accounts',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rupees(
                                    rows.fold<int>(
                                      0,
                                      (sum, row) =>
                                          sum +
                                          (int.tryParse(
                                                '${row['balance_paisa']}',
                                              ) ??
                                              0),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    if (module.statuses.isNotEmpty ||
                        module == BusinessModule.leads)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            for (final filter in <String?>[
                              null,
                              ...(module == BusinessModule.leads
                                  ? [
                                      'walk_in',
                                      'referral',
                                      'whatsapp',
                                      'facebook',
                                      'other',
                                    ]
                                  : module.statuses),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    filter == null ? 'All' : humanize(filter),
                                  ),
                                  selected: status == filter,
                                  onSelected: (_) {
                                    status = filter;
                                    page = 1;
                                    load();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (preview || error != null || rows.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        error != null ? Icons.cloud_off_outlined : module.icon,
                        size: 46,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        preview
                            ? 'Explore ${module.title.toLowerCase()}'
                            : error != null
                            ? 'Unable to load records'
                            : 'No records found',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        preview
                            ? 'Sign in to manage your organization’s ${module.title.toLowerCase()}.'
                            : error ??
                                  (module == BusinessModule.creditNotes
                                      ? 'Credit notes are issued when a return is completed with a credit resolution.'
                                      : 'New records will appear here. Try another filter or create your first record.'),
                        textAlign: TextAlign.center,
                      ),
                      if (error != null)
                        TextButton(onPressed: load, child: const Text('Retry')),
                      if (page > 1)
                        TextButton(
                          onPressed: () {
                            page--;
                            load();
                          },
                          child: const Text('Previous page'),
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, index) => _recordCard(rows[index]),
                ),
              ),
            if (!preview &&
                error == null &&
                !loading &&
                rows.isNotEmpty &&
                (module != BusinessModule.cashBank || cashTab == 1))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: page > 1
                            ? () {
                                page--;
                                load();
                              }
                            : null,
                        child: const Text('Previous'),
                      ),
                      Text('Page $page'),
                      OutlinedButton(
                        onPressed: hasMore
                            ? () {
                                page++;
                                load();
                              }
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> row) {
    final title = BusinessRepository.text(
      row,
      [
        'name',
        'number',
        'quotation_number',
        'return_number',
        'credit_note_number',
        'account.name',
        'reference',
      ],
      fallback: module == BusinessModule.cashBank && cashTab == 1
          ? 'Account transfer'
          : module.title,
    );
    final subtitle = BusinessRepository.text(row, [
      'company',
      'customer.name',
      'party.name',
      'lead.name',
      'customer_name',
      'type',
      'transferred_on',
      'created_at',
    ]);
    final amountKeys = module == BusinessModule.leads
        ? ['expected_value_paisa']
        : module == BusinessModule.creditNotes
        ? ['remaining_paisa', 'amount_paisa']
        : ['balance_paisa', 'closing_paisa', 'total_paisa', 'amount_paisa'];
    final amount = int.tryParse(BusinessRepository.text(row, amountKeys));
    final state = BusinessRepository.text(row, [
      'status',
      'stage.name',
      'stage_name',
    ], fallback: '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap:
            row['id'] == null ||
                (module == BusinessModule.cashBank && cashTab != 0)
            ? null
            : () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BusinessDetail(module: module, item: row),
                  ),
                );
                if (mounted) load();
              },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (state.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        humanize(state),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (amount != null) ...[
                const SizedBox(height: 14),
                Text(
                  rupees(amount),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (module == BusinessModule.creditNotes)
                const Text(
                  'Available credit',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              if (module == BusinessModule.leads &&
                  row['next_follow_up_date'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Follow up · ${row['next_follow_up_date']}'),
                ),
              if (module == BusinessModule.cashBank && cashTab == 2) ...[
                const Divider(height: 24),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    for (final field in [
                      'opening_paisa',
                      'in_paisa',
                      'out_paisa',
                    ])
                      Text(
                        '${humanize(field.replaceAll('_paisa', ''))}: ${rupees(int.tryParse('${row[field]}') ?? 0)}',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
