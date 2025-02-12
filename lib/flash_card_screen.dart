import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'session_utils.dart';
import 'flashcard_data.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title,});

  final String title; 

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _showFrontSide = true;
  int _currentCardIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _nextCardButtonEnabled = false;
  double _flashCardVolume = 1.0;
  final List<Map<String, dynamic>> _volumeChanges = [];
  bool _flipCardButtonEnabled = true;
  bool _reportGenerated = false;
  bool _wasSessionCanceled = false;

  late List<FlashCard> _randomizedFlashCards;
  late AnimationController _animationController;
  late Animation<Offset> _flyInAnimation;

  // Tracking variables
  late DateTime _sessionStartTime;
  late DateTime _cardStartTime;
  final List<Duration> _cardDurations = [];

  // Persistent session counter
  int _sessionCounter = 0;

  bool _isFirstCard = true;
  late UserGroup _userGroup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUserGroup();
    _initializeAnimation();
    _sessionStartTime = DateTime.now();
    _cardStartTime = DateTime.now();
    _loadSessionCounter();
    _loadFlashCardVolume();
    _reportGenerated = false;
    _checkForCanceledSession();
  }

  Future<void> _loadFlashCardVolume() async {
    double volume = await SessionUtils.getFlashCardVolume();
    setState(() {
      _flashCardVolume = volume;
    });
    _audioPlayer.setVolume(_flashCardVolume);
  }

  void _initializeUserGroup() async {
    _userGroup = await SessionUtils.getUserGroup();
    _randomizeCards();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flyInAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadSessionCounter() async {
    int counter = await SessionUtils.getFlashCardSessionCounter();
    setState(() {
      _sessionCounter = counter;
    });
  }

  Future<void> _checkForCanceledSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool wasSessionCanceled = prefs.getBool('wasSessionCanceled') ?? false;
    if (wasSessionCanceled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Session Canceled', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              content: Text(
                'Your previous session was canceled because you left the app. Please start a new session.',
                style: TextStyle(color: Colors.black),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      });
      await prefs.setBool('wasSessionCanceled', false);
    }
  }

  Future<void> _setCanceledSessionFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wasFlashCardSessionCanceled', true);
  }

  void _updateFlashCardVolume(double newVolume) {
    if (newVolume != _flashCardVolume) {
      DateTime timestamp = DateTime.now();
      _volumeChanges.add({
        'timestamp': timestamp,
        'oldVolume': _flashCardVolume,
        'newVolume': newVolume,
      });
      setState(() {
        _flashCardVolume = newVolume;
      });
      _audioPlayer.setVolume(_flashCardVolume);
      SessionUtils.setFlashCardVolume(_flashCardVolume);
    }
  }

  void _randomizeCards() {
    List<FlashCard> firstBlock = List.from(flashcards);
    List<FlashCard> secondBlock = List.from(flashcards);
    firstBlock.shuffle(Random());
    secondBlock.shuffle(Random());
    setState(() {
      _randomizedFlashCards = [...firstBlock, ...secondBlock];
    });
  }

  void _flipCard() async {
    if (!_flipCardButtonEnabled) return;

    setState(() {
      _flipCardButtonEnabled = false;
      _nextCardButtonEnabled = false;
    });

    FlashCard currentCard = _randomizedFlashCards[_currentCardIndex];
    String soundFile = _userGroup == UserGroup.spokenWord
        ? currentCard.spokenWordSound
        : currentCard.neutralSound;
    await _audioPlayer.setVolume(_flashCardVolume);
    await _audioPlayer.play(AssetSource(soundFile));

    setState(() {
      _showFrontSide = !_showFrontSide;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      if (_showFrontSide) {
        _flipCardButtonEnabled = true;
        _nextCardButtonEnabled = false;
      } else {
        _flipCardButtonEnabled = true;
        _nextCardButtonEnabled = true;
      }
    });
  }

  void _nextCard() async {
    if (!_nextCardButtonEnabled || _showFrontSide) return;

    setState(() {
      _flipCardButtonEnabled = false;
      _nextCardButtonEnabled = false;
    });

    _recordCardDuration();

    if (_currentCardIndex == _randomizedFlashCards.length - 1) {
      _endSession();
    } else {
      setState(() {
        _currentCardIndex++;
        _showFrontSide = true;
        _isFirstCard = false;
      });

      _animationController.forward(from: 0);
      _cardStartTime = DateTime.now();

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _flipCardButtonEnabled = true;
        _nextCardButtonEnabled = false;
      });
    }
  }

  void _recordCardDuration() {
    Duration cardDuration = DateTime.now().difference(_cardStartTime);
    _cardDurations.add(cardDuration);
  }

  void _endSession({bool canceled = false}) async {
    if (!_reportGenerated) {
      await SessionUtils.incrementFlashCardSessionCounter();
      _sessionCounter++;
      Duration totalDuration = DateTime.now().difference(_sessionStartTime);
      double averageCardDuration = _cardDurations.isNotEmpty
          ? _cardDurations.fold(Duration.zero, (a, b) => a + b).inSeconds /
              _cardDurations.length
          : 0;

      String report = 'Flash Card Session Report $_sessionCounter\n'
          'Session started: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_sessionStartTime)}\n'
          'Total time: ${totalDuration.inSeconds} seconds\n'
          'Average time per card: ${averageCardDuration.toStringAsFixed(2)} seconds\n'
          'Initial flash card volume: ${(_flashCardVolume * 100).round()}%\n'
          'Individual card times (seconds):\n';

      for (int i = 0; i < _cardDurations.length; i++) {
        report += 'Card ${i + 1}: ${_cardDurations[i].inSeconds}\n';
      }

      if (_volumeChanges.isNotEmpty) {
        report += 'Volume changes during session:\n';
        for (var change in _volumeChanges) {
          report +=
              'Changed at ${DateFormat('HH:mm:ss').format(change['timestamp'])} - '
              'Volume changed from ${(change['oldVolume'] * 100).round()}% to ${(change['newVolume'] * 100).round()}%\n';
        }
      }

      if (canceled) {
        report +=
            'Session canceled at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}\n\n';
      } else {
        report +=
            'Session completed at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}\n\n';
      }

      await SessionUtils.writeReportToFile(report);

      if (!canceled) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: Text('Session Complete',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                content: Text(
                  'Congratulations! You have completed your learning session for the day!\n\n'
                  'Please immediately proceed to the respective vocabulary test for this day via the button in the Learning & Sleeping Area',
                  style: TextStyle(color: Colors.black),
                ),
                actions: <Widget>[
                  TextButton(
                    child:
                        const Text('OK', style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.of(context).pop(); // Dismiss the dialog
                      Navigator.of(context).pop(); // Return to the home screen
                    },
                  ),
                ],
              ),
            );
          },
        );
        _reportGenerated = true;
      }
    }
  }

  Widget _buildCard() {
  return Card(
    color: _showFrontSide ? Theme.of(context).colorScheme.surface : Color(0xFFFF9050),
    elevation: 4.0,
    child: SizedBox(
      width: 300.0,
      height: 200.0,
      child: Center(
        child: Text(
          _showFrontSide
              ? _randomizedFlashCards[_currentCardIndex].front
              : _randomizedFlashCards[_currentCardIndex].back,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _showFrontSide ? Theme.of(context).colorScheme.onSurface : Color(0xFF102333),
              ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
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
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9050), size: 40),
          SizedBox(width: 25),
          Icon(Icons.smartphone, color: Color(0xFFFF9050), size: 30),
            Icon(Icons.volume_up, color: Color(0xFFFF9050), size: 30),
            Icon(Icons.arrow_upward, color: Color(0xFFFF9050), size: 30),
          SizedBox(width: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.power_settings_new, color: Color(0xFFFF9050), size: 30),
              Icon(Icons.close, color: Color(0xFFFF9050), size: 40),
            ],
          ),
        ],
      ),
    ),
  );
}

