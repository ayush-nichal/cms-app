import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);

    return Scaffold(
      body: state.isLoading && state.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.users.isEmpty
              ? const Center(
                  child: Text(
                    'No users yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => notifier.loadUsers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      final isCreator = user.role == 'creator';

                      return Card(
                        color: user.isActive ? null : Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          onTap: () => context.push('/admin/users/${user.id}'),
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text('Edit User'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push('/admin/users/edit', extra: user);
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.delete, color: user.isActive ? Colors.red : Colors.grey),
                                      title: Text('Deactivate User', style: TextStyle(color: user.isActive ? Colors.red : Colors.grey)),
                                      onTap: user.isActive ? () async {
                                        Navigator.pop(context);
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => const ConfirmDialog(
                                            title: 'Deactivate User',
                                            message: 'Are you sure you want to deactivate this user? They will no longer be able to log in.',
                                            confirmText: 'Deactivate',
                                          ),
                                        );
                                        if (confirm == true) {
                                          notifier.softDeleteUser(user.id).catchError((e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                              );
                                            }
                                          });
                                        }
                                      } : null, // disable if already inactive
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: user.isActive ? Colors.blue.shade100 : Colors.grey.shade400,
                            child: Icon(Icons.person, color: user.isActive ? Colors.blue : Colors.grey),
                          ),
                          title: Text(
                            user.email,
                            style: TextStyle(
                              decoration: user.isActive ? null : TextDecoration.lineThrough,
                              color: user.isActive ? null : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Chip(
                                  label: Text(
                                    user.role.toUpperCase(),
                                    style: TextStyle(color: user.isActive ? (isCreator ? Colors.blue.shade900 : Colors.amber.shade900) : Colors.grey.shade700, fontSize: 10),
                                  ),
                                  backgroundColor: user.isActive ? (isCreator ? Colors.blue.shade100 : Colors.amber.shade100) : Colors.grey.shade300,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                if (user.assignments.isNotEmpty)
                                  Chip(
                                    label: Text(
                                      '${user.assignments.length} Channels',
                                      style: TextStyle(color: user.isActive ? Colors.black87 : Colors.grey.shade700, fontSize: 10),
                                    ),
                                    backgroundColor: user.isActive ? Colors.grey.shade200 : Colors.grey.shade300,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (!user.isActive) ...[
                                  const SizedBox(width: 8),
                                  const Text('INACTIVE', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/users/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
