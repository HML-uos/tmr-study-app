import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'session_utils.dart';
import 'flashcard_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key,});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _countdown = 15 * 60;
  int _remainingPlaybackTime = 15 * 60;
  int _initialDelay = 30 * 60;
  bool _isPaused = false;
  int _pauseCountdown = 0;
  Timer? _pauseTimer;
  Timer? _timer;
  double _currentVolume = 100;
  double _initialVolume = 100;
  final List<int> _delayStack = [];
  final List<int> _pauseStack = [];
  final List<Map<String, dynamic>> _volumeChanges = [];
  bool _isSoundCheckActive = false;
  int _soundCheckCounter = 0;
  List<String> _soundCheckFiles = [
    'soundcheck1_normalized.wav',
    'soundcheck2_normalized.wav',
    'soundcheck3_normalized.wav',
    'soundcheck4_normalized.wav',
    'soundcheck5_normalized.wav',
    'soundcheck6_normalized.wav'
  ];
  int _soundCheckSessionCounter = 0;
  int _soundCheckCountdown = 60;
  bool _wasSessionCanceled = false;
  bool _reportGenerated = false;
  bool _sessionCompleted = false;

  bool get _canUndoDelay =>
      _delayStack.isNotEmpty && _countdown >= 900; 

  bool get _canUndoPause =>
      _pauseStack.isNotEmpty &&
      _pauseCountdown >= 900; 

  // Tracking variables
  DateTime? _sessionStartTime;
  int _delayPressCount = 0;
  int _pausePressCount = 0;
  int _pauseElongationCount = 0;
  int _pauseUndoCount = 0;
  int _delayUndoCount = 0;
  final List<DateTime> _delayPressTimes = [];
  final List<DateTime> _pausePressTimes = [];
  final List<DateTime> _pauseElongationTimes = [];
  int _sessionCounter = 0;
  int _nextSoundCountdown = 10;
  Timer? _nextSoundTimer;

  List<FlashCard> _replayFlashcards = flashcards.sublist(60);

  bool _isTimerRunning = false;

  String _formatTime(int timeInSeconds) {
    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  late UserGroup _userGroup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUserGroupAndFlashcards();
    _loadSessionCounter();
    _loadVolume();
    _loadSoundCheckCounter();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sleeping and Replay Area',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              'This is the Sleeping and Replay area of the app.\n\n'
              'Here you can access the volume check and the sound replay for your nightly memory reactivation.\n\n'
              'Setting your volume.\n\n'
              'Before you start your nightly reply always perform a "Volume Check" to ensure a suitable volume. The volume check plays 6 neutral sounds, not associated with your newly learned words, with 10 second intervals between them. As the sounds play you can choose your preferred volume setting via the volume slider. Set the volume to a level that you feel will be comfortable for your nightly replay. Your sound check volume will be saved and is then also utilized during the replay. If you do not need all of the 6 sounds to find a suitable volume level, you can also exit the volume check early by clicking "Save Volume & Quit". Please use the button and do not exit the sound check via the back arrow - doing this will not save your volume settings.\n\n'
              'You can also still freely change the volume during replay later at night, should the sounds wake you up.\n\n'
              'Your nightly replay.\n\n'
              'Once you have performed your volume check, you can start your nightly sound replay via "Go to bed". After clicking a 30 minute timer will start in which no sounds are playing, to ensure you can fall asleep in peace. If you can not fall asleep in these 30 minutes you can always elongate this buffer in 15 minute steps. You can also undo buffer elongations, should you accidentally elongate the timer too much.\n\n'
              'Once the timer has run out your cue sounds will start to play. You can adapt the sound volume even during replay via the volume slider, should you wake up by the sounds. If you are woken up, you can pause the replay to fall back asleep. You can elongate these pauses in the same manner as the replay buffer in 15 minute steps.\n\n'
              'Make sure to set your phone\'s volume to 50% and to only use the app integrated volume controls and to only use the app integrated volume controls and do not close the app during an active session.\n\n'
              'If you encounter any problems or have any questions on the app or the study, you can always contact Marius Lange via a mail to mariulange@uos.de.\n\n'
              'Thank you for your participation!',
              style: TextStyle(color: Colors.black),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _initializeUserGroupAndFlashcards() async {
    _userGroup = await SessionUtils.getUserGroup();
    setState(() {
      _replayFlashcards =
          flashcards.sublist(60); 
      _replayFlashcards.shuffle(Random());
    });
  }

  Future<void> _enableWakelock() async {
    await Wakelock.enable();
  }

  Future<void> _disableWakelock() async {
    await Wakelock.disable();
  }

  Future<void> _loadSessionCounter() async {
    int counter = await SessionUtils.getReplaySessionCounter();
    setState(() {
      _sessionCounter = counter;
    });
  }

  Future<void> _loadVolume() async {
    double volume = await SessionUtils.getReplayVolume();
    setState(() {
      _currentVolume = volume * 100; // Convert 0-1 to 0-100
      _initialVolume = _currentVolume;
    });
  }

  Future<void> _saveVolume() async {
    await SessionUtils.setReplayVolume(_currentVolume / 100); 
  }

  Future<void> _saveSoundCheckCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('soundCheckCounter', _soundCheckSessionCounter);
  }

  Future<void> _loadSoundCheckCounter() async {
    int counter = await SessionUtils.getSoundCheckSessionCounter();
    setState(() {
      _soundCheckSessionCounter = counter;
    });
  }

  void _startDecrementingTimer() {
    _isTimerRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _isTimerRunning) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else if (_remainingPlaybackTime > 0) {
          } else {
            _isTimerRunning = false;
            timer.cancel();
          }
        });
      }
    });
  }

  void _startPauseTimer() {
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_pauseCountdown > 0) {
          _pauseCountdown--;
        } else {
          _pauseTimer?.cancel();
          _isPaused = false;
          _adjustRemainingTime(); 
          _isTimerRunning = true;
          _startDecrementingTimer();
        }
      });
    });
  }

  void _playSounds() async {
    await _enableWakelock();
    setState(() {
      _audioPlayer.setVolume(_currentVolume / 100 * 0.1);
      _isPlaying = true;
      _countdown = _initialDelay;
      _isPaused = false;
      _pauseCountdown = 0;
      _sessionStartTime = DateTime.now();
    });
    _startDecrementingTimer();

    
    while (_countdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isPaused) return; 
    }
    _remainingPlaybackTime = 6000;

    while (_remainingPlaybackTime > 0) {
      if (_isPaused) {
        await Future.doWhile(() =>
            Future.delayed(const Duration(milliseconds: 100))
                .then((_) => _isPaused));
        continue; 
      }

      int currentWordIndex =
          (_remainingPlaybackTime - 1) ~/ 10 % _replayFlashcards.length;
      FlashCard card = _replayFlashcards[currentWordIndex];

      String soundFile = _userGroup == UserGroup.spokenWord
          ? card.spokenWordSound
          : card.neutralSound;
      _audioPlayer.play(AssetSource(soundFile));

      for (int j = 0; j < 10; j++) {
        if (_isPaused) break;
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          if (_remainingPlaybackTime > 0) {
            _remainingPlaybackTime--;
          }
        });
      }

      if (_remainingPlaybackTime % 600 == 0) {
        _replayFlashcards.shuffle(Random());
      }
    }

    setState(() {
      _isPlaying = false;
      _sessionCompleted = true;
    });

    _generateAndSaveReport();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pauseCountdown = 15 * 60; 
        _isTimerRunning = false;
        _startPauseTimer();
        _pausePressCount++;
        _pausePressTimes.add(DateTime.now());
      } else {
        _pauseTimer?.cancel();
        _adjustRemainingTime(); 
        _isTimerRunning = true;
        _startDecrementingTimer();
      }
    });
  }

  void _addDelay() {
    if (_isPlaying && _countdown > 0) {
      setState(() {
        _initialDelay += 900;
        _countdown += 900;
        _delayPressCount++;
        _delayPressTimes.add(DateTime.now());
        _delayStack.add(900);
      });
    }
  }

  void _addPauseTime() {
    setState(() {
      _pauseCountdown += 15 * 60;
      _pauseElongationCount++;
      _pauseElongationTimes.add(DateTime.now());
      _pauseStack.add(15 * 60);
    });
  }

  void _undoDelay() {
    if (_delayStack.isNotEmpty) {
      setState(() {
        int lastDelay = _delayStack.removeLast();
        _initialDelay -= lastDelay;
        _countdown -= lastDelay;
        _delayUndoCount++; 
      });
    }
  }

  void _undoPause() {
    if (_pauseStack.isNotEmpty) {
      setState(() {
        int lastPause = _pauseStack.removeLast();
        _pauseCountdown -= lastPause;
        _pauseUndoCount++;
      });
    }
  }

  void _updateVolume(double newVolume) {
    double roundedCurrentVolume = _currentVolume.roundToDouble();
    double roundedNewVolume = newVolume.roundToDouble();

    if (roundedNewVolume != roundedCurrentVolume) {
      DateTime timestamp = DateTime.now();
      _volumeChanges.add({
        'timestamp': timestamp,
        'oldVolume': roundedCurrentVolume,
        'newVolume': roundedNewVolume,
      });
      setState(() {
        _currentVolume = roundedNewVolume;
      });
      _audioPlayer.setVolume((roundedNewVolume / 100) * 0.1);
      _saveVolume();
    }
  }

  void _performSoundCheck() async {
    await _enableWakelock();
    setState(() {
      _isSoundCheckActive = true;
      _soundCheckCounter = 0;
      _soundCheckCountdown = 60;
      _nextSoundCountdown = 10;
    });

    _startNextSoundTimer();

    for (var sound in _soundCheckFiles) {
      if (!_isSoundCheckActive) break;
      await _audioPlayer.play(AssetSource(sound));
      _audioPlayer.setVolume(_currentVolume / 100 * 0.1);

      for (int i = 0; i < 10; i++) {
        if (!_isSoundCheckActive) break;
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _soundCheckCountdown--;
        });
      }

      _soundCheckCounter++;
      setState(() {
        _nextSoundCountdown = 10;
      });
    }

    if (_isSoundCheckActive) {
      _endSoundCheck();
    }
  }

  void _endSoundCheck() async {
    setState(() {
      _isSoundCheckActive = false;
      _initialVolume = _currentVolume;
    });

    await SessionUtils.incrementSoundCheckSessionCounter();
    await _saveVolume();

    _soundCheckSessionCounter = await SessionUtils.getSoundCheckSessionCounter();

    String report =
        'Sound Check Session $_soundCheckSessionCounter at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())} - '
        'Volume set to ${_currentVolume.round()}% - '  // Fixed - just use the direct value
        'Duration: ${60 - _soundCheckCountdown} seconds\n\n';
    await SessionUtils.writeReportToFile(report);

    await _disableWakelock();
}

  void _adjustRemainingTime() {
    setState(() {
      _remainingPlaybackTime = (_remainingPlaybackTime ~/ 10) * 10;
      if (_remainingPlaybackTime < 0) _remainingPlaybackTime = 0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying && _remainingPlaybackTime > 0 && !_reportGenerated) {
        _generateAndSaveReport(canceled: true);
        _wasSessionCanceled = true;
        _reportGenerated = true;
      }
      _timer?.cancel();
      _pauseTimer?.cancel();
      _audioPlayer.stop();
      Wakelock.disable();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasSessionCanceled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCancellationDialog();
        });
      }
    }
  }

  void _startNextSoundTimer() {
    _nextSoundTimer?.cancel();
    _nextSoundTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_nextSoundCountdown > 0) {
          _nextSoundCountdown--;
        } else {
          _nextSoundCountdown = 10;
        }
      });
    });
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text('Replay Session Canceled',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            content: Text(
              'Your replay session was canceled because you left the app. Please start a new session when you\'re ready.',
              style: TextStyle(color: Colors.black),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop(); 
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateAndSaveReport({bool canceled = false}) async {
    if (_reportGenerated) return;
    await SessionUtils.incrementReplaySessionCounter();
    _sessionCounter++;

    DateTime sessionEndTime = DateTime.now();
    Duration totalDuration = sessionEndTime.difference(_sessionStartTime!);

    String report = 'Replay Session Report $_sessionCounter\n';
    report +=
        'Session started at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_sessionStartTime!)}\n';
    report +=
        'Session ended at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(sessionEndTime)}\n';
    report +=
        'Total session duration: ${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m ${totalDuration.inSeconds % 60}s\n';
    report += 'Initial volume set to: ${_initialVolume.round()}%\n';

    report += 'Total delay presses: $_delayPressCount\n';
    if (_delayPressTimes.isNotEmpty) {
      report += 'Time Stamps Delay presses:\n';
      for (int i = 0; i < _delayPressTimes.length; i++) {
        report +=
            'Press ${i + 1} at ${DateFormat('HH:mm:ss').format(_delayPressTimes[i])}\n';
      }
    } else {
      report += 'No delay presses recorded.\n';
    }

    report += 'Total Pause presses: $_pausePressCount\n';
    if (_pausePressTimes.isNotEmpty) {
      report += 'Time Stamps Pause presses:\n';
      for (int i = 0; i < _pausePressTimes.length; i++) {
        report +=
            'Press ${i + 1} at ${DateFormat('HH:mm:ss').format(_pausePressTimes[i])}\n';
      }
    } else {
      report += 'No pause presses recorded.\n';
    }

    report += 'Total Pause elongations: $_pauseElongationCount\n';
    if (_pauseElongationTimes.isNotEmpty) {
      report += 'Time Stamps Pause elongations:\n';
      for (int i = 0; i < _pauseElongationTimes.length; i++) {
        report +=
            'Elongation ${i + 1} at ${DateFormat('HH:mm:ss').format(_pauseElongationTimes[i])}\n';
      }
    } else {
      report += 'No pause elongations recorded.\n';
    }

    report += 'Total delay undos: $_delayUndoCount\n';
    report += 'Total pause undos: $_pauseUndoCount\n';

    report += 'Volume changes:\n';
    for (var change in _volumeChanges) {
      report +=
          'Changed at ${DateFormat('HH:mm:ss').format(change['timestamp'])} - '
          'Volume changed from ${change['oldVolume'].round()}% to ${change['newVolume'].round()}%\n';
    }

    if (canceled) {
      report +=
          'Session canceled at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}\n\n';
    } else {
      report +=
          'Session completed at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}\n\n';
    }

    await SessionUtils.writeReportToFile(report);
    _reportGenerated = true;
  }

  Widget _buildWarningIconBox(BuildContext context) {
    return GestureDetector(
      onTap: () => _showWarningDialog(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Color(0xFFFF9050), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF9050), size: 40),
            SizedBox(width: 25),
            Icon(Icons.smartphone, color: Color(0xFFFF9050), size: 30),
            Icon(Icons.volume_up, color: Color(0xFFFF9050), size: 30),
            Icon(Icons.arrow_upward, color: Color(0xFFFF9050), size: 30),
            SizedBox(width: 25),
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.power_settings_new,
                    color: Color(0xFFFF9050), size: 30),
                Icon(Icons.close, color: Color(0xFFFF9050), size: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialButtons() {
    return Padding(
      padding: const EdgeInsets.only(
          top: 20.0), // Add space between icon bar and buttons
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLargeButton(
            icon: Icons.volume_up,
            label: 'Volume\nCheck',
            onPressed: _performSoundCheck,
          ),
          SizedBox(width: 20), 
          _buildLargeButton(
            icon: Icons.nightlight_round,
            label: 'Go to\nBed',
            onPressed: _playSounds,
          ),
        ],
      ),
    );
  }

  Widget _buildLargeButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      height: 160,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(16), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60),
            SizedBox(height: 10), 
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16), 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundCheckUI() {
    return Column(
      children: [
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCountdownDisplay("Remaining time:", _soundCheckCountdown),
            _buildCountdownDisplay("Next sound in:", _nextSoundCountdown),
          ],
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _endSoundCheck,
          child: Text('Save volume & quit', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(16),
            minimumSize: Size(200, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownDisplay(String label, int time) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 16,
          ),
        ),
        Text(
          _formatTime(time),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDelayUI() {
    return Column(
      children: [
        Text(
          'Sounds playing in:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 20,
          ),
        ),
        Text(
          _formatTime(_countdown),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 64,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _addDelay,
          child: Text('Add 15 Minutes', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(200, 60),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _canUndoDelay ? _undoDelay : null,
          child: Icon(Icons.undo, size: 30),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(16),
            minimumSize: Size(60, 60),
          ),
        ),
      ],
    );
  }

  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: Text(
            "Please keep your phone volume at 50% when using the app and only use the app internal volume controls.\n\n"
            "Please do not exit the app or lock your phone during active flashcard or replay sessions.",
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackUI() {
    if (!_isPlaying && _sessionCompleted) {  
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.secondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Replay Session Completed Successfully',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'You can now safely return to the home screen.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Text(
          'Remaining recueing time:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 20,
          ),
        ),
        Text(
          _formatTime(_remainingPlaybackTime),
          style: TextStyle(
            color: _isPaused
                ? Colors.grey
                : Theme.of(context).colorScheme.onBackground,
            fontSize: 64,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_isPaused)
          Text(
            'Pause: ${_formatTime(_pauseCountdown)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isPaused ? _addPauseTime : _togglePause,
          child: Text(_isPaused ? 'Add 15 Minutes' : 'Pause for 15 Minutes',
              style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(200, 60),
          ),
        ),
        SizedBox(height: 10),
        if (_isPaused)
          ElevatedButton(
            onPressed: _canUndoPause ? _undoPause : null,
            child: Icon(Icons.undo, size: 30),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(16),
              minimumSize: Size(60, 60),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 16, bottom: 16),
        child: FloatingActionButton(
          mini: true,
          child: Icon(Icons.help_outline, color: Colors.black),
          onPressed: _showHelpDialog,
        ),
      ),
    );
  }

  @override
    Widget build(BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          if (!_isPlaying && !_sessionCompleted) {
            return true;
          }
          
          // Handle active session case
          if (_isPlaying && _remainingPlaybackTime > 0 && !_reportGenerated) {
            await _generateAndSaveReport(canceled: true);
            return true;
          }

          if (_sessionCompleted) {
            bool shouldPop = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Leave Session?', style: TextStyle(color: Colors.black)),
                content: Text('Are you sure you want to exit the replay screen?', 
                  style: TextStyle(color: Colors.black)),
                actions: [
                  TextButton(
                    child: Text('No', style: TextStyle(color: Colors.black)),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: Text('Yes', style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      _disableWakelock();
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
            ) ?? false;
            return shouldPop;
          }
          
          return false;
        },
        child: Scaffold(
        appBar: AppBar(
          title: Text('Replay',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onBackground)),
          backgroundColor: Theme.of(context).colorScheme.background,
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildWarningIconBox(context),
              if (_isSoundCheckActive || (_isPlaying && _countdown == 0))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volume_mute,
                        color: Theme.of(context).colorScheme.onBackground,
                        size: 24,
                      ),
                      Expanded(
                        child: Slider(
                          value: _currentVolume,
                          min: 0.0,
                          max: 100.0,
                          divisions: 100,
                          label: _currentVolume.round().toString(),
                          onChanged: (double value) {
                            _updateVolume(value);
                          },
                        ),
                      ),
                      Icon(
                        Icons.volume_up,
                        color: Theme.of(context).colorScheme.onBackground,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isPlaying && !_isSoundCheckActive && !_sessionCompleted)
                          _buildInitialButtons(),
                        if (_isSoundCheckActive) _buildSoundCheckUI(),
                        if (_isPlaying && _countdown > 0) _buildDelayUI(),
                        if ((_isPlaying && _countdown == 0) || _sessionCompleted) _buildPlaybackUI(),
                      ]
                    ),
                  ),
                ),
              ),
              _buildHelpButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nextSoundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _disableWakelock(); 
    super.dispose();
  }
}
