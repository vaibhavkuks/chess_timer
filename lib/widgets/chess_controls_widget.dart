import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_effects/hyper_effects.dart';

import 'package:provider/provider.dart';

import 'package:solar_icons/solar_icons.dart';
import '../screens/time_picker_screen.dart';
import '../services/game_provider.dart';
import '../theme/app_theme.dart';

class ChessControlsWidget extends StatefulWidget {
  const ChessControlsWidget({super.key, this.onInactiveChanged});

  // Notifies parent when controls become inactive/active due to user inactivity while running
  final ValueChanged<bool>? onInactiveChanged;

  @override
  State<ChessControlsWidget> createState() => _ChessControlsWidgetState();
}

class _ChessControlsWidgetState extends State<ChessControlsWidget> {
  final BorderRadiusGeometry radius =
      BorderRadiusGeometry.circular(AppRadii.controls);

  // A flag to check if the controls have not been interacted with for some time
  bool inactive = false;
  DateTime? lastInteraction;
  // Stores threshold for inactivity
  int inactivityThreshold = 4; // seconds
  bool _lastGameRunningState = false; // Track previous game state

  Duration animationDuration = AppDurations.slow;

  Timer? _inactiveTimer;

  void _setInactive(bool value) {
    if (inactive == value) return;
    setState(() {
      inactive = value;
    });
    // Notify parent
    widget.onInactiveChanged?.call(inactive);
  }

  bool isFirstFrame = true; // Flag to skip animation on first frame

  @override
  void initState() {
    super.initState();
    lastInteraction = DateTime.now();
  }

  void _startInactiveTimer() {
    _inactiveTimer?.cancel();
    _inactiveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        final timeSinceLastInteraction = now.difference(lastInteraction!);

        if (timeSinceLastInteraction.inSeconds >= inactivityThreshold) {
          if (!inactive) _setInactive(true);
        } else {
          if (inactive) _setInactive(false);
        }
      }
    });
  }

  void _stopInactiveTimer() {
    _inactiveTimer?.cancel();
    if (inactive) _setInactive(false);
  }

  void _recordInteraction() {
    lastInteraction = DateTime.now();
    if (inactive) _setInactive(false);
  }

  void _manageTimerState(bool gameIsRunning) {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (gameIsRunning && !_lastGameRunningState) {
          // Game just started running
          if (_inactiveTimer == null || !_inactiveTimer!.isActive) {
            _startInactiveTimer();
          }
        } else if (!gameIsRunning && _lastGameRunningState) {
          // Game just stopped running
          _stopInactiveTimer();
        }
        _lastGameRunningState = gameIsRunning;
      }
      setState(() {
        isFirstFrame = false; // Set to false after first frame
      });
    });
  }

  @override
  void dispose() {
    _inactiveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final bool gameIsOver = gameProvider.gameStatus == GameStatus.over;
        final bool gameIsRunning =
            gameProvider.gameStatus == GameStatus.running;

        // Manage timer state safely outside of build
        _manageTimerState(gameIsRunning);

        return SizedBox(
          height: 64,
          child: Center(
            child: GestureDetector(
              onTap: () {
                // Reset the inactive state when tapped and restart timer
                if (gameIsRunning) {
                  _recordInteraction();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.all(6),
                decoration: ShapeDecoration(
                  color: AppColors.surface,
                  shape: RoundedSuperellipseBorder(borderRadius: radius),
                ),
                child: AnimatedSize(
                    onEnd: () {},
                    duration: animationDuration,
                    curve: Curves.elasticOut,
                    clipBehavior: Clip.none,
                    child: gameIsOver
                        ? _buildGameOverControls(context, gameProvider)
                        : (inactive && gameIsRunning)
                            ? Container(
                                key: const Key('inactive_controls'),
                                child: _buildMinimizedControls(),
                              )
                                .scaleIn(
                                  start: 2.4,
                                  end: 1,
                                )
                                .blurX(
                                  0,
                                  from: 10,
                                )
                                .oneShot(
                                  duration: animationDuration,
                                  curve: Curves.elasticOut,
                                )
                            : Container(
                                key: const Key('active_controls'),
                                child: _buildGameRunningControls(
                                    context, gameProvider),
                              )),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOverControls(
      BuildContext context, GameProvider gameProvider) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        gameProvider.resetChessClock();
        _stopInactiveTimer(); // Stop timer when reset from game over
      },
      borderRadius: BorderRadius.circular(AppRadii.controls),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(10, 9, 10, 11),
        child: Icon(
          SolarIconsOutline.restart,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMinimizedControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedDot(0),
          const SizedBox(width: 12),
          _buildAnimatedDot(1),
          const SizedBox(width: 12),
          _buildAnimatedDot(2),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.gray500,
        borderRadius: BorderRadius.circular(AppRadii.dot),
      ),
    ).fadeIn(start: 0.8, end: 0.4).oneShot(
          duration: animationDuration,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildGameRunningControls(
      BuildContext context, GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reset button
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              gameProvider.resetChessClock();
              _stopInactiveTimer(); // Stop timer when reset
            },
            icon: const Icon(SolarIconsOutline.restart),
          ),
          const SizedBox(width: 8),
          // Time picker button
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _recordInteraction(); // Record interaction when opening time picker
              _openTimePicker(context, gameProvider);
            },
            icon: const Icon(SolarIconsOutline.clockCircle),
          ),
          const SizedBox(width: 8),
          // Play/Pause button
          IconButton(
            onPressed: gameProvider.gameStatus == GameStatus.running
                ? () {
                    HapticFeedback.lightImpact();
                    gameProvider.pauseChessClock();
                    _stopInactiveTimer(); // Stop timer when paused
                  }
                : () {
                    HapticFeedback.lightImpact();
                    if (gameProvider.gameStatus == GameStatus.paused) {
                      gameProvider.resumeChessClock();
                      _recordInteraction(); // Record interaction when resumed
                    } else if (gameProvider.gameStatus != GameStatus.over) {
                      gameProvider.startChessClock(true);
                      _recordInteraction(); // Record interaction when game starts
                    }
                  },
            icon: Icon(
              gameProvider.gameStatus == GameStatus.running
                  ? SolarIconsOutline.pause
                  : SolarIconsOutline.play,
            ),
            iconSize: 21,
          ),
        ],
      )
          .scaleIn(
            start: 0.3,
            end: 1.0,
          )
          .blurX(
            0,
            from: 5,
          )
          .oneShot(
            skipIf: () {
              return isFirstFrame; // Skip animation on first frame
            },
            duration: animationDuration,
            curve: Curves.elasticOut,
          ),
    );
  }

  Future<void> _openTimePicker(
      BuildContext context, GameProvider gameProvider) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            TimePickerScreen(
          initialDuration: gameProvider.gameDuration,
          initialIncrement: gameProvider.incrementDuration,
          timeHours: List.generate(13, (index) => index),
          timeMinutes: List.generate(60, (index) => index),
          timeSeconds: List.generate(60, (index) => index),
          incrementSeconds: List.generate(60, (index) => index),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );

    if (result != null && result is List<Duration>) {
      gameProvider.resetChessClock();
      gameProvider.setTimeControl(result[0], result[1]);
    }
  }
}
