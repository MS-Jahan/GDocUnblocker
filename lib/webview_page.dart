import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage({this.url = 'https://www.example.com'}); // Default URL

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView'),
      ),
      body: WebView(
        debuggingEnabled: true,
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: widget.url,
        onWebViewCreated: (controller) {
          _controller = controller;
          _loadLocalJs();
        },
        onPageFinished: (controller) {
          // Optionally, you can run JavaScript here if needed
          // _controller = controller;
          _loadLocalJs();
        },
      ),
    );
  }

  Future<void> _loadLocalJs() async {
    String jsContent =
        await DefaultAssetBundle.of(context).loadString('assets/script.js');
    _controller.runJavascript(jsContent);
  }
}
