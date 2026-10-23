import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../services/secure_storage_service.dart';

class AppStartup extends ChangeNotifier {
  AppStartup(this.auth, this.storage);
  final AuthRepository auth;
  final SecureStorageService storage;
  bool _disposed = false;
  bool ready = false;
  bool onboardingSeen = false;

  Future<void> start() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1900)),
      () async {
        try {
          onboardingSeen = await storage.getOnboardingSeen();
          await auth.restoreSession();
        } catch (_) {
          // Storage/network failures must still let the user reach sign in.
        }
      }(),
    ]);
    if (_disposed) return;
    ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> finishOnboarding() async {
    await storage.setOnboardingSeen();
    if (_disposed) return;
    onboardingSeen = true;
    notifyListeners();
  }
}

class SplashView extends StatefulWidget {
  const SplashView({super.key});
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF062B43),
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (_, _) => CustomPaint(
                size: const Size(220, 120),
                painter: _BrandLines(
                  MediaQuery.disableAnimationsOf(context) ? 1 : animation.value,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'AWC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your business. Connected.',
              style: TextStyle(color: Color(0xFF9CBAD0), fontSize: 15),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF61DCC7),
                backgroundColor: Color(0xFF164862),
                semanticsLabel: 'Opening AWC',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BrandLines extends CustomPainter {
  _BrandLines(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(10, 100)
      ..lineTo(48, 20)
      ..lineTo(85, 100)
      ..moveTo(27, 68)
      ..lineTo(69, 68)
      ..moveTo(78, 24)
      ..lineTo(104, 100)
      ..lineTo(129, 45)
      ..lineTo(151, 100)
      ..lineTo(178, 24)
      ..moveTo(209, 32)
      ..cubicTo(155, -8, 155, 131, 209, 91);
    final paint = Paint()
      ..color = const Color(0xFF56C8FA)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * Curves.easeInOut.transform(progress);
    for (final metric in metrics) {
      canvas.drawPath(
        metric.extractPath(0, math.min(remaining, metric.length)),
        paint,
      );
      remaining = math.max(0, remaining - metric.length);
    }
  }

  @override
  bool shouldRepaint(_BrandLines oldDelegate) =>
      oldDelegate.progress != progress;
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onContinue});
  final Future<void> Function() onContinue;
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F8FC),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'AWC',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF075BA7),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF062B43),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.hub_outlined,
                        color: Color(0xFF61DCC7),
                        size: 64,
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'ONE CONNECTED WORKSPACE',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1.8,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final label in [
                            'Leads',
                            'Sales',
                            'Inventory',
                            'Cash & bank',
                          ])
                            Chip(
                              label: Text(label),
                              backgroundColor: const Color(0xFFE7F3FF),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Your next chapter\nstarts here.',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF062B43),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AWC brings your customers, sales and finances together, so you can spend more time growing your business.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF52697C),
                  ),
                ),
                const SizedBox(height: 24),
                for (final feature in [
                  (Icons.trending_up, 'Turn leads into lasting customers'),
                  (
                    Icons.inventory_2_outlined,
                    'Track orders, stock and returns',
                  ),
                  (
                    Icons.account_balance_wallet_outlined,
                    'Stay on top of payments and balances',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Icon(
                          feature.$1,
                          color: const Color(0xFF0878C9),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature.$2,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            await widget.onContinue();
                          } catch (_) {
                            if (mounted) {
                              setState(() {
                                saving = false;
                                error = 'Could not save your preference. Please try again.';
                              });
                            }
                          }
                        },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(saving ? 'Opening…' : 'Get started'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in or create your workspace next',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF738899), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
