import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


enum UserGroup { spokenWord, neutralSound }

class SessionUtils {
  static Future<int> getFlashCardSessionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('flashCardSessionCounter') ?? 0;
  }

  static Future<int> getReplaySessionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('replaySessionCounter') ?? 0;
  }

  static Future<int> getSoundCheckSessionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('soundCheckCounter') ?? 0;
  }

  static Future<void> incrementFlashCardSessionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCounter = prefs.getInt('flashCardSessionCounter') ?? 0;
    await prefs.setInt('flashCardSessionCounter', currentCounter + 1);
  }

  static Future<void> incrementReplaySessionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCounter = prefs.getInt('replaySessionCounter') ?? 0;
    await prefs.setInt('replaySessionCounter', currentCounter + 1);
  }

  static Future<void> incrementSoundCheckSessionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCounter = prefs.getInt('soundCheckCounter') ?? 0;
    await prefs.setInt('soundCheckCounter', currentCounter + 1);
  }

  static Future<void> resetAllSessionCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flashCardSessionCounter', 0);
    await prefs.setInt('replaySessionCounter', 0);
    await prefs.setInt('soundCheckCounter', 0);
  }

  static Future<void> writeReportToFile(String report) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/combined_report.txt');
      await file.writeAsString(report, mode: FileMode.append);
      print('Report saved to: ${file.path}');
    } catch (e) {
      print('Error writing to file: $e');
    }
  }

  static Future<String> readReportFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/combined_report.txt');
      if (await file.exists()) {
        String contents = await file.readAsString();
        String hash = _hashReport(contents);
        return '$contents\n\nReport Hash: $hash';
      } else {
        return 'No reports available';
      }
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  static String _hashReport(String report) {
    var bytes = utf8.encode(report);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> setUserGroup(UserGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userGroup', group.index);
  }

  static Future<void> deleteAllReports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/combined_report.txt');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting reports: $e');
    }
  }

  static Future<UserGroup> getUserGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final groupIndex = prefs.getInt('userGroup');
    return groupIndex != null ? UserGroup.values[groupIndex] : UserGroup.spokenWord;
  }

  static Future<double> getReplayVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('replayVolume') ?? 1.0;
  }

  static Future<void> setReplayVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('replayVolume', volume);
  }

  static Future<double> getFlashCardVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('flashCardVolume') ?? 1.0;
  }

  static Future<void> setFlashCardVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('flashCardVolume', volume);
  }
  
}
