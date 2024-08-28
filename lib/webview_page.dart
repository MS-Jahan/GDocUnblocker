import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class WebViewPage extends StatefulWidget {
  final String url;
  final String selectedScript;

  WebViewPage(
      {this.url = 'https://www.example.com',
      required this.selectedScript}); // Update constructor

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GDocUnblocker WebView'),
      ),
      body: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: widget.url,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onPageFinished: (controller) {
          _loadLocalJs();
        },
      ),
    );
  }

  Future<void> _loadLocalJs() async {
    String scriptFile = widget.selectedScript == '1'
        ? 'assets/script1-optimized.js'
        : 'assets/script2.js';
    String jsContent =
        await DefaultAssetBundle.of(context).loadString(scriptFile);
    _controller.runJavascript(jsContent);
  }
}
