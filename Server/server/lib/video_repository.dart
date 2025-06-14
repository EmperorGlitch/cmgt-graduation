import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class VideoRepository extends ChangeNotifier {
  List<String> _videos = [];
  File? _videoFile;

  List<String> get videos => List.unmodifiable(_videos);

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _videoFile = File('${directory.path}/videos.json');

    if (await _videoFile!.exists()) {
      final content = await _videoFile!.readAsString();
      _videos = List<String>.from(jsonDecode(content));
    } else {
      await _save();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await _videoFile!.writeAsString(jsonEncode(_videos));
  }

  void addVideo(String videoName) {
    if (!_videos.contains(videoName)) {
      _videos.add(videoName);
      _save();
      notifyListeners();
    }
  }

  void removeVideo(String videoName) {
    _videos.remove(videoName);
    _save();
    notifyListeners();
  }
}
