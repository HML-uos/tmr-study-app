import 'package:flutter/material.dart';
import 'flash_card_screen.dart';
import 'replay_screen.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  final String title;
  const HomeScreen({super.key, required this.title});

  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Info',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Learning & Sleeping Area',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              'This is the Learning & Sleeping area of the app.\n\n'
              'Learning.\n\n'
              'Under "Learning - Flashcards" you can start your daily flashcard session. Here you will learn the artificial words and their translations. While learning the cue sounds will play. You can control the flashcard volume directly in the app. Make sure to set your phone\'s volume to 50% and to only use the app integrated volume controls and do not close the app during an active session.\n\n'
              'Testing.\n\n'
              'With the buttons under "Vocabulary Test" you can quickly access your vocabulary surveys. Please make sure to always perform your daily vocabulary test directly after your flashcard learning session and choose the correct test for the day.\n\n'
              'Sleeping.\n\n'
              'Under "Sleeping - Replay" you initiate your nightly replay of the cue sounds. Perform a quick volume check every night to set up your volume to a comfortable level before falling asleep. Sounds play quieter in the replay as compared to the flash card area. You can still freely control the in app volume, even during nightly replay. Make sure to set your phone\'s volume to 50% and to only use the app integrated volume controls and do not close the app during an active session.\n\n'
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

  Future<void> _launchVocabTest(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.background,
      foregroundColor: Theme.of(context).colorScheme.onBackground,
    ),
    body: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
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
            ),
            SizedBox(height: 16), 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLargeButton(
                  context,
                  icon: Icons.flash_on,
                  label: 'Learning\nFlashcards',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Flashcards')),
                    );
                  },
                ),
                _buildLargeButton(
                  context,
                  icon: Icons.nightlight_round,
                  label: 'Sleeping\nReplay',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReplayScreen()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Vocabulary Tests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallButton(context, 'Day 1', () => _launchVocabTest('https://survey.academiccloud.de/index.php/917544?lang=en')),
                _buildSmallButton(context, 'Day 2', () => _launchVocabTest('https://survey.academiccloud.de/index.php/979582?lang=en')),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallButton(context, 'Day 3', () => _launchVocabTest('https://survey.academiccloud.de/index.php/884248?lang=en')),
                _buildSmallButton(
                  context, 
                  'Day 4', 
                  () => _launchVocabTest('https://survey.academiccloud.de/index.php/186968?lang=en'),
                  subtitle: 'No prior Flashcards!',
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            child: Icon(Icons.help_outline, color: Colors.black),
            onPressed: () => _showHelpDialog(context),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            child: Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLargeButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
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

  Widget _buildSmallButton(BuildContext context, String label, VoidCallback onPressed, {String? subtitle}) {
  return SizedBox(
    width: 160,
    height: 80,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}
}