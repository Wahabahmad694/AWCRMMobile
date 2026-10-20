import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';

class RecordsList extends StatefulWidget {
  const RecordsList({super.key, required this.resource, required this.title});
  final String resource;
  final String title;
  @override
  State<RecordsList> createState() => _RecordsListState();
}

class _RecordsListState extends State<RecordsList> {
  final search = TextEditingController();
  Timer? debounce;
  Future<Map<String, dynamic>>? future;
  String? organization;
  int page = 1;

  void load() {
    if (context.read<Session>().previewMode) return;
    final query = <String, dynamic>{'page': page, 'limit': 20};
    if (search.text.trim().isNotEmpty) query['search'] = search.text.trim();
    setState(() => future = () async {
      final response = await GetIt.I<ApiClient>().get('/${widget.resource}', query: query);
      final data = response.data;
      if (data is! Map || data['items'] is! List) {
        throw const ApiFailure('The server returned an invalid list response.');
      }
      return data.map((key, value) => MapEntry(key.toString(), value));
    }());
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    if (session.previewMode) return _state('Preview mode', 'Sign in to load ${widget.title.toLowerCase()} from your organization.');
    if (organization != session.organizationId || future == null) {
      organization = session.organizationId;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) load(); });
    }
    return Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: TextField(
        controller: search,
        decoration: InputDecoration(labelText: 'Search ${widget.title.toLowerCase()}', prefixIcon: const Icon(Icons.search),
          suffixIcon: search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () {
            search.clear(); page = 1; load();
          })),
        onChanged: (_) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 300), () {
          page = 1; load();
        }); },
      )),
      Expanded(child: FutureBuilder<Map<String, dynamic>>(future: future, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _state('Could not load ${widget.title.toLowerCase()}',
            snapshot.error.toString(), retry: load);
        }
        final data = snapshot.data!;
        final items = data['items'] as List;
        if (items.isEmpty) {
          return _state(search.text.isEmpty ? 'No ${widget.title.toLowerCase()} yet' : 'No matching results',
            search.text.isEmpty ? 'Records will appear here when created.' : 'Try a different search.');
        }
        final hasMore = data['has_more'] == true;
        return RefreshIndicator(onRefresh: () async { load(); await future; }, child: ListView.builder(
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == items.length) {
              return Padding(padding: const EdgeInsets.all(16), child: Row(
              mainAxisAlignment: MainAxisAlignment.center, children: [
                OutlinedButton(onPressed: page <= 1 ? null : () { page--; load(); }, child: const Text('Previous')),
                const SizedBox(width: 12), Text('Page $page'), const SizedBox(width: 12),
                OutlinedButton(onPressed: hasMore ? () { page++; load(); } : null, child: const Text('Next')),
              ],
            ));
            }
            final item = items[index];
            if (item is! Map) { return const SizedBox.shrink(); }
            final label = item['name'] ?? item['order_number'] ?? item['reference'] ?? item['id'];
            return Card(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: ListTile(title: Text(label?.toString() ?? 'Record'),
                subtitle: Text(_subtitle(item)), isThreeLine: false));
          },
        ));
      })),
    ]);
  }

  String _subtitle(Map item) {
    final values = <String>[];
    for (final key in ['phone', 'city', 'status', 'payment_status', 'date']) {
      final value = item[key];
      if (value != null && value.toString().isNotEmpty) values.add(value.toString());
    }
    return values.isEmpty ? 'Record available' : values.take(3).join(' • ');
  }

  Widget _state(String title, String detail, {VoidCallback? retry}) => Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.inbox_outlined, size: 48), const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8),
      Text(detail, textAlign: TextAlign.center),
      if (retry != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: retry, child: const Text('Retry'))],
    ]),
  ));
}
