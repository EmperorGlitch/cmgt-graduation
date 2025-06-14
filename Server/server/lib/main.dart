import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'networking.dart';
import 'client_list.dart';
import 'video_control_panel.dart';
import 'video_repository.dart';
import 'name_mapping_service.dart';

final networkingManager = WebSocketManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  networkingManager.start();
  await NameMappingService.instance.load();

  final videoRepo = VideoRepository();
  await videoRepo.init();

  runApp(
    ChangeNotifierProvider<VideoRepository>.value(
      value: videoRepo,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _version.isNotEmpty
        ? 'Content Playback Control Center. (ver. $_version)'
        : 'Content Playback Control Center.';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            titleText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          toolbarHeight: 40,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: VideoControlPanel(manager: networkingManager),
            ),
            const Divider(height: 1),
            Expanded(child: ClientList(manager: networkingManager)),
          ],
        ),
      ),
    );
  }
}
