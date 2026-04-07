import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../data/user_model.dart';
import 'add_assignment_sheet.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  final TextEditingController _callmebotController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  bool _isSavingCallMeBot = false;
  bool _isSavingWhatsapp = false;
  bool _obscureApiKey = true;

  @override
  void dispose() {
    _callmebotController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _saveCallMeBotKey(AppUser user) async {
    setState(() => _isSavingCallMeBot = true);
    try {
      await ref.read(userProvider.notifier).updateUser(
        user.id, 
        UpdateUserRequest(callmebotApiKey: _callmebotController.text.trim())
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key saved')));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSavingCallMeBot = false);
    }
  }

  void _saveWhatsapp(AppUser user) async {
    setState(() => _isSavingWhatsapp = true);
    try {
      await ref.read(userProvider.notifier).updateUser(
        user.id, 
        UpdateUserRequest(whatsappNumber: _whatsappController.text.trim())
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp saved')));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSavingWhatsapp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final user = state.users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => AppUser(id: '', email: 'Not Found', role: '', isActive: false, assignments: [])
    );

    if (user.id.isEmpty) return Scaffold(appBar: AppBar(title: const Text('User Not Found')));

    if (_callmebotController.text.isEmpty && user.callmebotApiKey != null) {
      _callmebotController.text = user.callmebotApiKey!;
    }
    if (_whatsappController.text.isEmpty && user.whatsappNumber != null) {
      _whatsappController.text = user.whatsappNumber!;
    }

    return Scaffold(
      appBar: AppBar(title: Text(user.email)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Info', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email}'),
                    const SizedBox(height: 4),
                    Text('Role: ${user.role.toUpperCase()}'),
                    const SizedBox(height: 4),
                    Text('Status: ${user.isActive ? "Active" : "Inactive"}', style: TextStyle(color: user.isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Channel Assignments', style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => AddAssignmentSheet(user: user),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Assign'),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (user.assignments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No assigned channels', style: TextStyle(color: Colors.grey))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: user.assignments.length,
                itemBuilder: (context, index) {
                  final assign = user.assignments[index];
                  return Dismissible(
                    key: Key(assign.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (_) => const ConfirmDialog(
                          title: 'Remove Assignment',
                          message: 'Are you sure you want to remove this user from the channel?',
                          confirmText: 'Remove',
                        )
                      );
                    },
                    onDismissed: (_) {
                      ref.read(userProvider.notifier).removeAssignment(user.id, assign.channelId).catchError((e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      });
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(assign.channelName),
                        subtitle: Text(assign.platformName),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Notification Settings', style: Theme.of(context).textTheme.titleLarge)),
                        const SizedBox(width: 8),
                        if (user.whatsappNumber != null && user.whatsappNumber!.isNotEmpty && user.callmebotApiKey != null && user.callmebotApiKey!.isNotEmpty)
                          FilledButton.tonalIcon(onPressed: (){}, icon: const Icon(Icons.notifications_active), label: const Text('Email + WhatsApp'), style: FilledButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900))
                        else
                          FilledButton.tonalIcon(onPressed: (){}, icon: const Icon(Icons.email), label: const Text('Email only'), style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Email (Primary)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mail),
                      title: Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Chip(
                      label: const Text('Email notifications active', style: TextStyle(fontSize: 12, color: Colors.green)),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide(color: Colors.green.shade200),
                    ),
                    const Divider(height: 32),
                    const Text('WhatsApp — optional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "The user must first send 'I allow callmebot to send me messages' to +34 644 58 49 28 on WhatsApp, then share the API key they receive.",
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (user.whatsappNumber != null && user.whatsappNumber!.isNotEmpty && user.callmebotApiKey != null && user.callmebotApiKey!.isNotEmpty)
                      Chip(
                        label: const Text('WhatsApp active', style: TextStyle(fontSize: 12, color: Colors.green)),
                        backgroundColor: Colors.green.shade50,
                        side: BorderSide(color: Colors.green.shade200),
                      )
                    else
                      Chip(
                        label: const Text('WhatsApp not configured', style: TextStyle(fontSize: 12, color: Colors.amber)),
                        backgroundColor: Colors.amber.shade50,
                        side: BorderSide(color: Colors.amber.shade200),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _whatsappController,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp Number (e.g. 919876543210)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixText: '+',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isSavingWhatsapp 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.save, color: Colors.blue),
                          onPressed: _isSavingWhatsapp ? null : () => _saveWhatsapp(user),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _callmebotController,
                            obscureText: _obscureApiKey,
                            decoration: InputDecoration(
                              labelText: 'CallMeBot API Key',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off, size: 20),
                                onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isSavingCallMeBot 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.save, color: Colors.blue),
                          onPressed: _isSavingCallMeBot ? null : () => _saveCallMeBotKey(user),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
