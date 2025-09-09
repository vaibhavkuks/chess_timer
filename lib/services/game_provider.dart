import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:developer' as dev;
import 'package:wakelock_plus/wakelock_plus.dart';

class GameConfig {
  final GameStatus gameStatus;
  final PlayerMove currentPlayerMove;
  final Duration gameDuration;
  final Duration incrementDuration;
  final Duration normalElapsed;
  final Duration invertedElapsed;
  final Duration normalRemaining;
  final Duration invertedRemaining;
  final int normalMoves;
  final int invertedMoves;
  final PlayerMove? losingPlayer;

  const GameConfig({
    required this.gameStatus,
    required this.currentPlayerMove,
    required this.gameDuration,
    required this.incrementDuration,
    required this.normalElapsed,
    required this.invertedElapsed,
    required this.normalRemaining,
    required this.invertedRemaining,
    required this.normalMoves,
    required this.invertedMoves,
    required this.losingPlayer,
  });

  Map<String, dynamic> toJson() => {
        'gameStatus': gameStatus.name,
        'currentPlayerMove': currentPlayerMove.name,
        'gameDurationMs': gameDuration.inMilliseconds,
        'incrementDurationMs': incrementDuration.inMilliseconds,
        'normalElapsedMs': normalElapsed.inMilliseconds,
        'invertedElapsedMs': invertedElapsed.inMilliseconds,
        'normalRemainingMs': normalRemaining.inMilliseconds,
        'invertedRemainingMs': invertedRemaining.inMilliseconds,
        'normalMoves': normalMoves,
        'invertedMoves': invertedMoves,
        'losingPlayer': losingPlayer?.name,
      };
}

class GameProvider extends ChangeNotifier {
  late final Ticker normalPlayerTicker;
  late final Ticker invertedPlayerTicker;

  // Track accumulated time when tickers are paused
  Duration normalPlayerAccumulated = Duration.zero;
  Duration invertedPlayerAccumulated = Duration.zero;

  // Track which player lost due to time expiration
  PlayerMove? _losingPlayer;

  // Track moves for each player
  int normalPlayerMoves = 0;
  int invertedPlayerMoves = 0;

  // Add increment duration
  Duration incrementDuration = Duration.zero;

  GameProvider() {
    dev.log('🚀 GameProvider initialized');
    normalPlayerTicker = Ticker((elapsed) {
      updateNormalPlayerElapsed(normalPlayerAccumulated + elapsed);
    });

    invertedPlayerTicker = Ticker((elapsed) {
      updateInvertedPlayerElapsed(invertedPlayerAccumulated + elapsed);
    });

    // Add listener to manage wakelock based on game status
    addListener(_wakelockListener);
    dev.log('📱 Wakelock listener added');
  }

  // final Soundpool soundpool = Soundpool.fromOptions(
  //   options: const SoundpoolOptions(streamType: StreamType.music),
  // );

  GameStatus gameStatus = GameStatus.idle;

  PlayerMove currentPlayerMove = PlayerMove.normal;

  Duration gameDuration = const Duration(minutes: 10);

  Duration normalPlayerElapsed = const Duration();
  Duration invertedPlayerElapsed = const Duration();

  // Wakelock listener to manage screen wake state
  void _wakelockListener() {
    _updateWakelock();
  }

  // Method to enable/disable wakelock based on game status
  void _updateWakelock() async {
    try {
      if (gameStatus == GameStatus.running && !(await WakelockPlus.enabled)) {
        await WakelockPlus.enable();
        dev.log('Wakelock enabled - game is running');
      } else if (gameStatus != GameStatus.running) {
        await WakelockPlus.disable();
        dev.log('Wakelock disabled - game is not running');
      }
    } catch (e) {
      dev.log('Error managing wakelock: $e');
    }
  }

  void updateNormalPlayerElapsed(Duration elapsed) {
    // dev.log(
    //     '⏱️ Normal player elapsed: ${elapsed.inMilliseconds}ms (accumulated: ${normalPlayerAccumulated.inMilliseconds}ms)');
    if (elapsed >= gameDuration) {
      dev.log('⚠️ Normal player time expired! Game ending...');
      _losingPlayer = PlayerMove.normal;
      endGame();
    }
    normalPlayerElapsed = elapsed;
    notifyListeners();
  }

  void updateInvertedPlayerElapsed(Duration elapsed) {
    // dev.log(
    //     '⏱️ Inverted player elapsed: ${elapsed.inMilliseconds}ms (accumulated: ${invertedPlayerAccumulated.inMilliseconds}ms)');
    if (elapsed >= gameDuration) {
      dev.log('⚠️ Inverted player time expired! Game ending...');
      _losingPlayer = PlayerMove.inverted;
      endGame();
    }
    invertedPlayerElapsed = elapsed;
    notifyListeners();
  }

