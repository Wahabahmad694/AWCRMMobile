import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../bottomNav/custom_bottom_nav.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import 'assistant_vm.dart';

class AssistantView extends StatefulWidget {
  const AssistantView({super.key});

  @override
  State<AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<AssistantView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<String> _quickPrompts = [
    'What are our sales today?',
    'آج کی کل فروخت کتنی ہے؟',
    'Who has pending receivables?',
    'Show low-stock products',
    'کل بقایا رقم کتنی ہے؟',
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => AssistantViewModel(),
      child: Consumer<AssistantViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'AI Copilot',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/assistant'),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 3,
              onTap: (index) {
                if (index == 0) context.go('/dashboard');
                if (index == 1) context.go('/customers');
                if (index == 2) context.go('/orders');
              },
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            body: Column(
              children: [
                // Quick suggested query prompts
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickPrompts.map((prompt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(prompt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFFEFF5FC),
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () {
                              vm.sendMessage(prompt);
                              _scrollToBottom();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Chat Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.messages.length + (vm.isBusy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == vm.messages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              _assistantAvatar(),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final msg = vm.messages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!msg.isUser) ...[
                              _assistantAvatar(),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: msg.isUser ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                                    bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                                  ),
                                  border: msg.isUser ? null : Border.all(color: AppColors.border),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.03),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: msg.isUser ? Colors.white : AppColors.textPrimary,
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: msg.isUser ? FontWeight.w500 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Input Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Ask your copilot anything…',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              vm.sendMessage(text);
                              _textCtrl.clear();
                              _scrollToBottom();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          if (_textCtrl.text.trim().isNotEmpty) {
                            vm.sendMessage(_textCtrl.text);
                            _textCtrl.clear();
                            _scrollToBottom();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _assistantAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.drawerBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF62B3FF), size: 16),
    );
  }
}