void _showWarningDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Info', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  @override
Widget build(BuildContext context) {

  return WillPopScope(
    onWillPop: () async {
      if (_currentCardIndex < _randomizedFlashCards.length - 1 && !_reportGenerated) {
        _generateCanceledSessionReport();
        _reportGenerated = true;
      }
      return true;
    },
    child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        ),
        body: Column(
          children: [
            _buildWarningIconBox(context),
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
                        value: _flashCardVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label: (_flashCardVolume * 100).round().toString(),
                        onChanged: (double value) {
                          _updateFlashCardVolume(value);
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
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildProgressBar("Progress", _currentCardIndex + 1, _randomizedFlashCards.length),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: _isFirstCard 
                            ? Offset.zero
                            : _flyInAnimation.value * MediaQuery.of(context).size.height / 2,
                          child: _buildCard(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showFrontSide ? 
                        (_flipCardButtonEnabled ? _flipCard : null) : 
                        (_nextCardButtonEnabled ? _nextCard : null),
                      child: Text(
                        _showFrontSide ? 'Flip Card' : 
                        (_currentCardIndex == _randomizedFlashCards.length - 1 ? 'End Session' : 'Next Card'),
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        minimumSize: Size(200, 60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
  );
}

Widget _buildProgressBar(String title, int current, int total) {
  return Row(
    children: [
      SizedBox(
        width: 80,
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 16,
          ),
        ),
      ),
      Expanded(
        child: LinearProgressIndicator(
          value: current / total,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
        ),
      ),
      SizedBox(width: 10),
      Text(
        '$current / $total',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 16,
        ),
      ),
    ],
  );
}


    void _generateCanceledSessionReport() {
    if (!_reportGenerated) {
      _endSession(canceled: true);
      _reportGenerated = true;
    }
  }

    @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_currentCardIndex < _randomizedFlashCards.length - 1 && !_reportGenerated) {
        _generateCanceledSessionReport();
        _reportGenerated = true;
        _wasSessionCanceled = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasSessionCanceled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCancellationDialog();
        });
      }
    }
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text('Session Canceled', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            content: Text(
              'Your session was canceled because you left the app. Please start a new session when you\'re ready.',
              style: TextStyle(color: Colors.black),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  Navigator.of(context).pop(); // Return to the home screen
                },
              ),
            ],
          ),
        );
      },
    );
  }

    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      _audioPlayer.dispose();
      _animationController.dispose();
      if (_currentCardIndex < _randomizedFlashCards.length - 1 &&
          !_reportGenerated) {
        _generateCanceledSessionReport();
      }
      super.dispose();
    }
  }
