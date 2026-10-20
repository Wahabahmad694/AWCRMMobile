import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final composer = TextEditingController();
  final scroll = ScrollController();
  final messages = <({bool user, String text})>[];
  bool busy = false;
  String? error;
  static const suggestions = [
    'What are my sales this month?',
    'Which customers have pending payments?',
    'Who are my top customers?',
    'Which customers should I follow up with?',
  ];

  @override
  void dispose() {
    composer.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? suggestion]) async {
    if (context.read<Session>().previewMode) {
      setState(() => error = 'Sign in to ask about your business data.');
      return;
    }
    final question = (suggestion ?? composer.text).trim();
    if (question.isEmpty || busy) return;
    setState(() {
      messages.add((user: true, text: question));
      busy = true;
      error = null;
      composer.clear();
    });
    try {
      final result = await GetIt.I<ApiClient>().post('/ai/chat', {'message': question});
      final body = result.data;
      if (body is! Map || body['answer'] is! String) {
        throw const ApiFailure('The assistant returned an invalid response.');
      }
      if (!mounted) return;
      setState(() => messages.add((user: false, text: body['answer'] as String)));
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) setState(() => error = 'The assistant is unavailable. Please try again.');
    } finally {
      if (mounted) {
        setState(() => busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) {
            scroll.animateTo(scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    if (context.watch<Session>().previewMode)
      const MaterialBanner(content: Text('Preview mode: AI requests require sign-in and a connected backend.'),
        actions: [SizedBox.shrink()]),
    Expanded(child: messages.isEmpty
      ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
            Icon(Icons.auto_awesome, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text('How can I help your business?', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Ask about your verified CRM data in English, Urdu, or Roman Urdu.', textAlign: TextAlign.center),
            const SizedBox(height: 28),
            for (final prompt in suggestions) Padding(padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(onPressed: busy ? null : () => send(prompt), child: Text(prompt))),
          ])))
      : ListView.builder(controller: scroll, padding: const EdgeInsets.all(20),
          itemCount: messages.length + (busy ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) {
              return const Padding(padding: EdgeInsets.all(16),
                child: Align(alignment: Alignment.centerLeft, child: CircularProgressIndicator()));
            }
            final message = messages[index];
            return Align(alignment: message.user ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680),
                child: Card(color: message.user ? Theme.of(context).colorScheme.primaryContainer : null,
                  child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(message.text)))));
          })),
    if (error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    SafeArea(top: false, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(controller: composer, minLines: 1, maxLines: 4,
          textInputAction: TextInputAction.send, onSubmitted: (_) => send(),
          decoration: const InputDecoration(hintText: 'Ask about your business…',
            border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton.filled(tooltip: 'Send message', onPressed: busy ? null : send,
          icon: const Icon(Icons.arrow_upward)),
      ])))),
  ]);
}
