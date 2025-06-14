import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class NameMappingService extends ChangeNotifier {
  static final NameMappingService instance = NameMappingService._internal();

  NameMappingService._internal();

  final Map<String, String> _mapping = {};

  Future<void> load() async {
    final file = await _getFile();
    if (await file.exists()) {
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents);
      _mapping.clear();
      _mapping.addAll(Map<String, String>.from(decoded));
      notifyListeners();
    }
  }

  Future<void> save() async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(_mapping));
  }

  String? getName(String id) => _mapping[id];

  void setName(String id, String name) {
    _mapping[id] = name;
    save();
    notifyListeners();
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/name_mapping.json');
  }
}