  void startNormalPlayer() {
    dev.log(
        '▶️ Starting normal player timer (accumulated: ${normalPlayerAccumulated.inSeconds}s)');
    normalPlayerTicker.start();
    gameStatus = GameStatus.running;
    notifyListeners();
  }

  void stopNormalPlayer() {
    dev.log(
        '⏸️ Stopping normal player timer (elapsed: ${normalPlayerElapsed.inSeconds}s)');
    // Save accumulated time before stopping
    normalPlayerAccumulated = normalPlayerElapsed;
    normalPlayerTicker.stop();
    dev.log(
        '💾 Normal player accumulated time saved: ${normalPlayerAccumulated.inSeconds}s');
    notifyListeners();
  }

  void startInvertedPlayer() {
    dev.log(
        '▶️ Starting inverted player timer (accumulated: ${invertedPlayerAccumulated.inSeconds}s)');
    invertedPlayerTicker.start();
    gameStatus = GameStatus.running;
    notifyListeners();
  }

  void stopInvertedPlayer() {
    dev.log(
        '⏸️ Stopping inverted player timer (elapsed: ${invertedPlayerElapsed.inSeconds}s)');
    // Save accumulated time before stopping
    invertedPlayerAccumulated = invertedPlayerElapsed;
    invertedPlayerTicker.stop();
    dev.log(
        '💾 Inverted player accumulated time saved: ${invertedPlayerAccumulated.inSeconds}s');
    notifyListeners();
  }

  @override
  void dispose() {
    // Remove the wakelock listener before disposing
    removeListener(_wakelockListener);

    // Disable wakelock when disposing
    WakelockPlus.disable().catchError((e) {
      dev.log('Error disabling wakelock on dispose: $e');
    });

    normalPlayerTicker.dispose();
    invertedPlayerTicker.dispose();
    // soundpool.dispose();
    super.dispose();
  }

  void stopBoth() {
    dev.log('⏹️ Stopping both timers');
    normalPlayerAccumulated = normalPlayerElapsed;
    invertedPlayerAccumulated = invertedPlayerElapsed;
    normalPlayerTicker.stop();
    invertedPlayerTicker.stop();
    dev.log(
        '⏹️ Both timers stopped - Normal: ${normalPlayerAccumulated.inSeconds}s, Inverted: ${invertedPlayerAccumulated.inSeconds}s');
    notifyListeners();
  }

  void startChessClock(bool? normalPlayerFirst) {
    dev.log(
        '🎮 Starting chess clock - normal player first: ${normalPlayerFirst ?? true}');
    gameStatus = GameStatus.running;

    if (normalPlayerFirst ?? true) {
      startNormalPlayer();
    } else {
      startInvertedPlayer();
    }
  }

  void pauseChessClock() {
    dev.log('⏸️ Pausing chess clock');
    gameStatus = GameStatus.paused;
    stopBoth();
    notifyListeners();
  }

  void resumeChessClock() {
    dev.log(
        '▶️ Resuming chess clock - current player: ${currentPlayerMove.name}');
    gameStatus = GameStatus.running;

    if (currentPlayerMove == PlayerMove.normal) {
      startNormalPlayer();
    } else {
      startInvertedPlayer();
    }
  }

  void switchPlayer() {
    dev.log('🔄 ========== SWITCHING PLAYER ==========');
    dev.log('🔄 Current player: ${currentPlayerMove.name}');
    dev.log('🔄 Increment duration: ${incrementDuration.inSeconds}s');

    if (currentPlayerMove == PlayerMove.normal) {
      dev.log('🔄 Normal player completing move...');

      // Stop current player and apply increment BEFORE switching
      stopNormalPlayer();
      normalPlayerMoves++; // Increment moves when switching from normal player
      dev.log('📊 Normal player moves: $normalPlayerMoves');

      // Apply increment to the player who just completed their move
      if (incrementDuration != Duration.zero) {
        dev.log(
            '⏰ Applying ${incrementDuration.inSeconds}s increment to normal player...');
        applyIncrementToNormalPlayer();
        notifyListeners();
      }

      currentPlayerMove = PlayerMove.inverted;
      dev.log('🔄 Switched to inverted player');
      startInvertedPlayer();
    } else {
      dev.log('🔄 Inverted player completing move...');

      // Stop current player and apply increment BEFORE switching
      stopInvertedPlayer();
      invertedPlayerMoves++; // Increment moves when switching from inverted player
      dev.log('📊 Inverted player moves: $invertedPlayerMoves');

      // Apply increment to the player who just completed their move
      if (incrementDuration > Duration.zero) {
        dev.log(
            '⏰ Applying ${incrementDuration.inSeconds}s increment to inverted player...');
        applyIncrementToInvertedPlayer();
        notifyListeners();
      }

      currentPlayerMove = PlayerMove.normal;
      dev.log('🔄 Switched to normal player');
      startNormalPlayer();
    }
    dev.log('🔄 ========== SWITCH COMPLETE ==========');
    notifyListeners();
  }

