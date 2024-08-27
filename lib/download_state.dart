import 'package:flutter/material.dart';

// In download_state.dart
class DownloadState extends ChangeNotifier {
  String? _filePath;

  String? get filePath => _filePath;

  void setFilePath(String? filePath) {
    _filePath = filePath;
    notifyListeners();
  }
}
