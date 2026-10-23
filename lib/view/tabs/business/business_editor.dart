import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/api/formatters.dart';
import '../../../data/remote/api_service.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/business_repository.dart';
import 'business_module.dart';

class BusinessEditor extends StatefulWidget {
  const BusinessEditor({
    super.key,
    required this.module,
    this.initial,
    this.action,
    this.transfer = false,
  });
  final BusinessModule module;
  final Map<String, dynamic>? initial;
  final String? action;
  final bool transfer;
  @override
  State<BusinessEditor> createState() => _BusinessEditorState();
}

class _BusinessEditorState extends State<BusinessEditor> {
  final form = GlobalKey<FormState>();
  final repo = BusinessRepository(sl<ApiService>());
  final fields = <String, TextEditingController>{};
  final values = <String, dynamic>{};
  final labels = <String, String>{};
  final lines = <_QuoteLine>[];
  final returnQuantities = <String, TextEditingController>{};
  List<Map<String, dynamic>> returnable = [];
  bool saving = false, loadingLines = false;
  String? error, lastPayload, idempotencyKey;
  String partyType = 'customer';
  int orderRequest = 0;
  Map<String, dynamic> get original => widget.initial ?? {};
  bool get editing => widget.initial != null && widget.action == null;
  bool get isAction => widget.action != null;
  String get title => widget.transfer
      ? 'Record transfer'
      : isAction
      ? humanize(widget.action!)
      : editing
      ? 'Edit ${widget.module.title.toLowerCase()}'
      : widget.module.createLabel;

  @override
  void initState() {
    super.initState();
    values.addAll(original);
    if (original['lead_id'] != null) partyType = 'lead';
    for (final key in ['customer', 'lead']) {
      final data = BusinessRepository.record(
        original[key] ?? original['party'],
      );
      if (original['${key}_id'] != null) {
        labels['${key}_id'] = '${data['name'] ?? 'Selected $key'}';
      }
    }
    if (widget.module == BusinessModule.quotations && !isAction) {
      final existing = original['lines'];
      if (existing is List) {
        for (final line in existing.whereType<Map>()) {
          lines.add(
            _QuoteLine(
              description: '${line['description'] ?? ''}',
              quantity: '${line['quantity'] ?? '1'}',
              price: _decimal(line['unit_price_paisa']),
              productId: line['product_id']?.toString(),
            ),
          );
        }
      }
      if (lines.isEmpty) lines.add(_QuoteLine());
    }
  }

