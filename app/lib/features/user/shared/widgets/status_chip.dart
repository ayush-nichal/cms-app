import 'package:flutter/material.dart';

class StatusChip extends StatefulWidget {
  final String status;
  final String? scheduleId;
  final bool isInteractive;
  final Function(String)? onStatusChanged;
  final bool isLoading;

  const StatusChip({
    super.key, 
    required this.status, 
    this.scheduleId,
    this.isInteractive = false, 
    this.onStatusChanged,
    this.isLoading = false,
  });

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip> {
  Color _getBgColor() {
    switch (widget.status) {
      case 'posted': return Colors.green.shade100;
      case 'not_posted': return Colors.red.shade100;
      default: return Colors.blue.shade100;
    }
  }

  Color _getTextColor() {
    switch (widget.status) {
      case 'posted': return Colors.green.shade900;
      case 'not_posted': return Colors.red.shade900;
      default: return Colors.blue.shade900;
    }
  }

  String _getLabel() {
    switch (widget.status) {
      case 'posted': return 'Posted';
      case 'not_posted': return 'Not Posted';
      default: return 'Scheduled';
    }
  }

  void _showStatusBottomSheet(BuildContext context) {
    if (!widget.isInteractive || widget.isLoading) return;
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['scheduled', 'posted', 'not_posted'].map((opt) {
              final isSelected = opt == widget.status;
              String txt = 'Scheduled';
              if (opt == 'posted') txt = 'Posted';
              if (opt == 'not_posted') txt = 'Not Posted';

              return ListTile(
                title: Text(txt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (opt != widget.status && widget.onStatusChanged != null) {
                    widget.onStatusChanged!(opt);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getLabel().toUpperCase(),
          style: TextStyle(fontSize: 10, color: _getTextColor(), fontWeight: FontWeight.bold),
        ),
        if (widget.isInteractive) ...[
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 14, color: _getTextColor()),
        ],
        if (widget.isLoading) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 10, 
            height: 10, 
            child: CircularProgressIndicator(strokeWidth: 2, color: _getTextColor())
          )
        ]
      ],
    );

    Widget chip = Chip(
      label: content,
      backgroundColor: _getBgColor(),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );

    if (widget.isInteractive) {
      return GestureDetector(
        onTap: () => _showStatusBottomSheet(context),
        child: chip,
      );
    }
    return chip;
  }
}
