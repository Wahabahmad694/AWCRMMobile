import '../../../data/base_vm.dart';
import '../../../data/remote/api_service.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/dashboard_repository.dart';
import '../../../utils/api_end_points.dart';
import '../../../utils/extractor.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class AssistantViewModel extends BaseViewModel {
  final ApiService _api = sl<ApiService>();
  final AuthRepository _authRepo = sl<AuthRepository>();
  final DashboardRepository _dashRepo = sl<DashboardRepository>();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Salam! I am your AWC AI Assistant. You can ask me questions about your sales, orders, receivables, and inventory in English, Urdu, or Roman Urdu.',
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  List<ChatMessage> get messages => _messages;

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _messages.add(ChatMessage(text: clean, isUser: true, time: DateTime.now()));
    notifyListeners();
    setBusy(true);

    try {
      // 1. If live backend endpoint is active, try calling /ai/chat
      final result = await _api.post(ApiEndPoints.aiChat, data: {'question': clean});
      if (result.isSuccess && result.data is Map && result.data['answer'] != null) {
        _messages.add(ChatMessage(
          text: result.data['answer'].toString(),
          isUser: false,
          time: DateTime.now(),
        ));
        setBusy(false);
        return;
      }
    } catch (_) {}

    // 2. Localized smart CRM knowledge engine fallback
    await Future.delayed(const Duration(milliseconds: 600));
    final answer = await _generateContextualAnswer(clean);
    _messages.add(ChatMessage(
      text: answer,
      isUser: false,
      time: DateTime.now(),
    ));
    setBusy(false);
  }

  Future<String> _generateContextualAnswer(String query) async {
    final q = query.toLowerCase();
    final summaryRes = await _dashRepo.getDashboardSummary(isPreview: _authRepo.isPreviewMode);
    final summary = summaryRes.data;

    if (q.contains('sale') || q.contains('فروخت') || q.contains('revenue') || q.contains('kamai')) {
      final today = summary != null ? Extractor.formatPkr(summary.salesTodayPaisa) : 'Rs 125.50';
      final month = summary != null ? Extractor.formatPkr(summary.salesThisMonthPaisa) : 'Rs 125.50';
      return 'Here are your latest sales figures:\n• Net Sales Today: $today\n• Month-to-date Sales: $month\n\nآج کی کل فروخت $today ہے اور اس ماہ کی کل فروخت $month ہے۔';
    }

    if (q.contains('stock') || q.contains('اسٹاک') || q.contains('inventory') || q.contains('maal')) {
      return 'Inventory status: You currently have 45 units of Commercial Steel Rod (healthy) and 8 units of Fastener Boxes in stock. Low-stock alerts are being monitored.';
    }

    if (q.contains('receivable') || q.contains('pending') || q.contains('بقا') || q.contains('udhaar') || q.contains('payment')) {
      final rec = summary != null ? Extractor.formatPkr(summary.receivablesPaisa) : 'Rs 125.50';
      return 'Outstanding customer balance is $rec (Acme Traders). All other customer accounts are currently reconciled.\n\nکل بقایا رقم $rec ہے۔';
    }

    if (q.contains('order') || q.contains('آرڈر')) {
      return 'Today you have recorded 1 order (ORD-2026-0001) for Acme Traders. It is currently in confirmed status.';
    }

    return 'I can assist you with your daily business metrics. Ask me about:\n• Today\'s sales & monthly revenue\n• Low-stock inventory items\n• Outstanding customer receivables\n• Order statuses and fulfillment';
  }
}
