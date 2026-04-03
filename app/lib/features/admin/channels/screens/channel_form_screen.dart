import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../platforms/providers/platform_provider.dart';
import '../../platforms/data/platform_model.dart';

class ChannelFormScreen extends ConsumerStatefulWidget {
  final String platformId;
  final String platformName;
  final Channel? channel;

  const ChannelFormScreen({
    super.key,
    required this.platformId,
    required this.platformName,
    this.channel,
  });

  @override
  ConsumerState<ChannelFormScreen> createState() => _ChannelFormScreenState();
}

class _ChannelFormScreenState extends ConsumerState<ChannelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _handleController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel?.name ?? '');
    _handleController = TextEditingController(text: widget.channel?.handle ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final provider = ref.read(platformProvider.notifier);
      final handleValue = _handleController.text.trim();
      final finalHandle = handleValue.startsWith('@') ? handleValue : '@$handleValue';

      if (widget.channel == null) {
        await provider.createChannel(widget.platformId, _nameController.text.trim(), finalHandle);
      } else {
        await provider.updateChannel(widget.channel!.id, widget.platformId, _nameController.text.trim(), finalHandle);
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.channel == null ? 'Channel created' : 'Channel updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.channel != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Channel' : 'New Channel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: widget.platformName,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Platform',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. My Awesome Channel',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Channel name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _handleController,
                decoration: const InputDecoration(
                  labelText: 'Handle',
                  border: OutlineInputBorder(),
                  hintText: '@handle',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Handle is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Channel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
