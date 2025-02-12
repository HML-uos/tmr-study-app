import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'session_utils.dart';
import 'login_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Area',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              'This is the report area of the app. Congratulations, if you are able to access this area it means that you are almost done with your participation in the study!\n\n'
              'To finalize your participation you only need to hand in your usage behavior report. To do this click on "View reports" and then on "Copy to Clipboard" - a pop up on the bottom of the screen will inform you that the report contents have been copied to your clipboard.\n\n'
              'Do not edit this copied report in any way!\n\n'
              'Once you have your report in your clipboard, click the link at the top of this area to be forwarded to the report hand in survey. There you can paste in your report and are then finished with the study.',
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
            style:
                TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    const url = 'https://your-survey-link-here.com';
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not launch survey link')),
                      );
                    }
                  },
                  child: Text('Open Report Hand-in Survey'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String report = await SessionUtils.readReportFile();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Combined Reports',
                              style: TextStyle(color: Colors.black)),
                          content: SingleChildScrollView(
                            child: Text(report,
                                style: const TextStyle(color: Colors.black)),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Close',
                                  style: TextStyle(color: Colors.black)),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Copy to Clipboard',
                                  style: TextStyle(color: Colors.black)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: report));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Report copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('View Reports'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    bool confirmed = await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Deletion',
                                  style: TextStyle(color: Colors.black)),
                              content: const Text(
                                'Are you sure you want to delete all reports and reset all session counters?',
                                style: TextStyle(color: Colors.black),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.black)),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete and Reset',
                                      style: TextStyle(color: Colors.black)),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            );
                          },
                        ) ??
                        false;

                    if (confirmed) {
                      await SessionUtils.deleteAllReports();
                      await SessionUtils.resetAllSessionCounters();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'All reports have been deleted and all session counters have been reset')),
                      );
                    }
                  },
                  child: const Text('Delete All Reports and Reset Counters'),
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
}
