import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'webview_page.dart'; // Import the new WebView page file
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:path_provider/path_provider.dart';
import 'download_state.dart'; // Import the state model
import 'locator.dart';
import 'package:open_file/open_file.dart';
import 'update_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  setupLocator(); // Initialize the service locator

  // var server = await io.serve(_handlePostRequest, '127.0.0.1', 8080);
  // print('Server running on localhost:${server.port}');

  runApp(
    ChangeNotifierProvider.value(
      value: locator<DownloadState>(),
      child: GDocUnblocker(),
    ),
  );
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
    return Response.ok('Preflight OK', headers: _corsHeaders());
  }

  if (request.method == 'POST') {
    var contentType = request.headers['Content-Type'];
    var filename = request.headers['filename'];
    if (contentType != null && contentType.contains('application/json')) {
      try {
        var bytes = await request.read().toList();
        var pdfData = bytes.expand((element) => element).toList();

        String downloadPath = await _getDownloadPath();
        var filePath = '$downloadPath/${filename!}';
        var file = File(filePath);

        await file.writeAsBytes(pdfData);
        print('File saved successfully to ${filePath}');

        // Notify Flutter app via global state using get_it
        final downloadState = locator<DownloadState>();
        downloadState.setFilePath(filePath);

        return Response.ok('File saved successfully!', headers: _corsHeaders());
      } catch (e) {
        print('Error: $e');
        return Response(500,
            body: 'Error saving file', headers: _corsHeaders());
      }
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

class GDocUnblocker extends StatelessWidget {
  const GDocUnblocker({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'GDocUnblocker',
      home: WebViewHomePage(),
    );
  }
}

class WebViewHomePage extends StatefulWidget {
  const WebViewHomePage({super.key});

  @override
  _WebViewHomePageState createState() => _WebViewHomePageState();
}

class _WebViewHomePageState extends State<WebViewHomePage> {
  final _urlController = TextEditingController();
  String _selectedOption = '1'; // Default to "Faster (Recommended)"
  late HttpServer _server; // Reference to the server

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startServer();
    checkServer();
    _checkForUpdates();
  }

  @override
  void dispose() {
    // Close the server when the widget is disposed
    _server.close();
    print('Server stopped');
    super.dispose();
  }

  Future<void> _startServer() async {
    _server = await io.serve(_handlePostRequest, '127.0.0.1', 8080);
    print('Server running on localhost:${_server.port}');
  }

  void _checkForUpdates() {
    UpdateNotifier(context).checkForUpdate();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadState>(
      builder: (context, downloadState, child) {
        if (downloadState.filePath != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File downloaded successfully!'),
                action: SnackBarAction(
                  label: 'View Downloads',
                  onPressed: () {
                    // Navigate to the DownloadsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DownloadsPage(),
                      ),
                    );
                  },
                ),
              ),
            );
            // Clear path after showing snack bar
            Provider.of<DownloadState>(context, listen: false)
                .setFilePath(null);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.lock_open_rounded), // Add an icon here
                SizedBox(width: 8),
                Text('GDocUnblocker'),
              ],
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_open, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text('GDocUnblocker',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 24)),
                        ],
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              'Loading version...',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            );
                          } else if (snapshot.hasError) {
                            return Text(
                              'Error loading version',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            );
                          } else {
                            final version = snapshot.data!.version;
                            final buildNumber = snapshot.data!.buildNumber;
                            return Text(
                              'v$version+$buildNumber',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Downloads'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DownloadsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  onTap: () async {
                    const url = "https://github.com/MS-Jahan/GDocUnblocker";
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
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Enter a Google Drive PDF preview URL',
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  "Select unblock method:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: '1',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                        });
                      },
                    ),
                    Text('Faster (Recommended)'),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: '2',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                        });
                      },
                    ),
                    Text('Slower, Low Res, Use only if 1st one fails'),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  "Instructions:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Press 'Go' now and press 'Generate PDF' on the next page.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String url = _urlController.text;
                    // check if the string ends with ?hl=en
                    if (url.isNotEmpty) {
                      // if the URL has ?usp=sharing, remove it
                      url = url.replaceAll(RegExp(r'\?usp=sharing'), '');

                      if (!url.endsWith('?hl=en')) {
                        url += '?hl=en';
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (contexts) => WebViewPage(
                            url: url,
                            selectedScript:
                                _selectedOption, // Pass the selected option
                          ),
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
      },
    );
  }
}

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  Future<List<FileSystemEntity>> _listFilesInDirectory() async {
    final directory = await getDownloadsDirectory();
    return directory!.listSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.download), // Add an icon here
            SizedBox(width: 8),
            Text('Downloads'),
          ],
        ),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _listFilesInDirectory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading files'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No files found'));
          } else {
            final files = snapshot.data!;
            return ListView.builder(
              itemCount: files.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Download folder: ${files.first.parent.path}',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                } else {
                  final file = files[index - 1];
                  return ListTile(
                    leading: Icon(Icons.file_present), // Add an icon here
                    title: Text(file.path.split('/').last),
                    trailing: IconButton(
                      icon: Icon(Icons.open_in_new),
                      onPressed: () {
                        OpenFile.open(file.path);
                      },
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
