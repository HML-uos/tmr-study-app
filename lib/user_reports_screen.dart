import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'session_utils.dart';
import 'login_screen.dart';

class UserReportsScreen extends StatelessWidget {
  const UserReportsScreen({Key? key}) : super(key: key);

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Area',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              'This is the report area of the app. Congratulations, if you are able to access this area it means that you are almost done with your participation in the study!\n\n'
              'To finalize your participation you only need to hand in your usage behavior report. To do this click on "Copy report" - a pop up on the bottom of the screen will inform you that the report contents have been copied to your clipboard.\n\n'
              'Do not edit this copied report in any way!\n\n'
              'Once you have your report in your clipboard, click the "Final Survey" button to be forwarded to the report hand in survey. There you can paste in your report and are then finished with the study.',
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
        title: Text('Reports',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 80,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Congratulations!\n\n',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        TextSpan(
                          text: 'You have completed all learning sessions and vocabulary tests and are therefore almost done with your participation in the study. Please use the button below to copy your usage behavior report to your clipboard. Use the other button to get to the final survey, where you can paste in your report.\n\n'
                              'Thank you so much for your participation!',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLargeButton(
                        context: context,
                        icon: Icons.content_copy,
                        label: 'Copy report',
                        onPressed: () => _copyReportsToClipboard(context),
                      ),
                      const SizedBox(width: 20),
                      _buildLargeButton(
                        context: context,
                        icon: Icons.assignment,
                        label: 'Final Survey',
                        onPressed: () => _openFinalSurvey(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      height: 65,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _copyReportsToClipboard(BuildContext context) async {
    String report = await SessionUtils.readReportFile();
    await Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard')),
    );
  }

  void _openFinalSurvey(BuildContext context) async {
    final Uri url = Uri.parse('https://survey.academiccloud.de/index.php/175925?lang=en');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch survey link')),
      );
    }
  }
}
