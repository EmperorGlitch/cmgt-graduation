import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'selection_manager.dart';
import 'networking.dart';
import 'video_repository.dart';

class VideoControlPanel extends StatefulWidget {
  final WebSocketManager manager;

  const VideoControlPanel({super.key, required this.manager});

  @override
  _VideoControlPanelState createState() => _VideoControlPanelState();
}

class _VideoControlPanelState extends State<VideoControlPanel> {
  String? selectedVideo;

  @override
  void initState() {
    super.initState();
    final videos = Provider.of<VideoRepository>(context, listen: false).videos;
    if (videos.isNotEmpty) {
      selectedVideo = videos[0];
    }
  }

  void _showAddVideoDialog() {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add video'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Input video name.mp4'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;

            final networking = widget.manager;

            final resolvedList = await networking.resolveVideos([name]);
            if (resolvedList.isNotEmpty) {
              final resolved = resolvedList.first;

              Provider.of<VideoRepository>(context, listen: false).addVideo(name);
              setState(() {
                selectedVideo ??= name;
              });

              networking.broadcastVideoAdded(resolved);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Video "$name" was not found on Content Management Web-Service')),
              );
            }

            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

  void _showRemoveVideosDialog(List<String> videos) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove video'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return ListTile(
                    title: Text(video, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        Provider.of<VideoRepository>(
                          context,
                          listen: false,
                        ).removeVideo(video);
                        setState(() {
                          if (selectedVideo == video) {
                            final updated =
                                Provider.of<VideoRepository>(
                                  context,
                                  listen: false,
                                ).videos;
                            selectedVideo =
                                updated.isNotEmpty ? updated[0] : null;
                          }
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videos = Provider.of<VideoRepository>(context).videos;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child:
              videos.isEmpty
                  ? const Text(
                    'There are no available videos',
                    style: TextStyle(fontSize: 16),
                  )
                  : DropdownButtonFormField<String>(
                    value: selectedVideo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select video',
                      labelStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    dropdownColor: Colors.white,
                    items:
                        videos
                            .map(
                              (video) => DropdownMenuItem<String>(
                                value: video,
                                child: Text(
                                  video,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedVideo = value;
                      });
                    },
                  ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _showAddVideoDialog,
          tooltip: 'Add video',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed:
              videos.isEmpty ? null : () => _showRemoveVideosDialog(videos),
          tooltip: 'Remove video',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            if (selectedVideo != null) {
              if (SelectionManager.instance.hasSelection) {
                final selectedIds =
                    SelectionManager.instance.selectedIds.toList();
                for (var id in selectedIds) {
                  widget.manager.sendCommandToClient(
                    id,
                    'play',
                    selectedVideo!,
                  );
                }
                SelectionManager.instance.clear();
              } else {
                widget.manager.sendCommandToAll('play', selectedVideo!);
              }
            }
          },
          tooltip: 'Play',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () {
            if (SelectionManager.instance.hasSelection) {
              final selectedIds =
                  SelectionManager.instance.selectedIds.toList();
              for (var id in selectedIds) {
                widget.manager.sendCommandToClient(id, 'pause', '');
              }
              SelectionManager.instance.clear();
            } else {
              widget.manager.sendCommandToAll('pause', '');
            }
          },
          tooltip: 'Pause',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.stop),
          onPressed: () {
            if (SelectionManager.instance.hasSelection) {
              final selectedIds =
                  SelectionManager.instance.selectedIds.toList();
              for (var id in selectedIds) {
                widget.manager.sendCommandToClient(id, 'stop', '');
              }
              SelectionManager.instance.clear();
            } else {
              widget.manager.sendCommandToAll('stop', '');
            }
          },
          tooltip: 'Stop',
        ),
      ],
    );
  }
}
