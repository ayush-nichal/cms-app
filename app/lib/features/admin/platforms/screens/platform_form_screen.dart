import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/platform_provider.dart';
import '../data/platform_model.dart';

class PlatformFormScreen extends ConsumerStatefulWidget {
  final Platform? platform;

  const PlatformFormScreen({super.key, this.platform});

  @override
  ConsumerState<PlatformFormScreen> createState() => _PlatformFormScreenState();
}

class _PlatformFormScreenState extends ConsumerState<PlatformFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.platform?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final provider = ref.read(platformProvider.notifier);
      if (widget.platform == null) {
        await provider.createPlatform(_nameController.text.trim());
      } else {
        await provider.updatePlatform(widget.platform!.id, _nameController.text.trim());
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.platform == null ? 'Platform created' : 'Platform updated')),
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
    final isEdit = widget.platform != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Platform' : 'New Platform'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Platform Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. YouTube',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
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
                    : const Text('Save Platform'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
