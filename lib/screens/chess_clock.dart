import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../services/game_provider.dart';
import '../widgets/fixed_width_time.dart';
import '../widgets/animated_blur_overlay.dart';
import '../widgets/chess_controls_widget.dart';
import '../widgets/customization_cards.dart';
import 'settings_screen.dart';
import 'package:solar_icons/solar_icons.dart';

class ChessClockMain extends StatefulWidget {
  const ChessClockMain({super.key});

  @override
  State<ChessClockMain> createState() => _ChessClockMainState();
}

class _ChessClockMainState extends State<ChessClockMain> {
  late GameProvider gameProvider;
  late Duration normalElapsed;
  late Duration invertedElapsed;
  late Duration gameDuration;
  final double bgRadius = AppRadii.bg;
  AudioPool? _tapPool; // Ultra-low-latency pool for tap sound
  final AudioPlayer _fallbackPlayer = AudioPlayer();
  String _assetKey = 'assets/audio/chess.m4a';
  bool _controlsInactive = false;

  @override
  void initState() {
    super.initState();
    _initAudioPool();
  }

  Future<void> _initAudioPool() async {
    for (final key in <String>['assets/audio/chess.m4a', 'audio/chess.m4a']) {
      try {
        final pool = await AudioPool.create(
          source: AssetSource(key),
          maxPlayers: 4, // handle rapid successive taps
        );
        _tapPool = pool;
        _assetKey = key;
        debugPrint('Tap sound pool initialized with asset: $key');
        break;
      } catch (_) {
        debugPrint('Tap sound pool init failed for: $key');
      }
    }
    if (_tapPool == null) {
      debugPrint('Tap sound pool not ready; fallback player will be used.');
    }
  }

