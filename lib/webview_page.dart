import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String selectedScript;

  const WebViewPage(
      {super.key, this.url = 'https://www.example.com',
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
        title: const Text('GDocUnblocker WebView'),
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
