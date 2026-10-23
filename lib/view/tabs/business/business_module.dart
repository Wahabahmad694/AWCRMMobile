import 'package:flutter/material.dart';

enum BusinessModule { leads, quotations, returns, creditNotes, cashBank }

extension BusinessModuleInfo on BusinessModule {
  String get title => switch (this) {
    BusinessModule.leads => 'Leads',
    BusinessModule.quotations => 'Quotations',
    BusinessModule.returns => 'Returns',
    BusinessModule.creditNotes => 'Credit notes',
    BusinessModule.cashBank => 'Cash and bank',
  };
  String get route => switch (this) {
    BusinessModule.creditNotes => '/credit-notes',
    BusinessModule.cashBank => '/cash-bank',
    _ => '/$name',
  };
  String get endpoint =>
      this == BusinessModule.cashBank ? '/payment-accounts' : route;
  String get description => switch (this) {
    BusinessModule.leads =>
      'Build relationships. Keep every opportunity moving.',
    BusinessModule.quotations =>
      'Create clear proposals and turn them into orders.',
    BusinessModule.returns => 'Manage returned items and customer resolutions.',
    BusinessModule.creditNotes =>
      'Track customer credit and apply it to orders.',
    BusinessModule.cashBank =>
      'Your balances and money movements in one place.',
  };
  String get createLabel => switch (this) {
    BusinessModule.leads => 'New lead',
    BusinessModule.quotations => 'New quotation',
    BusinessModule.returns => 'New return',
    BusinessModule.creditNotes => '',
    BusinessModule.cashBank => 'Add account',
  };
  IconData get icon => switch (this) {
    BusinessModule.leads => Icons.people_alt_outlined,
    BusinessModule.quotations => Icons.description_outlined,
    BusinessModule.returns => Icons.assignment_return_outlined,
    BusinessModule.creditNotes => Icons.receipt_long_outlined,
    BusinessModule.cashBank => Icons.account_balance_outlined,
  };
  List<String> get statuses => switch (this) {
    BusinessModule.quotations => [
      'draft',
      'sent',
      'accepted',
      'rejected',
      'converted',
    ],
    BusinessModule.returns => ['draft', 'completed', 'cancelled'],
    BusinessModule.creditNotes => ['open', 'used', 'void'],
    _ => [],
  };
  bool get searchable =>
      this == BusinessModule.leads || this == BusinessModule.quotations;
}

String humanize(String value) => value
    .split('_')
    .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
    .join(' ');
