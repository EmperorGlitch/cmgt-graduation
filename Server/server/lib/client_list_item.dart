import 'package:flutter/material.dart';
import 'client_info.dart';
import 'name_mapping_service.dart';
import 'selection_manager.dart';

class ClientListItem extends StatelessWidget {
  final ClientInfo clientInfo;

  const ClientListItem({super.key, required this.clientInfo});

  Color _getBatteryColor(double batteryLevel) {
    if (batteryLevel >= 50) {
      return Colors.green[100]!;
    } else if (batteryLevel >= 20) {
      return Colors.yellow[100]!;
    } else {
      return Colors.red[100]!;
    }
  }

  ImageProvider _getDeviceIcon(String deviceType) {
    final lower = deviceType.toLowerCase();
    if (lower.contains('pico')) {
      return const AssetImage('assets/icons/pico.png');
    } else if (lower.contains('quest') || lower.contains('meta')) {
      return const AssetImage('assets/icons/oculus.png');
    } else {
      return const AssetImage('assets/icons/windows.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([clientInfo, SelectionManager.instance]),
      builder: (context, _) {
        final isSelected = SelectionManager.instance.isSelected(clientInfo.id);
        return GestureDetector(
          onTap: () {
            SelectionManager.instance.toggle(clientInfo.id);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[200]
              : _getBatteryColor(clientInfo.batteryLevel),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Image(
                  image: _getDeviceIcon(clientInfo.deviceType),
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameField(context),
                      Text(
                        clientInfo.deviceType,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildIconText(
                          Icons.battery_full,
                          '${clientInfo.batteryLevel.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(width: 8),
                        _buildIconText(
                          Icons.movie_creation_outlined,
                          clientInfo.currentVideo.isNotEmpty
                              ? clientInfo.currentVideo
                              : 'No video',
                        ),
                        const SizedBox(width: 8),
                        _buildIconText(Icons.timer, _formatTime(clientInfo)),
                        const SizedBox(width: 8),
                        _buildIconText(
                          Icons.play_circle_fill,
                          clientInfo.status,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameField(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    controller.text = clientInfo.name;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter name',
              border: InputBorder.none,
            ),
            onSubmitted: (newName) {
              if (newName.isNotEmpty && newName != clientInfo.name) {
                clientInfo.name = newName;
                NameMappingService.instance.setName(clientInfo.id, newName);
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            final newName = controller.text.trim();
            if (newName.isNotEmpty && newName != clientInfo.name) {
              clientInfo.name = newName;
              NameMappingService.instance.setName(clientInfo.id, newName);
            }
          },
        ),
      ],
    );
  }

  String _formatDuration(double seconds) {
    final int totalSeconds = seconds.floor();
    final int minutes = totalSeconds ~/ 60;
    final int secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTime(ClientInfo clientInfo) {
    if (clientInfo.totalDuration <= 0) {
      return _formatDuration(clientInfo.currentTime);
    }
    final remaining = clientInfo.totalDuration - clientInfo.currentTime;
    return '${_formatDuration(clientInfo.currentTime)}/${_formatDuration(clientInfo.totalDuration)}'
        ' (${_formatDuration(remaining)} left)';
  }

  Widget _buildIconText(IconData iconData, String text) {
    return Row(
      children: [
        Icon(iconData, size: 20, color: Colors.black87),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}
