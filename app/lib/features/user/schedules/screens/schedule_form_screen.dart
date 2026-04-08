import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import '../providers/schedule_provider.dart';
import '../data/schedule_model.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/content_type_translator.dart';
import '../../../../shared/design/design_tokens.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String platformName;
  final Schedule? schedule;

  const ScheduleFormScreen({super.key, required this.channelId, required this.platformName, this.schedule});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String _contentType = 'text_post';
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
    } else {
      _initializeSupportedContentType();
    }
  }

  void _initializeSupportedContentType() {
    const primitives = ['text_post', 'image_post', 'short_form_video', 'long_form_video', 'carousel_post'];
    for (var p in primitives) {
      if (ContentTypeTranslator.isSupported(p, widget.platformName)) {
        _contentType = p;
        break;
      }
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
                  final XFile? file = _contentType.contains('video') 
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
                  final XFile? file = _contentType.contains('video') 
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

      if (widget.schedule?.mediaUrl != null && widget.schedule!.mediaUrl != _currentMediaUrl) {
         try {
           await uploadService.deleteMedia(widget.schedule!.mediaUrl!);
         } catch(e) {}
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
    const primitives = ['text_post', 'image_post', 'short_form_video', 'long_form_video', 'carousel_post'];
    final isEditMode = widget.schedule != null;

    NavigationBar userNavBar() {
      return NavigationBar(
        backgroundColor: surfaceWhite,
        indicatorColor: const Color(0xFFE8F0FB),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/user/schedules');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: onSurfaceVar),
            selectedIcon: Icon(Icons.grid_view_rounded, color: primary),
            label: 'Schedules',
          ),
          NavigationDestination(
            icon: Icon(Icons.subscriptions_outlined, color: onSurfaceVar),
            selectedIcon: Icon(Icons.subscriptions_rounded, color: primary),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded, color: onSurfaceVar),
            selectedIcon: Icon(Icons.people_rounded, color: primary),
            label: 'Profile',
          ),
        ],
      );
    }

    TextStyle labelStyle() => GoogleFonts.epilogue(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: onSurfaceVar,
          letterSpacing: 11 * 0.06,
        );

    InputDecoration inputDecoration({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0x40C1C6D4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0x40C1C6D4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: surface,
      bottomNavigationBar: userNavBar(),
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditMode ? 'Edit Schedule' : 'New Schedule',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'SCHEDULE CONFIGURATION',
                    style: GoogleFonts.epilogue(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: primary,
                      letterSpacing: 11 * 0.08,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Schedule Content',
                    style: GoogleFonts.publicSans(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define your post metadata, schedule timing, and creative assets for the upcoming broadcast.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Text('POST TITLE', style: labelStyle()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    maxLength: 100,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                    decoration: inputDecoration(hintText: 'e.g., Q3 Product Launch Highlights'),
                    validator: (v) {
                      final req = Validators.required(v, 'Title');
                      if (req != null) return req;
                      return Validators.maxLength(v, 100, 'Title');
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('DESCRIPTION (OPTIONAL)', style: labelStyle()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLength: 500,
                    maxLines: 4,
                    minLines: 3,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                    decoration: inputDecoration(hintText: 'Briefly describe the context of this schedule...'),
                  ),
                  const SizedBox(height: 20),
                  Text('CONTENT TYPE', style: labelStyle()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: primitives.map((primitive) {
                      final isSupported = ContentTypeTranslator.isSupported(primitive, widget.platformName);
                      final isSelected = _contentType == primitive;
                      final label = ContentTypeTranslator.translate(primitive, widget.platformName);

                      return GestureDetector(
                        onTap: isSupported
                            ? () {
                                setState(() {
                                  _contentType = primitive;
                                  _pickedFile = null;
                                });
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? primaryGradient : null,
                            color: isSelected ? null : surfaceWhite,
                            borderRadius: BorderRadius.circular(9999),
                            border: isSelected
                                ? null
                                : Border.all(color: const Color(0x40C1C6D4), width: 1),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSupported
                                  ? (isSelected ? Colors.white : onSurface)
                                  : onSurfaceVar,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('ATTACH MEDIA', style: labelStyle()),
                  const SizedBox(height: 8),
                  if (_pickedFile == null && _currentMediaUrl == null)
                    GestureDetector(
                      onTap: _handleMediaSelection,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x66C1C6D4)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_a_photo_rounded, color: primary, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'Add photo or video',
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Drag and drop or click to browse',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: _pickedFile != null
                                ? (!_contentType.contains('video')
                                    ? Image.file(_pickedFile!, fit: BoxFit.cover)
                                    : Container(
                                        color: surfaceLow,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.play_circle_rounded, size: 56, color: primary),
                                              const SizedBox(height: 6),
                                              Text(
                                                p.basename(_pickedFile!.path),
                                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                : (!_contentType.contains('video')
                                    ? Image.network(_currentMediaUrl!, fit: BoxFit.cover)
                                    : Container(
                                        color: surfaceLow,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.play_circle_rounded, size: 56, color: primary),
                                              const SizedBox(height: 6),
                                              Text(
                                                p.basename(_currentMediaUrl!),
                                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _pickedFile = null;
                                _currentMediaUrl = null;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(color: surfaceWhite, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: errorRed, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_isUploading) ...[
                    const SizedBox(height: 16),
                    Text('Uploading media...', style: GoogleFonts.plusJakartaSans(color: onSurfaceVar)),
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 20),
                  Text('PICK DATE', style: labelStyle()),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: _selectedDate == null ? '' : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                        ),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                        decoration: inputDecoration(
                          hintText: 'MM/DD/YYYY',
                          prefixIcon: const Icon(Icons.calendar_today_rounded, color: primary, size: 18),
                          suffixIcon: const Icon(Icons.calendar_month_rounded, color: onSurfaceVar, size: 18),
                        ),
                        validator: (_) => _selectedDate == null ? 'Date is required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('PICK TIME', style: labelStyle()),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: TextEditingController(text: _selectedTime == null ? '' : _selectedTime!.format(context)),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                        decoration: inputDecoration(
                          hintText: '02:00 PM',
                          prefixIcon: const Icon(Icons.schedule_rounded, color: primary, size: 18),
                          suffixIcon: const Icon(Icons.access_time_rounded, color: onSurfaceVar, size: 18),
                        ),
                        validator: (_) => _selectedTime == null ? 'Time is required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Sticky save button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9999),
                    onTap: (_isLoading || _isUploading) ? null : _submit,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Center(
                        child: (_isLoading || _isUploading)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : Text(
                                isEditMode ? 'SAVE CHANGES' : 'SAVE SCHEDULE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 15 * 0.04,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
