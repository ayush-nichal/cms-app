import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../providers/schedule_provider.dart';
import '../data/schedule_model.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/utils/validators.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String channelId;
  final Schedule? schedule;

  const ScheduleFormScreen({super.key, required this.channelId, this.schedule});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String _contentType = 'post';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  
  File? _pickedFile;
  String? _currentMediaUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule?.title ?? '');
    _descController = TextEditingController(text: widget.schedule?.description ?? '');
    if (widget.schedule != null) {
      _contentType = widget.schedule!.contentType;
      _selectedDate = widget.schedule!.scheduledAt;
      _selectedTime = TimeOfDay.fromDateTime(widget.schedule!.scheduledAt);
      _currentMediaUrl = widget.schedule!.mediaUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime initDate = _selectedDate ?? today;
    if (initDate.isBefore(today)) {
      initDate = today;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        // If they pick today but current selected time is past, clear it to force a new pick
        if (_selectedTime != null) {
          final checkDt = DateTime(date.year, date.month, date.day, _selectedTime!.hour, _selectedTime!.minute);
          if (checkDt.isBefore(DateTime.now())) {
             _selectedTime = null;
          }
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      if (_selectedDate != null) {
        final now = DateTime.now();
        final selectedDt = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
          time.hour, time.minute,
        );
        if (selectedDt.isBefore(now)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a future time.')));
          return;
        }
      }
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _handleMediaSelection() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final XFile? file = _contentType == 'video' 
                    ? await _picker.pickVideo(source: ImageSource.gallery) 
                    : await _picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      _pickedFile = File(file.path);
                      _currentMediaUrl = null; 
                    });
                  }
                } catch(e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission denied or error: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo/video'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final XFile? file = _contentType == 'video' 
                    ? await _picker.pickVideo(source: ImageSource.camera) 
                    : await _picker.pickImage(source: ImageSource.camera);
                  if (file != null) {
                    setState(() {
                      _pickedFile = File(file.path);
                      _currentMediaUrl = null;
                    });
                  }
                } catch(e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission denied or error: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time')));
      return;
    }

    setState(() => _isUploading = true);

    String? finalMediaUrl = _currentMediaUrl;

    try {
      final uploadService = ref.read(mediaUploadServiceProvider);

      // If user replaced media, delete the old one
      if (widget.schedule?.mediaUrl != null && widget.schedule!.mediaUrl != _currentMediaUrl) {
         try {
           await uploadService.deleteMedia(widget.schedule!.mediaUrl!);
         } catch(e) {
           debugPrint('Could not delete old media: $e');
         }
      }

      if (_pickedFile != null) {
        finalMediaUrl = await uploadService.uploadMedia(_pickedFile!);
      }

      setState(() {
        _isUploading = false;
        _isLoading = true;
      });

      final scheduledAt = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );

      if (scheduledAt.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot schedule in the past. Please update the time.')));
        setState(() => _isUploading = false);
        return;
      }

      final req = CreateScheduleRequest(
        channelId: widget.channelId,
        title: _titleController.text.trim(),
        contentType: _contentType,
        description: _descController.text.trim(),
        mediaUrl: (finalMediaUrl == null || finalMediaUrl.isEmpty) ? null : finalMediaUrl,
        scheduledAt: scheduledAt,
      );

      if (widget.schedule == null) {
        await ref.read(scheduleProvider.notifier).createSchedule(req);
      } else {
        await ref.read(scheduleProvider.notifier).updateSchedule(widget.schedule!.id, req);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.schedule == null ? 'Schedule created' : 'Schedule updated')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      setState(() {
        _isUploading = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.schedule == null ? 'New Schedule' : 'Edit Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) {
                   final req = Validators.required(v, 'Title');
                   if (req != null) return req;
                   return Validators.maxLength(v, 100, 'Title');
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'post', label: Text('Post'), icon: Icon(Icons.image)),
                  ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.videocam)),
                ],
                selected: {_contentType},
                onSelectionChanged: (val) {
                  setState(() {
                    _contentType = val.first;
                    _pickedFile = null; 
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Attach Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_pickedFile == null && _currentMediaUrl == null)
                InkWell(
                  onTap: _handleMediaSelection,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Add photo or video', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _pickedFile != null 
                           ? (_contentType == 'post' 
                               ? Image.file(_pickedFile!, fit: BoxFit.cover) 
                               : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.play_circle_fill, size: 48, color: Colors.blue), Text(p.basename(_pickedFile!.path))])))
                           : (_contentType == 'post'
                               ? Image.network(_currentMediaUrl!, fit: BoxFit.cover)
                               : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.play_circle_fill, size: 48, color: Colors.blue), Text(p.basename(_currentMediaUrl!))])))
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _pickedFile = null;
                          _currentMediaUrl = null;
                        });
                      },
                    )
                  ],
                ),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                const Text('Uploading media...'),
                const SizedBox(height: 4),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null ? 'Pick Date' : DateFormat('MMM d, yyyy').format(_selectedDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime == null ? 'Pick Time' : _selectedTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isLoading || _isUploading) ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: (_isLoading || _isUploading) ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Schedule'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