  void _playTap() {
    try {
      if (_tapPool != null) {
        _tapPool!.start();
        return;
      }
      _fallbackPlayer.play(AssetSource(_assetKey));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  void dispose() {
    gameProvider.normalPlayerTicker.stop();
    gameProvider.invertedPlayerTicker.stop();
    _tapPool?.dispose();
    _fallbackPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    gameProvider = Provider.of<GameProvider>(context, listen: true);
    normalElapsed = gameProvider.normalPlayerElapsed;
    invertedElapsed = gameProvider.invertedPlayerElapsed;
    gameDuration = gameProvider.gameDuration;

    final bool gameIsOver = gameProvider.gameStatus == GameStatus.over;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Central moving panel
          AnimatedAlign(
            alignment: gameProvider.currentPlayerMove != PlayerMove.normal
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            duration: AppDurations.fast,
            curve: Curves.easeOutCirc,
            child: AnimatedContainer(
              duration: AppDurations.slow,
              curve: Curves.easeOutCirc,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2 - 38,
              decoration: ShapeDecoration(
                color: gameProvider.gameStatus == GameStatus.over
                    ? AppColors.danger
                    : AppColors.surface,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(bgRadius),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: IgnorePointer(
                  ignoring:
                      gameProvider.currentPlayerMove == PlayerMove.normal ||
                          gameIsOver,
                  child: GestureDetector(
                    onTapDown: (_) {},
                    onTap: () {
                      // HapticFeedback.lightImpact();
                      _playTap();
                      gameProvider.switchPlayer();
                    },
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: AppDurations.fast,
                          margin: const EdgeInsets.only(top: 24),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(AppRadii.bg),
                              bottomRight: Radius.circular(AppRadii.bg),
                            ),
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: pi,
                              child: RepaintBoundary(
                                child: FixedWidthTime(
                                  elapsed: invertedElapsed,
                                  gameDuration: gameDuration,
                                  isLoser: gameProvider.isPlayerLoser(
                                    PlayerMove.inverted,
                                  ),
                                  gameIsOver: gameIsOver,
                                  increment: gameProvider
                                      .incrementDuration, // Pass increment
                                  style: AppTextStyles.timeLarge.copyWith(
                                    color: gameProvider.currentPlayerMove ==
                                            PlayerMove.inverted
                                        ? AppColors.gray800
                                        : AppColors.gray500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Positioned(
                        //   bottom: 16,
                        //   left: 0,
                        //   right: 0,
                        //   child: AnimatedOpacity(
                        //     opacity: gameProvider.currentPlayerMove ==
                        //             PlayerMove.normal
                        //         ? 1
                        //         : 0,
                        //     curve: Curves.easeOutCirc,
                        //     duration: const Duration(milliseconds: 500),
                        //     child: Transform.rotate(
                        //       angle: pi,
                        //       child: FixedWidthTime(
                        //         elapsed: normalElapsed,
                        //         gameDuration: gameDuration,
                        //         isLoser: gameProvider.isPlayerLoser(
                        //           PlayerMove.normal,
                        //         ),
                        //         gameIsOver: gameIsOver,
                        //         increment: gameProvider
                        //             .incrementDuration, // Pass increment
                        //         style: TextStyle(
                        //           fontSize: 20,
                        //           color: Colors.grey.shade600,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // Add move counter for inverted player
                        !(gameProvider.gameStatus == GameStatus.over ||
                                gameProvider.gameStatus == GameStatus.idle)
                            ? Positioned(
                                right: 24,
                                top: 32,
                                child: Transform.rotate(
                                  angle: pi,
                                  child: Text(
                                    '${gameProvider.invertedPlayerMoves}',
                                    style: TextStyle(
                                      color: gameProvider.isPlayerLoser(
                                        PlayerMove.inverted,
                                      )
                                          ? AppColors
                                              .white // Use white for loser
                                          : gameProvider.currentPlayerMove ==
                                                  PlayerMove.inverted
                                              ? AppColors.black.withAlpha(100)
                                              : AppColors.gray600,
                                      fontWeight: FontWeight.normal,
                                      fontSize:
                                          AppTextStyles.moveCounter.fontSize,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
              // options and controls row with external settings button

              AnimatedSize(
                duration: AppDurations.fast,
                child: SizedBox(
                  height: 64,
                  child: gameProvider.isCustomizationMode
                      ? const CustomizationScrollableCards()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Settings button placed outside the controls widget
                              IgnorePointer(
                                ignoring: _controlsInactive,
                                child: AnimatedScale(
                                  scale: _controlsInactive ? 0.8 : 1.0,
                                  duration: AppDurations.medium,
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedOpacity(
                                    opacity: _controlsInactive ? 0.0 : 1.0,
                                    duration: AppDurations.medium,
                                    curve: Curves.easeOutCubic,
                                    child: IconButton(
                                      icon: Icon(SolarIconsOutline.settings,
                                          size: 22, color: Colors.white70),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (context, animation,
                                                    secondaryAnimation) =>
                                                const SettingsScreen(),
                                            transitionsBuilder: (context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child) =>
                                                FadeTransition(
                                                    opacity: animation,
                                                    child: child),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              ChessControlsWidget(
                                onInactiveChanged: (inactive) {
                                  if (_controlsInactive != inactive) {
                                    setState(
                                        () => _controlsInactive = inactive);
                                  }
                                },
                              ),
                              IgnorePointer(
                                ignoring: _controlsInactive,
                                child: AnimatedScale(
                                  scale: _controlsInactive ? 0.8 : 1.0,
                                  duration: AppDurations.medium,
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedOpacity(
                                    opacity: _controlsInactive ? 0.0 : 1.0,
                                    duration: AppDurations.medium,
                                    curve: Curves.easeOutCubic,
                                    child: IconButton(
                                      icon: Icon(SolarIconsOutline.palette2,
                                          size: 22, color: Colors.white70),
                                      onPressed: () {
                                        gameProvider.toggleCustomizationMode();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  ignoring:
                      gameProvider.currentPlayerMove == PlayerMove.inverted ||
                          gameIsOver,
                  child: GestureDetector(
                    onTap: () {
                      // HapticFeedback.lightImpact();
                      _playTap();
                      gameProvider.switchPlayer();
                    },
                    child: Stack(
                      children: [
                        gameProvider.gameStatus == GameStatus.idle
                            ? Positioned(
                                top: 224,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Shimmer.fromColors(
                                      baseColor: AppColors.black.withAlpha(100),
                                      highlightColor:
                                          AppColors.black.withAlpha(60),
                                      period: const Duration(seconds: 2),
                                      child: const Text(
                                        'Tap to start clock',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                ))
                            : const SizedBox(),
                        AnimatedContainer(
                          duration: AppDurations.fast,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(AppRadii.bg),
                              topRight: Radius.circular(AppRadii.bg),
                            ),
                          ),
                          child: Center(
                            child: RepaintBoundary(
                              child: FixedWidthTime(
                                elapsed: normalElapsed,
                                gameDuration: gameDuration,
                                isLoser: gameProvider.isPlayerLoser(
                                  PlayerMove.normal,
                                ),
                                gameIsOver: gameIsOver,
                                increment: gameProvider
                                    .incrementDuration, // Pass increment
                                style: AppTextStyles.timeLarge.copyWith(
                                  color: gameProvider.currentPlayerMove ==
                                          PlayerMove.normal
                                      ? AppColors.gray800
                                      : AppColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Positioned(
                        //   left: 0,
                        //   right: 0,
                        //   top: 16,
                        //   child: AnimatedOpacity(
                        //     opacity: gameProvider.currentPlayerMove ==
                        //             PlayerMove.inverted
                        //         ? 1
                        //         : 0,
                        //     duration: const Duration(milliseconds: 500),
                        //     curve: Curves.easeOutCirc,
                        //     child: FixedWidthTime(
                        //       elapsed: invertedElapsed,
                        //       gameDuration: gameDuration,
                        //       isLoser: gameProvider.isPlayerLoser(
                        //         PlayerMove.inverted,
                        //       ),
                        //       gameIsOver: gameIsOver,
                        //       increment: gameProvider
                        //           .incrementDuration, // Pass increment
                        //       style: TextStyle(
                        //         fontSize: 20,
                        //         color: Colors.grey.shade600,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // Add move counter for normal player
                        !(gameProvider.gameStatus == GameStatus.over ||
                                gameProvider.gameStatus == GameStatus.idle)
                            ? Positioned(
                                bottom: 32,
                                left: 24,
                                child: Text(
                                  '${gameProvider.normalPlayerMoves}',
                                  style: TextStyle(
                                    color: gameProvider.isPlayerLoser(
                                      PlayerMove.normal,
                                    )
                                        ? AppColors.white // Use white for loser
                                        : gameProvider.currentPlayerMove ==
                                                PlayerMove.normal
                                            ? AppColors.black.withAlpha(100)
                                            : AppColors.gray600,
                                    fontWeight: FontWeight.normal,
                                    fontSize:
                                        AppTextStyles.moveCounter.fontSize,
                                  ),
                                ),
                              )
                            : const SizedBox(),

                        // gameProvider.gameStatus == GameStatus.idle
                        //     ? Positioned(
                        //         top: 64,
                        //         left: 0,
                        //         right: 0,
                        //         child: Center(
                        //           child: Shimmer.fromColors(
                        //             baseColor: AppColors.black.withAlpha(150),
                        //             highlightColor:
                        //                 AppColors.black.withAlpha(250),
                        //             child: const Text(
                        //               'Tap here to start clock',
                        //               style: AppTextStyles.overlaySmall,
                        //             ),
                        //           ),
                        //         ),
                        //       )
                        //     : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Overlay for paused state
          Selector<GameProvider, bool>(
            selector: (_, gp) => gp.gameStatus == GameStatus.paused,
            builder: (context, isPaused, _) {
              return AnimatedBlurOverlay(
                isVisible: isPaused,
                onTap: () => context.read<GameProvider>().resumeChessClock(),
                blurSigma: 5,
                duration: AppDurations.medium,
                curve: Curves.easeOutCirc,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.flip(
                        flipY: true,
                        flipX: true,
                        child: Shimmer.fromColors(
                          baseColor: AppColors.white.withAlpha(150),
                          highlightColor: AppColors.white.withAlpha(250),
                          child: const Text(
                            'Tap anywhere to resume',
                            style: AppTextStyles.overlaySmall,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 4 + 40,
                        width: double.maxFinite,
                      ),
                      const Icon(
                        CupertinoIcons.play_fill,
                        size: 50,
                        color: AppColors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Timer Paused',
                        style: AppTextStyles.overlayTitle,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 4 + 40,
                        width: double.maxFinite,
                      ),
                      Shimmer.fromColors(
                        baseColor: AppColors.white.withAlpha(150),
                        highlightColor: AppColors.white.withAlpha(250),
                        child: const Text(
                          'Tap anywhere to resume',
                          style: AppTextStyles.overlaySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
