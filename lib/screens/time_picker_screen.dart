import 'package:chess_timer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../widgets/animated_blur_overlay.dart';
import '../widgets/custom_wheel_picker.dart';

class TimePickerScreen extends StatefulWidget {
  final Duration initialDuration;
  final Duration initialIncrement;
  final List<int> timeHours;
  final List<int> timeMinutes;
  final List<int> timeSeconds;
  final List<int> incrementSeconds;

  const TimePickerScreen({
    super.key,
    required this.initialDuration,
    required this.initialIncrement,
    this.timeHours = const [0, 1, 2, 3, 4, 5],
    this.timeMinutes = const [0, 1, 3, 5, 10, 15, 30, 45],
    this.timeSeconds = const [0, 15, 30, 45],
    this.incrementSeconds = const [0, 1, 3, 5, 10, 15, 30],
  });

  @override
  State<TimePickerScreen> createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen> {
  late Duration selectedDuration;
  late Duration selectedIncrement;
  late int initialHoursIndex;
  late int initialMinutesIndex;
  late int initialSecondsIndex;

  // Track current selections
  late int currentHoursIndex;
  late int currentMinutesIndex;
  late int currentSecondsIndex;
  late int currentIncrementIndex;

  @override
  void initState() {
    super.initState();
    selectedDuration = widget.initialDuration;
    selectedIncrement = widget.initialIncrement;

    // Find the closest index for hours
    initialHoursIndex = 0;
    for (int i = 0; i < widget.timeHours.length; i++) {
      if (widget.timeHours[i] == widget.initialDuration.inHours) {
        initialHoursIndex = i;
        break;
      }
    }

    // Find the closest index for minutes
    initialMinutesIndex = 0;
    for (int i = 0; i < widget.timeMinutes.length; i++) {
      if (widget.timeMinutes[i] ==
          widget.initialDuration.inMinutes.remainder(60)) {
        initialMinutesIndex = i;
        break;
      }
    }

    // Find the closest index for seconds
    initialSecondsIndex = 0;
    for (int i = 0; i < widget.timeSeconds.length; i++) {
      if (widget.timeSeconds[i] ==
          widget.initialDuration.inSeconds.remainder(60)) {
        initialSecondsIndex = i;
        break;
      }
    }

    // Find the closest index for increment
    int initialIncrementIndex = 0;
    for (int i = 0; i < widget.incrementSeconds.length; i++) {
      if (widget.incrementSeconds[i] == widget.initialIncrement.inSeconds) {
        initialIncrementIndex = i;
        break;
      }
    }

    // Initialize current selections
    currentHoursIndex = initialHoursIndex;
    currentMinutesIndex = initialMinutesIndex;
    currentSecondsIndex = initialSecondsIndex;
    currentIncrementIndex = initialIncrementIndex;
  }

  void _updateSelectedDuration() {
    int hours = widget.timeHours[currentHoursIndex];
    int minutes = widget.timeMinutes[currentMinutesIndex];
    int seconds = widget.timeSeconds[currentSecondsIndex];
    selectedDuration = Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isZero = selectedDuration == Duration.zero;
    return AnimatedBlurOverlay(
      isVisible: true,
      blurSigma: 8,
      duration: AppDurations.fast,
      backgroundColor: const Color(0xB3000000),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: Colors.black.withAlpha(100),
          child: SafeArea(
            child: Column(
              children: [
                // Pickers section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 140),
                        height: 200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              // Hours picker
                              CustomWheelPicker(
                                label: 'Hours',
                                values: widget.timeHours,
                                initialIndex: initialHoursIndex,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    currentHoursIndex = index;
                                    _updateSelectedDuration();
                                  });
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 26),
                                child: Text(
                                  ":",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              // Minutes picker
                              CustomWheelPicker(
                                label: 'Minutes',
                                values: widget.timeMinutes,
                                initialIndex: initialMinutesIndex,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    currentMinutesIndex = index;
                                    _updateSelectedDuration();
                                  });
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 26),
                                child: Text(
                                  ":",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              // Seconds picker
                              CustomWheelPicker(
                                label: 'Seconds',
                                values: widget.timeSeconds,
                                initialIndex: initialSecondsIndex,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    currentSecondsIndex = index;
                                    _updateSelectedDuration();
                                  });
                                },
                              ),
                              // Increment picker
                              CustomWheelPicker(
                                label: 'Increment',
                                values: widget.incrementSeconds,
                                initialIndex: currentIncrementIndex,
                                prefix: '+',
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    currentIncrementIndex = index;
                                    selectedIncrement = Duration(
                                      seconds: widget.incrementSeconds[
                                          currentIncrementIndex],
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Show warning if duration is zero
                isZero
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Timer duration must be greater than 0.',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : SizedBox(height: 27),
                // Bottom info section
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Each player gets the main time plus increment after each move',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    TextButton(
                      onPressed: isZero
                          ? null
                          : () {
                              Navigator.pop(context,
                                  [selectedDuration, selectedIncrement]);
                            },
                      style: ButtonStyle(
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color>((states) {
                          if (isZero || states.contains(WidgetState.disabled)) {
                            return Colors.white38;
                          }
                          return Colors.white;
                        }),
                      ),
                      child: const Text('Done',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
