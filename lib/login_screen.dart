import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'session_utils.dart';
import 'user_reports_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  void _login() async {
  String password = _passwordController.text;
  if (password == 'xGa9') {
    await SessionUtils.setUserGroup(UserGroup.spokenWord);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen(title: 'Learning & Sleeping')),
    );
  } else if (password == 'ygB8') {
    await SessionUtils.setUserGroup(UserGroup.neutralSound);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen(title: 'Learning & Sleeping')),
    );
  } else if (password == 'reports') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  } else if (password == 'zPc7') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UserReportsScreen()),
    );
  } else {
    setState(() {
      _errorMessage = 'Invalid password. Please try again.';
    });
  }
}

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Welcome', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              'Welcome to the TMR Study App!\n\n'
              'Through this Login area you can access the different functionalities of the app - namely the main Learning & Sleeping area and later on the Report area.\n\n'
              'Please fill in the password that was provided to you in the Intro-Survey to access the Learning & Sleeping area. There you can start with your flashcard learning sessions and initiate the sound replay before going to sleep.\n\n'
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

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Login'),
      backgroundColor: Theme.of(context).colorScheme.background,
      foregroundColor: Theme.of(context).colorScheme.onBackground,
    ),
    body: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TMR Study App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,  // Uses the orange accent color
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Reminder: \n'
                  'Please always set your phone volume to 50% when using the app and only use the app internal volume slider to change your volume levels!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter your password from the Intro-Survey.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),  
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ],
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            child: Icon(Icons.help_outline, color: Colors.black),
            onPressed: _showHelpDialog,
          ),
        ),
      ],
    ),
  );
}
}