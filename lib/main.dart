import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'webview_page.dart'; // Import the new WebView page file
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  // Start the local server
  var server = await io.serve(_handlePostRequest, '0.0.0.0', 8080);
  print('Server running on localhost:${server.port}');

  runApp(WebViewDemo());
}

// Function to get the app-specific download directory
Future<String> _getDownloadPath() async {
  final directory =
      await getDownloadsDirectory(); // Or use getExternalStorageDirectory() for broader access
  return directory!.path;
}

Future<Response> _handlePostRequest(Request request) async {
  print("Received request ${request.method}");
  if (request.method == 'OPTIONS') {
    // Handle preflight requests
    return Response.ok('Preflight OK', headers: _corsHeaders());
  }

  if (request.method == 'POST') {
    var contentType = request.headers['Content-Type'];
    var filename = request.headers['filename'];
    if (contentType != null && contentType.contains('application/json')) {
      try {
        // Parse and save the PDF file
        var bytes = await request.read().toList();
        var pdfData = bytes.expand((element) => element).toList();

        // Get the app-specific download directory
        String downloadPath = await _getDownloadPath();
        var filePath = '$downloadPath/${filename!}';
        var file = File(filePath);

        // Save the file
        await file.writeAsBytes(pdfData);

        // show a message in toast
        print('File saved successfully to ${filePath}');
      } catch (e) {
        print('Error: $e');
      }
      return Response.ok('File saved successfully!', headers: _corsHeaders());
    } else {
      return Response(400,
          body: 'Invalid content type', headers: _corsHeaders());
    }
  }
  return Response(405, body: 'Method Not Allowed', headers: _corsHeaders());
}
// a function to send post request and check if the local server is working

void checkServer() async {
  try {
    var client = HttpClient();
    var request = await client.getUrl(Uri.parse('http://localhost:8080'));

    // Close the request and get the response
    var response = await request.close();

    // Read the response and print it
    response.transform(const Utf8Decoder()).listen((content) {
      print('Server Response: $content');
    });

    // Check the response status code
    if (response.statusCode == 200) {
      print('Server is working.');
    } else {
      print('Server returned status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// CORS headers
Map<String, String> _corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers':
        'Origin, Content-Type, filename', // Add filename here
  };
}

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
    checkServer();
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
                              // "https://drive.google.com/file/d/1gfQpqfMScIsAeN0kpHG9QRPgMrxwppsQ/view?usp=sharing"),
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
