import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'webview_page.dart'; // Import the new WebView page file
import 'dart:async';

void main() => runApp(WebViewDemo());

class WebViewDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView Demo',
      home: WebViewHomePage(),
    );
  }
}

class WebViewHomePage extends StatefulWidget {
  @override
  _WebViewHomePageState createState() => _WebViewHomePageState();
}

class _WebViewHomePageState extends State<WebViewHomePage> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Enter URL',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                String url = _urlController.text;
                // should be edited
                if (!url.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebViewPage(
                          url:
                              'https://drive.google.com/file/d/1q3Z6SJxVZV6UJsRoWf37sMjlWg3LMdyi/view'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a URL')));
                }
              },
              child: Text('Go'),
            ),
          ],
        ),
      ),
    );
  }
}
