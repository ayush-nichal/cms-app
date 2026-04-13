import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/update_service.dart';
import '../design/design_tokens.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final Dio dio;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.dio,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0.0;
  bool _isDownloading = false;
  bool _isInstallReady = false;
  String? _downloadedPath;
  String? _errorMessage;

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/downloads/cms_app_update.apk';
      await Directory('${dir.path}/downloads').create(recursive: true);

      await widget.dio.download(
        widget.updateInfo.apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => _progress = received / total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      setState(() {
        _isDownloading = false;
        _isInstallReady = true;
        _downloadedPath = savePath;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Download failed. Please try again.';
      });
    }
  }

  Future<void> _install() async {
    if (_downloadedPath == null) return;
    await OpenFile.open(_downloadedPath!);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;
    final isForced = info.forceUpdate;

    return PopScope(
      canPop: !isForced && !_isDownloading,
      child: Container(
        decoration: const BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: GoogleFonts.publicSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        'v${info.currentVersion}  →  v${info.latestVersion}',
                        style: GoogleFonts.epilogue(
                          fontSize: 13,
                          color: onSurfaceVar,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isForced && !_isDownloading)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Later',
                      style: GoogleFonts.plusJakartaSans(
                        color: onSurfaceVar,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Release notes
            if (info.releaseNotes.isNotEmpty) ...[
              Text(
                "WHAT'S NEW",
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onSurfaceVar,
                  letterSpacing: 11 * 0.08,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.6,
                      color: onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Progress bar (shown during download)
            if (_isDownloading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading update...',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: onSurfaceVar),
                  ),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.epilogue(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: surfaceLow,
                  valueColor: const AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: errorRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: errorRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                onTap: _isDownloading
                    ? null
                    : _isInstallReady
                        ? _install
                        : _downloadAndInstall,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _isDownloading ? null : primaryGradient,
                    color: _isDownloading ? surfaceLow : null,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Center(
                    child: Text(
                      _isInstallReady
                          ? 'INSTALL NOW'
                          : _isDownloading
                              ? 'DOWNLOADING...'
                              : 'UPDATE NOW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _isDownloading ? onSurfaceVar : Colors.white,
                        letterSpacing: 15 * 0.04,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
