import 'package:flutter/material.dart';

class CallableListItem extends StatefulWidget {
  final Widget avatar;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback onAvatarTap;
  final void Function(bool isVideo) onCall;

  const CallableListItem({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onAvatarTap,
    required this.onCall,
  });

  @override
  State<CallableListItem> createState() => _CallableListItemState();
}

class _CallableListItemState extends State<CallableListItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: GestureDetector(onTap: widget.onAvatarTap, child: widget.avatar),
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: widget.trailing,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.call, size: 18),
                        label: const Text('Audio'),
                        onPressed: () {
                          setState(() => _expanded = false);
                          widget.onCall(false);
                        },
                      ),
                      const SizedBox(width: 16),
                      ActionChip(
                        avatar: const Icon(Icons.videocam, size: 18),
                        label: const Text('Video'),
                        onPressed: () {
                          setState(() => _expanded = false);
                          widget.onCall(true);
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}