import 'package:flutter/material.dart';
import 'networking.dart';
import 'client_list_item.dart';

class ClientList extends StatelessWidget {
  final WebSocketManager manager;

  const ClientList({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                'Сlients (${manager.clients.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: manager.clients.length,
                itemBuilder: (context, index) {
                  final client = manager.clients[index];
                  return ClientListItem(clientInfo: client.info);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
