import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateNotifier {
  final BuildContext context;

  UpdateNotifier(this.context);

  Future<void> checkForUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion =
        "${packageInfo.version}+${packageInfo.buildNumber}";
    print("Current version: $currentVersion");

    // GitHub API URL to get the latest release
    const String url =
        'https://api.github.com/repos/MS-Jahan/GDocUnblocker/releases/latest';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        String latestVersion = jsonResponse['tag_name'];
        print("Latest version: $latestVersion");

        if (latestVersion != currentVersion) {
          _showUpdateDialog(latestVersion);
        }
      } else {
        print('Failed to fetch latest release info.');
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
  }

  void _showUpdateDialog(String latestVersion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: Text(
              'A new version ($latestVersion) is available. Would you like to update?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                const String url =
                    'https://github.com/MS-Jahan/GDocUnblocker/releases';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  // show a snackbar or handle the error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not launch $url'),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
