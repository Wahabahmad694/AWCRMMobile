import 'package:flutter/material.dart';

import '../../../core/api/formatters.dart';
import '../../../data/remote/api_service.dart';
import '../../../di_container.dart';
import '../../../repositories/business_repository.dart';
import 'business_module.dart';
import 'business_editor.dart';

class BusinessDetail extends StatefulWidget {
  const BusinessDetail({super.key, required this.module, required this.item});
  final BusinessModule module;
  final Map<String, dynamic> item;
  @override
  State<BusinessDetail> createState() => _BusinessDetailState();
}

class _BusinessDetailState extends State<BusinessDetail> {
  final repo = BusinessRepository(sl<ApiService>());
  Map<String, dynamic> data = {};
  List<Map<String, dynamic>> transactions = [];
  bool loading = true, more = false;
  String? error;
  int page = 1;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final id = Uri.encodeComponent('${widget.item['id']}');
      if (widget.module == BusinessModule.cashBank) {
        final results = await Future.wait([
          repo.get('/payment-accounts', query: {'include_inactive': 'true'}),
          repo.get(
            '/payment-accounts/$id/book',
            query: {'page': page, 'limit': 20},
          ),
        ]);
        final accounts = BusinessRepository.rows(results[0]);
        final book = BusinessRepository.record(results[1]);
        final account = accounts
            .where((a) => '${a['id']}' == '${widget.item['id']}')
            .firstOrNull;
        data = {...widget.item, ...?account};
        transactions = BusinessRepository.rows(
          book['rows'] ?? book['items'] ?? [],
        );
        more = book['has_more'] is bool
            ? book['has_more'] as bool
            : transactions.length == 20;
      } else {
        data = BusinessRepository.record(
          await repo.get('${widget.module.endpoint}/$id'),
        );
        if (data.isEmpty) {
          throw const BusinessFailure('The server returned an empty record.');
        }
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = '$e';
        });
      }
    }
  }

  Future<void> edit([String? action]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusinessEditor(
          module: widget.module,
          initial: data,
          action: action,
        ),
      ),
    );
    if (changed == true && mounted) await load();
  }

  List<String> get actions {
    final status = data['status'];
    return switch (widget.module) {
      BusinessModule.leads =>
        data['converted_customer_id'] != null || data['converted_at'] != null
            ? []
            : data['archived_at'] != null
            ? ['restore']
            : ['move', 'convert', 'archive'],
      BusinessModule.quotations => [
        if (status == 'draft') 'send',
        if (status == 'sent') ...['accept', 'reject'],
        if (status == 'accepted') 'convert',
        'duplicate',
      ],
      BusinessModule.returns => status == 'draft' ? ['complete', 'cancel'] : [],
      BusinessModule.creditNotes =>
        status == 'open'
            ? [
                'apply',
                if (data['applications'] is List &&
                    (data['applications'] as List).isEmpty)
                  'void',
              ]
            : [],
      BusinessModule.cashBank => [
        (data['active'] == false ||
                data['is_active'] == false ||
                status == 'inactive')
            ? 'activate'
            : 'deactivate',
      ],
    };
  }

  bool get editable => switch (widget.module) {
    BusinessModule.leads =>
      data['archived_at'] == null &&
          data['converted_customer_id'] == null &&
          data['converted_at'] == null,
    BusinessModule.quotations => data['status'] == 'draft',
    BusinessModule.cashBank => true,
    _ => false,
  };

  String money(dynamic value) {
    final n = int.tryParse('$value');
    return n == null ? '—' : rupees(n);
  }

  Widget section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.module.title)),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!, textAlign: TextAlign.center),
                  TextButton(onPressed: load, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  BusinessRepository.text(data, [
                    'name',
                    'number',
                    'quotation_number',
                    'return_number',
                    'credit_note_number',
                  ], fallback: widget.module.title),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  humanize(
                    BusinessRepository.text(data, [
                      'status',
                      'stage.name',
                      'type',
                    ], fallback: ''),
                  ),
                  style: const TextStyle(color: Color(0xFF0878C9)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (editable)
                      FilledButton.icon(
                        onPressed: () => edit(),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    for (final action in actions)
                      OutlinedButton(
                        onPressed: () => edit(action),
                        child: Text(humanize(action)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                section('Overview', [
                  for (final field in <String, String>{
                    'company': 'Company',
                    'phone': 'Phone',
                    'email': 'Email',
                    'source': 'Source',
                    'customer.name': 'Customer',
                    'lead.name': 'Lead',
                    'customer_name': 'Customer',
                    'order.number': 'Order',
                    'order_number': 'Order',
                    'next_follow_up_date': 'Next follow-up',
                    'issue_date': 'Issued',
                    'valid_until': 'Valid until',
                    'reason': 'Reason',
                    'resolution': 'Resolution',
                    'account_number_masked': 'Account number',
                    'opening_balance_date': 'Opening balance date',
                    'created_at': 'Created',
                  }.entries)
                    if (BusinessRepository.text(data, [field.key]) != '—')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                field.value,
                                style: const TextStyle(color: Colors.blueGrey),
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                BusinessRepository.text(data, [field.key]),
                              ),
                            ),
                          ],
                        ),
                      ),
                  for (final field in <String, String>{
                    'expected_value_paisa': 'Expected value',
                    'total_paisa': 'Total',
                    'amount_paisa': 'Amount',
                    'remaining_paisa': 'Remaining credit',
                    'balance_paisa': 'Balance',
                    'opening_balance_paisa': 'Opening balance',
                    'discount_paisa': 'Discount',
                    'tax_paisa': 'Tax',
                  }.entries)
                    if (data[field.key] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(field.value)),
                            Text(
                              money(data[field.key]),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                ]),
                if (data['lines'] is List)
                  section('Items', [
                    for (final line in (data['lines'] as List).whereType<Map>())
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          BusinessRepository.text(
                            Map<String, dynamic>.from(line),
                            ['description', 'product.name'],
                          ),
                        ),
                        subtitle: Text('Quantity: ${line['quantity'] ?? '—'}'),
                        trailing: Text(
                          money(
                            line['line_total_paisa'] ??
                                line['total_paisa'] ??
                                line['unit_price_paisa'],
                          ),
                        ),
                      ),
                  ]),
                if (data['applications'] is List)
                  section('Credit applications', [
                    if ((data['applications'] as List).isEmpty)
                      const Text('No credit applied yet.'),
                    for (final row
                        in (data['applications'] as List).whereType<Map>())
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          BusinessRepository.text(
                            Map<String, dynamic>.from(row),
                            ['order.number', 'order_number'],
                          ),
                        ),
                        subtitle: Text('${row['created_at'] ?? ''}'),
                        trailing: Text(money(row['amount_paisa'])),
                      ),
                  ]),
                for (final key in ['notes', 'terms', 'reason_note'])
                  if (data[key] != null && '${data[key]}'.isNotEmpty)
                    section(humanize(key), [SelectableText('${data[key]}')]),
                if (widget.module == BusinessModule.cashBank)
                  section('Account book', [
                    if (transactions.isEmpty)
                      const Text('No transactions on this page.'),
                    for (final row in transactions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              BusinessRepository.text(row, [
                                'reference',
                                'kind',
                              ]),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${row['date'] ?? ''}',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 18,
                              runSpacing: 6,
                              children: [
                                Text('In ${money(row['in_paisa'])}'),
                                Text('Out ${money(row['out_paisa'])}'),
                                Text('Balance ${money(row['balance_paisa'])}'),
                              ],
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: page > 1
                              ? () {
                                  page--;
                                  load();
                                }
                              : null,
                          child: const Text('Previous'),
                        ),
                        Text('Page $page'),
                        TextButton(
                          onPressed: more
                              ? () {
                                  page++;
                                  load();
                                }
                              : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ]),
              ],
            ),
          ),
  );
}
