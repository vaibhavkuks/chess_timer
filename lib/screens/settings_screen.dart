import 'package:chess_timer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../widgets/animated_blur_overlay.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBlurOverlay(
      isVisible: true,
      blurSigma: 8,
      duration: AppDurations.fast,
      backgroundColor: const Color(0xB3000000),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 40),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: ListView(
                          shrinkWrap: true,
                          children: const [
                            _PlaceholderTile(title: 'Sound Effects'),
                            _PlaceholderTile(title: 'Haptic Feedback'),
                            _PlaceholderTile(title: 'Show Move Counters'),
                            _PlaceholderTile(title: 'Auto Wakelock'),
                            _PlaceholderTile(title: 'Animations'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const Text(
            'Coming soon',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
