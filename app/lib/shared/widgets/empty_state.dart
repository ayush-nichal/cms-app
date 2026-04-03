import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  factory EmptyState.noPlatforms(VoidCallback? onAction) => EmptyState(
    icon: Icons.layers_clear,
    title: 'No Platforms',
    subtitle: 'Get started by configuring a new platform.',
    actionLabel: 'Add Platform',
    onAction: onAction,
  );

  factory EmptyState.noChannels(VoidCallback? onAction) => EmptyState(
    icon: Icons.tv_off,
    title: 'No Channels',
    subtitle: 'Add a channel to begin assigning content.',
    actionLabel: 'Add Channel',
    onAction: onAction,
  );

  factory EmptyState.noSchedules(VoidCallback? onAction) => EmptyState(
    icon: Icons.event_busy,
    title: 'No pending schedules',
    subtitle: 'Your content calendar is looking a bit empty.',
    actionLabel: 'Create Schedule',
    onAction: onAction,
  );

  factory EmptyState.noUsers(VoidCallback? onAction) => EmptyState(
    icon: Icons.group_off,
    title: 'No Users Found',
    subtitle: 'Invite users to manage your content.',
    actionLabel: 'Add User',
    onAction: onAction,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
