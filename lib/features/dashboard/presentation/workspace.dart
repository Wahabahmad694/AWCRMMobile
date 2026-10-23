import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/session.dart';
import '../../../app/theme/app_theme.dart';
import '../../account/presentation/account_page.dart';
import '../../ai_assistant/presentation/assistant_page.dart';
import 'live_dashboard.dart';
import 'records_list.dart';

// Navigation only exposes screens that have a real data path or an explicit unavailable state.
enum WorkspaceSection { dashboard, leads, quotations, returns, customers, orders, payments, creditNotes, cashAndBank, assistant, account }

extension SectionInfo on WorkspaceSection {
  String get title => switch (this) {
    WorkspaceSection.dashboard => 'Overview',
    WorkspaceSection.leads => 'Leads',
    WorkspaceSection.quotations => 'Quotations',
    WorkspaceSection.returns => 'Returns',
    WorkspaceSection.assistant => 'AI assistant',
    WorkspaceSection.customers => 'Customers',
    WorkspaceSection.orders => 'Orders',
    WorkspaceSection.payments => 'Payments',
    WorkspaceSection.creditNotes => 'Credit notes',
    WorkspaceSection.cashAndBank => 'Cash and bank',
    WorkspaceSection.account => 'Account',
  };
  String get path => switch (this) {
    WorkspaceSection.creditNotes => '/credit-notes',
    WorkspaceSection.cashAndBank => '/cash-and-bank',
    _ => '/$name',
  };
  IconData get icon => switch (this) {
    WorkspaceSection.dashboard => Icons.dashboard_outlined,
    WorkspaceSection.leads => Icons.view_kanban_outlined,
    WorkspaceSection.quotations => Icons.description_outlined,
    WorkspaceSection.returns => Icons.keyboard_return_outlined,
    WorkspaceSection.assistant => Icons.auto_awesome_outlined,
    WorkspaceSection.customers => Icons.people_outline,
    WorkspaceSection.orders => Icons.receipt_long_outlined,
    WorkspaceSection.payments => Icons.account_balance_wallet_outlined,
    WorkspaceSection.creditNotes => Icons.note_outlined,
    WorkspaceSection.cashAndBank => Icons.account_balance_outlined,
    WorkspaceSection.account => Icons.person_outline,
  };
}

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key, required this.section});
  final WorkspaceSection section;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < AppTokens.mobile;
    final desktop = width >= AppTokens.desktop;
    final preview = context.watch<Session>().previewMode;
    final session = context.watch<Session>();
    final nav = WorkspaceSection.values;
    return Scaffold(
      appBar: AppBar(
        leading: desktop ? null : Builder(builder: (context) => IconButton(
          tooltip: 'Open navigation', icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        title: Row(children: [
          if (!mobile) const Icon(Icons.business_center_rounded, size: 24),
          if (!mobile) const SizedBox(width: 12),
          Text(section.title),
        ]),
        actions: [
          if (!preview && session.memberships.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Switch organization',
              onSelected: session.switchOrganization,
              itemBuilder: (_) => [
                for (final membership in session.memberships)
                  PopupMenuItem(value: membership.organizationId,
                    child: Row(children: [
                      if (membership.organizationId == session.organizationId)
                        const Icon(Icons.check, size: 18),
                      if (membership.organizationId == session.organizationId)
                        const SizedBox(width: 8),
                      Text(membership.name),
                    ])),
              ],
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text(session.currentMembership?.name ?? 'Organization'))),
            ),
          if (preview) const Center(child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Chip(label: Text('Preview mode')),
          )),
          IconButton(
            tooltip: 'Account & Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go('/account'),
          ),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: () async {
            final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
              title: Text(preview ? 'Leave preview?' : 'Sign out?'),
              content: Text(preview
                  ? 'You can enter preview mode again from the sign-in screen.'
                  : 'You will need to sign in again to access your workspace.'),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(preview ? 'Leave preview' : 'Sign out'))],
            ));
            if (confirm == true && context.mounted) await context.read<Session>().signOut();
          }),
          const SizedBox(width: 8),
        ],
      ),
      drawer: desktop ? null : Drawer(child: _navList(context, nav)),
      bottomNavigationBar: mobile ? NavigationBar(
        selectedIndex: ![WorkspaceSection.dashboard, WorkspaceSection.leads, WorkspaceSection.orders, WorkspaceSection.account].contains(section)
            ? 0 : [WorkspaceSection.dashboard, WorkspaceSection.leads, WorkspaceSection.orders, WorkspaceSection.account].indexOf(section),
        onDestinationSelected: (index) => context.go([WorkspaceSection.dashboard, WorkspaceSection.leads, WorkspaceSection.orders, WorkspaceSection.account][index].path),
        destinations: [for (final item in [WorkspaceSection.dashboard, WorkspaceSection.leads, WorkspaceSection.orders, WorkspaceSection.account]) NavigationDestination(icon: Icon(item.icon), label: item.title)],
      ) : null,
      body: Column(
        children: [
          if (session.readOnly)
            Container(
              color: Colors.amber.shade800,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your subscription is read-only. Contact your organization owner.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(children: [
              if (desktop) SizedBox(width: 240, child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: _navList(context, nav),
              )),
              Expanded(child: switch (section) {
                WorkspaceSection.dashboard => const LiveDashboard(),
                WorkspaceSection.leads => const RecordsList(resource: 'leads', title: 'Leads'),
                WorkspaceSection.quotations => const RecordsList(resource: 'quotations', title: 'Quotations'),
                WorkspaceSection.returns => const RecordsList(resource: 'returns', title: 'Returns'),
                WorkspaceSection.assistant => const AssistantPage(),
                WorkspaceSection.customers => const RecordsList(resource: 'customers', title: 'Customers'),
                WorkspaceSection.orders => const RecordsList(resource: 'orders', title: 'Orders'),
                WorkspaceSection.payments => const RecordsList(resource: 'payments', title: 'Payments'),
                WorkspaceSection.creditNotes => const RecordsList(resource: 'credit-notes', title: 'Credit notes'),
                WorkspaceSection.cashAndBank => const RecordsList(resource: 'payment-accounts', title: 'Cash and bank'),
                WorkspaceSection.account => const AccountPage(),
              }),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _navList(BuildContext context, List<WorkspaceSection> nav) => SafeArea(
    child: ListView(padding: const EdgeInsets.all(16), children: [
      const ListTile(title: Text('AWC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20))),
      const SizedBox(height: 16),
      for (final item in nav) Padding(padding: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          leading: Icon(item.icon), title: Text(item.title),
          selected: section == item,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () => context.go(item.path),
        )),
    ]),
  );
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    Text('Business overview', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Your live business data will appear here when the dashboard API is connected.'),
    const SizedBox(height: 24),
    LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 500 ? 2 : 1;
      final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(spacing: 16, runSpacing: 16, children: [
        for (final label in ['Total sales', 'Orders', 'Payments collected', 'Outstanding receivables'])
          SizedBox(width: cardWidth, child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(label, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 20),
              const Text('No live data', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4), const Text('Connect dashboard API')],
          )))),
      ]);
    }),
    const SizedBox(height: 24),
    Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('AI business briefing', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12), const Text('Ask the assistant about verified business records.'),
        const SizedBox(height: 12), Align(alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(onPressed: () => context.go('/assistant'),
            icon: const Icon(Icons.auto_awesome), label: const Text('Open assistant')))],
    ))),
  ]);
}

