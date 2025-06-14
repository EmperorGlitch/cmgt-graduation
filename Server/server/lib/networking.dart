import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'client_info.dart';
import 'video_repository.dart';

class ClientConnection {
  final WebSocket socket;
  final ClientInfo info;

  ClientConnection(this.socket, this.info);
}

class WebSocketManager extends ChangeNotifier {
  final List<ClientConnection> clients = [];
  final videoRepository = VideoRepository();

  void start() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    print(
      'WebSocket server is listening on a ws://${server.address.address}:${server.port}',
    );

    await for (HttpRequest request in server) {

      if (WebSocketTransformer.isUpgradeRequest(request)) {

        final socket = await WebSocketTransformer.upgrade(request);

        final info = ClientInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          deviceType: 'Unknown',
          batteryLevel: 0,
        );

        final clientConnection = ClientConnection(socket, info);
        clients.add(clientConnection);

        notifyListeners();

        print('New VR-client connected with ID: ${info.id}');
        socket.add(jsonEncode({'type': 'welcome', 'clientId': info.id}));

        final resolvedVideos = await resolveVideos(
          videoRepository.videos,
        );

        if (resolvedVideos.isNotEmpty) {
          socket.add(
            jsonEncode({'type': 'video_list', 'videos': resolvedVideos}),
          );
        }

        socket.listen(
          (message) {
            _handleMessage(clientConnection, message);
          },
          onDone: () {
            _removeClientBySocket(socket);
          },
          onError: (error) {
            _removeClientBySocket(socket);
          },
        );
      } else {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.close();
      }
    }
  }

  void _handleMessage(ClientConnection clientConnection, String message) {
    print('Client: ${clientConnection.info.id} Message: $message');

    try {
      final data = jsonDecode(message);

      if (data is Map<String, dynamic>) {
        clientConnection.info.updateFromMap(data);
      }
    } catch (e) {
      print('Client: ${clientConnection.info.id} Error: $e');
    }
  }

  void _removeClientBySocket(WebSocket socket) {
    clients.removeWhere((c) => c.socket == socket);

    notifyListeners();

    print('Client has disconnected');
  }

  void sendCommandToAll(String command, String? video) {
    final data = {
      'type': 'command',
      'command': command,
      if (video != null) 'video': video,
    };
    final jsonString = jsonEncode(data);

    for (var client in clients) {
      client.socket.add(jsonString);
    }
    print('Command "$command" with video $video has been broadcast to all clients');
  }

  void sendCommandToClient(String clientId, String command, String? video) {
    final client = clients.firstWhere(
      (c) => c.info.id == clientId,
      orElse: () => throw Exception('Client not found'),
    );

    final data = {
      'type': 'command',
      'command': command,
      if (video != null) 'video': video,
    };

    client.socket.add(jsonEncode(data));

    print('Command "$command" has been send to client $clientId');
  }

  Future<List<Map<String, dynamic>>> resolveVideos(List<String> names) async {
    final uri = Uri.parse('http://192.168.177.91:4040/videos/find');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'names': names}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print("Request error in http://../videos/find: ${response.body}");
      return [];
    }
  }

  void broadcastVideoAdded(Map<String, dynamic> videoData) {
    final message = jsonEncode({'type': 'video_list', 'videos': videoData});

    for (final client in clients) {
      client.socket.add(message);
    }

    print("Video list has been broadcast to all clients: ${videoData['name']}");
  }
}