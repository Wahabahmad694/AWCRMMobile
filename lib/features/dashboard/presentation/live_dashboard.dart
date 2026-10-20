import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/formatters.dart';
import '../../../core/auth/session.dart';

class LiveDashboard extends StatefulWidget {
  const LiveDashboard({super.key});
  @override
  State<LiveDashboard> createState() => _LiveDashboardState();
}

class _LiveDashboardState extends State<LiveDashboard> {
  Future<Map<String, dynamic>>? future;
  String? currentOrg;

  void load() {
    setState(() {
      future = () async {
        final response = await GetIt.I<ApiClient>().get('/dashboard/summary');
        final data = response.data;
        if (data is! Map) throw const ApiFailure('The dashboard returned invalid data.');
        return data.map((key, value) => MapEntry(key.toString(), value));
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    if (session.previewMode) return _content(context, null, preview: true);
    if (currentOrg != session.organizationId || future == null) {
      currentOrg = session.organizationId;
      future = () async {
        final response = await GetIt.I<ApiClient>().get('/dashboard/summary');
        final data = response.data;
        if (data is! Map) throw const ApiFailure('The dashboard returned invalid data.');
        return data.map((key, value) => MapEntry(key.toString(), value));
      }();
    }
    return FutureBuilder<Map<String, dynamic>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(snapshot.error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: load, child: const Text('Retry')),
          ],
        )));
      }
      return RefreshIndicator(onRefresh: () async { load(); await future; },
        child: _content(context, snapshot.data));
    });
  }

  Widget _content(BuildContext context, Map<String, dynamic>? data, {bool preview = false}) {
    const metrics = <(String, String)>[
      ('total_sales_paisa', 'Total sales'),
      ('total_orders', 'Orders'),
      ('payments_collected_paisa', 'Payments collected'),
      ('outstanding_receivables_paisa', 'Outstanding receivables'),
      ('active_customers', 'Active customers'),
      ('pending_follow_ups', 'Pending follow-ups'),
    ];
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('Business overview', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(preview ? 'Preview mode — live business data is hidden.' : 'Figures are provided by your organization’s API.'),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 500 ? 2 : 1;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (final metric in metrics)
            SizedBox(width: cardWidth, child: Card(child: Padding(padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(metric.$2, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                Text(_display(data?[metric.$1], metric.$1),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ])))),
        ]);
      }),
    ]);
  }

  String _display(Object? value, String key) {
    if (value == null) return 'No live data';
    if (key.endsWith('_paisa')) return value is int ? formatPkr(value) : 'Unavailable';
    return value is num ? value.toString() : 'Unavailable';
  }
}
