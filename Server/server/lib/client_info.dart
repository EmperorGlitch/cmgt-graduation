import 'package:flutter/foundation.dart';
import "name_mapping_service.dart";

class ClientInfo extends ChangeNotifier {
  String id;
  String name;
  String deviceType;
  double batteryLevel;
  String currentVideo;
  double currentTime;
  double totalDuration;
  String status;

  ClientInfo({
    required this.id,
    required this.deviceType,
    required this.batteryLevel,
    this.currentVideo = '',
    this.currentTime = 0.0,
    this.totalDuration = 0.0,
    this.status = 'Stop',
    String? name,
  }) : name = name ?? id;

  void updateFromMap(Map<String, dynamic> data) {
    bool changed = false;

    if (data['id'] != null && data['id'] != id) {
      id = data['id'];
      final nameMappingService = NameMappingService.instance;
      final mappedName = nameMappingService.getName(id);
      if (mappedName != null) {
        name = mappedName;
      } else {
        name = id;
      }
      changed = true;
    }
    if (data['deviceType'] != null && data['deviceType'] != deviceType) {
      deviceType = data['deviceType'];
      changed = true;
    }
    if (data['batteryLevel'] != null && batteryLevel != data['batteryLevel']) {
      batteryLevel = (data['batteryLevel'] as num).toDouble();
      changed = true;
    }
    if (data['currentVideo'] != null && data['currentVideo'] != currentVideo) {
      currentVideo = data['currentVideo'];
      changed = true;
    }
    if (data['currentTime'] != null &&
        currentTime != (data['currentTime'] as num).toDouble()) {
      currentTime = (data['currentTime'] as num).toDouble();
      changed = true;
    }
    if (data['totalDuration'] != null &&
        totalDuration != (data['totalDuration'] as num).toDouble()) {
      totalDuration = (data['totalDuration'] as num).toDouble();
      changed = true;
    }
    if (data['status'] != null && data['status'] != status) {
      status = data['status'];
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
}