  String _decimal(dynamic paisa) =>
      ((int.tryParse('$paisa') ?? 0) / 100).toStringAsFixed(2);
  TextEditingController controller(String key, {String? initial}) =>
      fields.putIfAbsent(
        key,
        () => TextEditingController(
          text:
              initial ??
              (key.endsWith('_paisa')
                  ? _decimal(original[key])
                  : '${original[key] ?? ''}'),
        ),
      );

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    for (final line in lines) {
      line.dispose();
    }
    for (final c in returnQuantities.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
    String key,
    String label, {
    bool required = false,
    bool money = false,
    bool signed = false,
    int maxLength = 200,
    int minLength = 0,
    int maxLines = 1,
    String? initial,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller(key, initial: initial),
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: money
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : key == 'email'
          ? TextInputType.emailAddress
          : key == 'phone'
          ? TextInputType.phone
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        prefixText: money ? 'Rs ' : null,
        counterText: '',
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'Enter $label';
        if (text.isEmpty) return null;
        if (text.length < minLength) {
          return 'Use at least $minLength characters';
        }
        if (money && _parseMoney(text, signed: signed) == null) {
          return 'Enter a valid amount with up to two decimals';
        }
        if (money &&
            (_parseMoney(text, signed: signed)!.abs() > 100000000000000)) {
          return 'Amount is too large';
        }
        if (key == 'email' &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return 'Enter a valid email';
        }
        return null;
      },
    ),
  );

  int? _parseMoney(String text, {bool signed = false}) {
    if (signed && text.startsWith('-')) {
      final n = parsePaisa(text.substring(1));
      return n == null ? null : -n;
    }
    return parsePaisa(text);
  }

  Widget choice(
    String key,
    String label,
    List<String> options,
    String fallback,
  ) {
    values.putIfAbsent(key, () => fallback);
    if (!options.contains(values[key])) values[key] = fallback;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: values[key] as String,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(humanize(option))),
        ],
        onChanged: (v) => setState(() => values[key] = v),
      ),
    );
  }

  Widget dateField(
    String key,
    String label, {
    bool required = false,
    bool today = false,
  }) {
    final c = controller(
      key,
      initial:
          original[key]?.toString().split('T').first ??
          (today ? formatKarachiDate() : ''),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        readOnly: true,
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        validator: (_) => required && c.text.isEmpty ? 'Choose $label' : null,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) c.text = date.toIso8601String().substring(0, 10);
        },
      ),
    );
  }

  Widget lookup(
    String key,
    String label,
    String endpoint, {
    bool required = true,
    bool paginated = true,
    Map<String, dynamic>? query,
    Future<void> Function(Map<String, dynamic>)? selected,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: FormField<String>(
      key: ValueKey('$key-${values[key]}'),
      initialValue: values[key]?.toString(),
      validator: (v) =>
          required && (v == null || v.isEmpty) ? 'Choose $label' : null,
      builder: (state) => InkWell(
        onTap: saving
            ? null
            : () async {
                final item = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => _RecordPicker(
                    title: label,
                    endpoint: endpoint,
                    paginated: paginated,
                    query: query,
                  ),
                );
                if (item == null || !mounted) return;
                setState(() {
                  values[key] = item['id'];
                  labels[key] = BusinessRepository.text(item, [
                    'name',
                    'number',
                    'order_number',
                    'description',
                  ]);
                  state.didChange(item['id']?.toString());
                });
                await selected?.call(item);
              },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: '$label${required ? ' *' : ''}',
            errorText: state.errorText,
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: Text(
            labels[key] ??
                (values[key] != null ? 'Selected $label' : 'Choose $label'),
            maxLines: 2,
          ),
        ),
      ),
    ),
  );

  Future<void> loadReturnable(Map<String, dynamic> order) async {
    final request = ++orderRequest;
    setState(() {
      loadingLines = true;
      error = null;
      returnable = [];
    });
    for (final c in returnQuantities.values) {
      c.dispose();
    }
    returnQuantities.clear();
    try {
      final data = await repo.get(
        '/orders/${Uri.encodeComponent('${order['id']}')}/returnable',
      );
      final map = BusinessRepository.record(data);
      final items = BusinessRepository.rows(
        map['lines'] ?? map['items'] ?? data,
      );
      if (!mounted || request != orderRequest) return;
      setState(() {
        returnable = items
            .where(
              (line) =>
                  (num.tryParse('${line['returnable_quantity']}') ?? 0) > 0,
            )
            .toList();
        for (final line in returnable) {
          returnQuantities[_returnLineId(line)] = TextEditingController(
            text: '0',
          );
        }
        loadingLines = false;
      });
    } catch (e) {
      if (mounted && request == orderRequest) {
        setState(() {
          error = e.toString();
          loadingLines = false;
        });
      }
    }
  }

  String _returnLineId(Map<String, dynamic> line) =>
      '${line['order_line_id'] ?? line['order_item_id'] ?? line['id']}';

  List<Widget> fieldsForForm() {
    if (widget.transfer) {
      return [
        lookup(
          'from_account_id',
          'From account',
          '/payment-accounts',
          paginated: false,
        ),
        lookup(
          'to_account_id',
          'To account',
          '/payment-accounts',
          paginated: false,
        ),
        field('amount_paisa', 'Amount', required: true, money: true),
        dateField(
          'transferred_on',
          'Transfer date',
          required: true,
          today: true,
        ),
        field('note', 'Note', maxLength: 300, maxLines: 3),
      ];
    }
    if (isAction) {
      if (widget.action == 'move') {
        return [
          lookup(
            'stage_id',
            'Pipeline stage',
            '/pipeline/stages',
            paginated: false,
          ),
          field(
            'lost_reason',
            'Reason (required for a lost stage)',
            maxLength: 300,
          ),
        ];
      }
      if (widget.action == 'apply') {
        return [
          lookup(
            'order_id',
            'Customer order',
            '/orders',
            query: {'customer_id': original['customer_id']},
          ),
          field('amount_paisa', 'Credit amount', required: true, money: true),
          Text(
            'Available credit: ${rupees(int.tryParse('${original['remaining_paisa']}') ?? 0)}',
          ),
        ];
      }
      if (widget.action == 'void') {
        return [
          field(
            'reason',
            'Reason',
            required: true,
            minLength: 3,
            maxLength: 300,
            maxLines: 3,
          ),
        ];
      }
      if (widget.action == 'reject') {
        return [field('reason', 'Reason', maxLength: 500, maxLines: 3)];
      }
      if (widget.action == 'complete') {
        return [
          if (original['resolution'] == 'refund') ...[
            choice('method', 'Refund method', [
              'cash',
              'bank_transfer',
              'easypaisa',
              'jazzcash',
              'mobile_wallet',
              'cheque',
              'other',
            ], 'cash'),
            lookup(
              'payment_account_id',
              'Refund account',
              '/payment-accounts',
              required: false,
              paginated: false,
            ),
          ] else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Apply credit to the original order'),
              value: values['auto_apply'] != false,
              onChanged: (v) => setState(() => values['auto_apply'] = v),
            ),
          const Text(
            'Completing this return updates stock and records the customer’s credit or refund.',
          ),
        ];
      }
      return [
        Text(switch (widget.action) {
          'convert' =>
            widget.module == BusinessModule.leads
                ? 'Create a customer from this lead.'
                : 'Create an order from this accepted quotation.',
          'send' => 'Mark this quotation as sent to the customer.',
          'cancel' => 'Cancel this draft return.',
          'duplicate' => 'Create a new draft copy of this quotation.',
          _ => '${humanize(widget.action!)} this record?',
        }),
      ];
    }
    switch (widget.module) {
      case BusinessModule.leads:
        return [
          field('name', 'Name', required: true),
          field('company', 'Company'),
          field('phone', 'Phone', maxLength: 40),
          field('email', 'Email', maxLength: 254),
          choice('source', 'Source', [
            'walk_in',
            'referral',
            'whatsapp',
            'facebook',
            'other',
          ], 'other'),
          if (!editing)
            lookup(
              'stage_id',
              'Pipeline stage',
              '/pipeline/stages',
              required: false,
              paginated: false,
            ),
          field('expected_value_paisa', 'Expected value', money: true),
          dateField('next_follow_up_date', 'Next follow-up'),
          field('notes', 'Notes', maxLength: 2000, maxLines: 3),
        ];
      case BusinessModule.quotations:
        return [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'customer', label: Text('Customer')),
              ButtonSegment(value: 'lead', label: Text('Lead')),
            ],
            selected: {partyType},
            onSelectionChanged: (v) => setState(() => partyType = v.first),
          ),
          const SizedBox(height: 16),
          lookup(
            '${partyType}_id',
            humanize(partyType),
            partyType == 'customer' ? '/customers' : '/leads',
          ),
          dateField('issue_date', 'Issue date', required: true, today: true),
          dateField('valid_until', 'Valid until', required: true),
          const Text(
            'Quotation items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lines.length; i++) _quoteLine(i),
          OutlinedButton.icon(
            onPressed: lines.length >= 200
                ? null
                : () => setState(() => lines.add(_QuoteLine())),
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
          const SizedBox(height: 20),
          field('discount_paisa', 'Discount', money: true),
          field('tax_paisa', 'Tax', money: true),
          field('notes', 'Notes', maxLength: 1000, maxLines: 3),
          field('terms', 'Terms', maxLength: 2000, maxLines: 3),
        ];
      case BusinessModule.returns:
        return [
          lookup(
            'order_id',
            'Fulfilled order',
            '/orders',
            query: {'status': 'fulfilled'},
            selected: loadReturnable,
          ),
          if (loadingLines) const LinearProgressIndicator(),
          if (!loadingLines && values['order_id'] != null && returnable.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('No returnable items found for this order.'),
            ),
          for (final line in returnable)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: returnQuantities[_returnLineId(line)],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: BusinessRepository.text(line, [
                    'description',
                    'product.name',
                  ]),
                  helperText:
                      'Up to ${line['returnable_quantity']} available to return',
                ),
                validator: (text) {
                  final n = num.tryParse(text ?? '');
                  final max =
                      num.tryParse('${line['returnable_quantity']}') ?? 0;
                  return n == null || !n.isFinite || n < 0 || n > max
                      ? 'Enter a quantity between 0 and $max'
                      : null;
                },
              ),
            ),
          choice('reason', 'Reason', [
            'damaged',
            'wrong_item',
            'quality',
            'customer_changed_mind',
            'other',
          ], 'damaged'),
          field('reason_note', 'Reason note', maxLength: 300, maxLines: 3),
          choice('resolution', 'Resolution', [
            'credit_note',
            'refund',
          ], 'credit_note'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Return items to stock'),
            value: values['restock'] != false,
            onChanged: (v) => setState(() => values['restock'] = v),
          ),
        ];
      case BusinessModule.cashBank:
        return [
          field('name', 'Account name', required: true, maxLength: 80),
          if (!editing)
            choice('type', 'Account type', [
              'cash',
              'bank',
              'easypaisa',
              'jazzcash',
              'other',
            ], 'cash'),
          field(
            'account_number_masked',
            'Masked account number',
            maxLength: 40,
            required:
                (values['type'] ?? original['type']) != 'cash' &&
                (values['type'] ?? original['type']) != 'other',
          ),
          if (!editing) ...[
            field(
              'opening_balance_paisa',
              'Opening balance',
              money: true,
              signed: true,
            ),
            dateField(
              'opening_balance_date',
              'Opening balance date',
              required: true,
              today: true,
            ),
          ],
        ];
      case BusinessModule.creditNotes:
        return [];
    }
  }

  Widget _quoteLine(int index) {
    final line = lines[index];
    return Card(
      key: ObjectKey(line),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final product = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (_) => const _RecordPicker(
                        title: 'Product',
                        endpoint: '/products',
                      ),
                    );
                    if (product != null && mounted) {
                      setState(() {
                        line.productId = product['id']?.toString();
                        line.description.text = '${product['name'] ?? ''}';
                        line.price.text = _decimal(
                          product['selling_price_paisa'] ??
                              product['price_paisa'] ??
                              product['unit_price_paisa'],
                        );
                      });
                    }
                  },
                  child: const Text('Product'),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: lines.length <= 1
                      ? null
                      : () => setState(() {
                          lines.removeAt(index);
                          line.dispose();
                        }),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            TextFormField(
              controller: line.description,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Description',
                counterText: '',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty && line.productId == null
                  ? 'Enter a description or choose a product'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (v) {
                      final n = num.tryParse(v ?? '');
                      return n == null || !n.isFinite || n <= 0
                          ? 'Enter a positive quantity'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Unit price (PKR)',
                    ),
                    validator: (v) =>
                        parsePaisa(v ?? '') == null ||
                            parsePaisa(v ?? '')! > 100000000000000
                        ? 'Invalid price'
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> payload() {
    final body = <String, dynamic>{};
    void addText(List<String> keys) {
      for (final key in keys) {
        final text = fields[key]?.text.trim() ?? '';
        if (text.isNotEmpty) body[key] = text;
      }
    }

    void money(String key, {bool signed = false}) {
      final text = fields[key]?.text.trim() ?? '';
      if (text.isNotEmpty) body[key] = _parseMoney(text, signed: signed);
    }

    void version() {
      final v = int.tryParse('${original['version']}');
      if (v == null || v < 1) {
        throw const BusinessFailure(
          'This record has no version. Reload it before making changes.',
        );
      }
      body['expected_version'] = v;
    }

    if (widget.transfer) {
      if (values['from_account_id'] == values['to_account_id']) {
        throw const BusinessFailure('Choose two different accounts.');
      }
      body.addAll({
        'from_account_id': values['from_account_id'],
        'to_account_id': values['to_account_id'],
      });
      money('amount_paisa');
      addText(['transferred_on', 'note']);
      if ((body['amount_paisa'] as int? ?? 0) <= 0) {
        throw const BusinessFailure('Enter an amount greater than zero.');
      }
      return body;
    }
    if (isAction) {
      if ([
        'move',
        'convert',
        'send',
        'accept',
        'reject',
        'complete',
        'cancel',
      ].contains(widget.action)) {
        version();
      }
      if (widget.action == 'move') {
        body['stage_id'] = values['stage_id'];
        addText(['lost_reason']);
      }
      if (widget.action == 'reject' || widget.action == 'void') {
        addText(['reason']);
      }
      if (widget.action == 'apply') {
        body['order_id'] = values['order_id'];
        money('amount_paisa');
        final amount = body['amount_paisa'] as int? ?? 0;
        final available = int.tryParse('${original['remaining_paisa']}');
        if (amount <= 0 || (available != null && amount > available)) {
          throw const BusinessFailure(
            'Enter an amount within the available credit.',
          );
        }
      }
      if (widget.action == 'complete') {
        if (original['resolution'] == 'refund') {
          body['refund'] = {
            'method': values['method'],
            if (values['payment_account_id'] != null)
              'payment_account_id': values['payment_account_id'],
          };
        } else {
          body['auto_apply'] = values['auto_apply'] != false;
        }
      }
      return body;
    }
    if (editing) version();
    switch (widget.module) {
      case BusinessModule.leads:
        addText([
          'name',
          'company',
          'phone',
          'email',
          'notes',
          'next_follow_up_date',
        ]);
        body['source'] = values['source'];
        money('expected_value_paisa');
        if (!editing && values['stage_id'] != null) {
          body['stage_id'] = values['stage_id'];
        }
      case BusinessModule.quotations:
        body['${partyType}_id'] = values['${partyType}_id'];
        addText(['issue_date', 'valid_until', 'notes', 'terms']);
        if (body['valid_until'].toString().compareTo(
              body['issue_date'].toString(),
            ) <
            0) {
          throw const BusinessFailure(
            'Valid until must be on or after the issue date.',
          );
        }
        body['lines'] = [
          for (final line in lines)
            {
              if (line.productId != null) 'product_id': line.productId,
              'description': line.description.text.trim(),
              'quantity': line.quantity.text.trim(),
              'unit_price_paisa': parsePaisa(line.price.text),
            },
        ];
        money('discount_paisa');
        money('tax_paisa');
      case BusinessModule.returns:
        final selected = [
          for (final line in returnable)
            if ((num.tryParse(returnQuantities[_returnLineId(line)]!.text) ??
                    0) >
                0)
              {
                'order_line_id': _returnLineId(line),
                'quantity': returnQuantities[_returnLineId(line)]!.text.trim(),
              },
        ];
        if (selected.isEmpty) {
          throw const BusinessFailure('Select at least one item to return.');
        }
        body.addAll({
          'order_id': values['order_id'],
          'lines': selected,
          'reason': values['reason'],
          'restock': values['restock'] != false,
          'resolution': values['resolution'],
        });
        addText(['reason_note']);
      case BusinessModule.cashBank:
        addText(['name', 'account_number_masked']);
        if (!editing) {
          body['type'] = values['type'];
          money('opening_balance_paisa', signed: true);
          addText(['opening_balance_date']);
        }
      case BusinessModule.creditNotes:
        break;
    }
    return body;
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || saving) return;
    if (sl<AuthRepository>().isPreviewMode) return;
    try {
      final body = payload();
      final encoded = jsonEncode(body);
      if (lastPayload != encoded) {
        idempotencyKey = generateIdempotencyKey();
        lastPayload = encoded;
      }
      setState(() {
        saving = true;
        error = null;
      });
      var path = widget.transfer
          ? '/account-transfers'
          : widget.module.endpoint;
      if (editing || isAction) {
        path += '/${Uri.encodeComponent('${original['id']}')}';
      }
      if (isAction) path += '/${widget.action}';
      await repo.save(
        path,
        body,
        patch: editing,
        idempotencyKey: idempotencyKey!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: form,
            child: AbsorbPointer(
              absorbing: saving,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(22),
                children: [
                  ...fieldsForForm(),
                  const SizedBox(height: 16),
                  if (error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Color(0xFFAB2530)),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: saving || loadingLines ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      saving
                          ? 'Saving…'
                          : isAction
                          ? 'Confirm ${humanize(widget.action!).toLowerCase()}'
                          : 'Save',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuoteLine {
  _QuoteLine({
    String description = '',
    String quantity = '1',
    String price = '',
    this.productId,
  }) : description = TextEditingController(text: description),
       quantity = TextEditingController(text: quantity),
       price = TextEditingController(text: price);
  final TextEditingController description, quantity, price;
  String? productId;
  void dispose() {
    description.dispose();
    quantity.dispose();
    price.dispose();
  }
}

class _RecordPicker extends StatefulWidget {
  const _RecordPicker({
    required this.title,
    required this.endpoint,
    this.paginated = true,
    this.query,
  });
  final String title, endpoint;
  final bool paginated;
  final Map<String, dynamic>? query;
  @override
  State<_RecordPicker> createState() => _RecordPickerState();
}

class _RecordPickerState extends State<_RecordPicker> {
  final search = TextEditingController();
  final repo = BusinessRepository(sl<ApiService>());
  List<Map<String, dynamic>> rows = [];
  bool loading = true, more = false;
  String? error;
  int page = 1, request = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final current = ++request;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await repo.get(
        widget.endpoint,
        query: {
          ...?widget.query,
          if (widget.paginated) 'page': page,
          if (widget.paginated) 'limit': 20,
          if (widget.paginated && search.text.trim().isNotEmpty)
            'search': search.text.trim(),
        },
      );
      final list = BusinessRepository.rows(result);
      if (mounted && current == request) {
        setState(() {
          rows = list;
          more = list.length == 20;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted && current == request) {
        setState(() {
          error = '$e';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Choose ${widget.title.toLowerCase()}'),
    content: SizedBox(
      width: 440,
      height: 400,
      child: Column(
        children: [
          if (widget.paginated)
            TextField(
              controller: search,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'Search',
                counterText: '',
                suffixIcon: IconButton(
                  onPressed: () {
                    page = 1;
                    load();
                  },
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) {
                page = 1;
                load();
              },
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error!),
                        TextButton(onPressed: load, child: const Text('Retry')),
                      ],
                    ),
                  )
                : rows.isEmpty
                ? const Center(child: Text('No matching records'))
                : ListView(
                    children: [
                      for (final row in rows)
                        ListTile(
                          title: Text(
                            BusinessRepository.text(row, [
                              'name',
                              'number',
                              'order_number',
                              'description',
                            ]),
                          ),
                          subtitle: Text(
                            BusinessRepository.text(row, [
                              'company',
                              'phone',
                              'type',
                              'status',
                            ], fallback: ''),
                          ),
                          onTap: row['id'] == null
                              ? null
                              : () => Navigator.pop(context, row),
                        ),
                    ],
                  ),
          ),
          if (widget.paginated)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: !loading && page > 1
                      ? () {
                          page--;
                          load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $page'),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: !loading && more
                      ? () {
                          page++;
                          load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}