  // Helper methods to apply increment
  void applyIncrementToNormalPlayer() {
    dev.log('💰 === APPLYING INCREMENT TO NORMAL PLAYER ===');
    dev.log(
        '💰 Before - Accumulated: ${normalPlayerAccumulated.inSeconds}s, Elapsed: ${normalPlayerElapsed.inSeconds}s');

    // Calculate how much time to subtract from elapsed time (adding time to the clock)
    Duration newElapsed = normalPlayerAccumulated - incrementDuration;

    normalPlayerAccumulated = newElapsed;

    updateNormalPlayerElapsed(newElapsed);

    dev.log('💰 After - Accumulated: ${normalPlayerAccumulated.inSeconds}s');
    dev.log(
        '💰 Increment of ${incrementDuration.inSeconds}s applied to normal player');
    dev.log('💰 === INCREMENT APPLICATION COMPLETE ===');
    notifyListeners();
  }

  void applyIncrementToInvertedPlayer() {
    dev.log('💰 === APPLYING INCREMENT TO INVERTED PLAYER ===');
    dev.log(
        '💰 Before - Accumulated: ${invertedPlayerAccumulated.inSeconds}s, Elapsed: ${invertedPlayerElapsed.inSeconds}s');

    // Calculate how much time to subtract from elapsed time (adding time to the clock)
    Duration newElapsed = invertedPlayerAccumulated - incrementDuration;

    invertedPlayerAccumulated = newElapsed;

    updateInvertedPlayerElapsed(newElapsed);

    dev.log('💰 After - Accumulated: ${invertedPlayerAccumulated.inSeconds}s');
    dev.log(
        '💰 Increment of ${incrementDuration.inSeconds}s applied to inverted player');
    dev.log('💰 === INCREMENT APPLICATION COMPLETE ===');
    notifyListeners();
  }

  void resetChessClock() {
    dev.log('🔄 ========== RESETTING CHESS CLOCK ==========');
    gameStatus = GameStatus.idle;
    currentPlayerMove = PlayerMove.normal;
    stopBoth();
    normalPlayerAccumulated = Duration.zero;
    invertedPlayerAccumulated = Duration.zero;
    normalPlayerElapsed = Duration.zero;
    invertedPlayerElapsed = Duration.zero;
    normalPlayerMoves = 0; // Reset move counters
    invertedPlayerMoves = 0;
    _losingPlayer = null;
    dev.log('🔄 All timers and counters reset to zero');
    dev.log('🔄 ========== RESET COMPLETE ==========');
    notifyListeners();
  }

  void endGame() {
    dev.log('🏁 Game ending - Winner: ${getWinnerText()}');
    gameStatus = GameStatus.over;
    stopBoth();
  }

  // Get winner text based on who ran out of time
  String getWinnerText() {
    if (_losingPlayer == PlayerMove.normal) {
      return "Inverted Player Wins!";
    } else if (_losingPlayer == PlayerMove.inverted) {
      return "Normal Player Wins!";
    }
    return "Game Over";
  }

  // Check if a specific player is the loser
  bool isPlayerLoser(PlayerMove playerMove) {
    return gameStatus == GameStatus.over && _losingPlayer == playerMove;
  }

  // Add a method to set both game duration and increment
  void setTimeControl(Duration gameDuration, Duration increment) {
    dev.log(
        '⚙️ Setting time control - Duration: ${gameDuration.inMinutes}min ${gameDuration.inSeconds % 60}s, Increment: ${increment.inSeconds}s');
    this.gameDuration = gameDuration;
    incrementDuration = increment;
    notifyListeners();
  }

  GameConfig getGameConfig() {
    final Duration normalRemaining =
        (gameDuration - normalPlayerElapsed).isNegative
            ? Duration.zero
            : (gameDuration - normalPlayerElapsed);
    final Duration invertedRemaining =
        (gameDuration - invertedPlayerElapsed).isNegative
            ? Duration.zero
            : (gameDuration - invertedPlayerElapsed);

    return GameConfig(
      gameStatus: gameStatus,
      currentPlayerMove: currentPlayerMove,
      gameDuration: gameDuration,
      incrementDuration: incrementDuration,
      normalElapsed: normalPlayerElapsed,
      invertedElapsed: invertedPlayerElapsed,
      normalRemaining: normalRemaining,
      invertedRemaining: invertedRemaining,
      normalMoves: normalPlayerMoves,
      invertedMoves: invertedPlayerMoves,
      losingPlayer: _losingPlayer,
    );
  }
}

enum GameStatus {
  idle,
  running,
  paused,
  over,
}

enum PlayerMove {
  normal,
  inverted,
}
