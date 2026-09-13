import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/call_logs/models/call_log_entry.dart';

class CallPermissions {
  static Future<bool> _request(CallType type) async {
    final permissions = <Permission>[
      Permission.microphone,
      if (type == CallType.video) Permission.camera,
    ];
    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted);
  }

  static Future<bool> _anyPermanentlyDenied(CallType type) async {
    final mic = await Permission.microphone.status;
    if (mic.isPermanentlyDenied) return true;
    if (type == CallType.video) {
      final cam = await Permission.camera.status;
      if (cam.isPermanentlyDenied) return true;
    }
    return false;
  }

  /// Requests mic (+ camera for video) permission. Returns true if the
  /// call should proceed. Shows a dialog with an "Open Settings" option
  /// if the user has permanently denied a permission.
  static Future<bool> ensure(BuildContext context, CallType type) async {
    final granted = await _request(type);
    if (granted) return true;

    if (await _anyPermanentlyDenied(type)) {
      if (!context.mounted) return false;
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission needed'),
          content: Text(
            type == CallType.video
                ? 'Microphone and camera access are required for video calls. Please enable them in Settings.'
                : 'Microphone access is required for calls. Please enable it in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (openSettings == true) await openAppSettings();
      return false;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == CallType.video
                ? 'Microphone and camera permission are needed to call.'
                : 'Microphone permission is needed to call.',
          ),
        ),
      );
    }
    return false;
  }
}
