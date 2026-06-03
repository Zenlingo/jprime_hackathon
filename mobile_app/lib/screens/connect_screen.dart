import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/segmented_control.dart';
import '../widgets/avatar.dart';
import 'linkedin_webview_screen.dart';

class ConnectScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final String? linkedInUrl;
  final void Function(String?) onLinkedInChanged;
  final String? displayName;
  final void Function(String?) onDisplayNameChanged;

  const ConnectScreen({
    super.key,
    this.onThemeToggle,
    this.linkedInUrl,
    required this.onLinkedInChanged,
    this.displayName,
    required this.onDisplayNameChanged,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  String _tab = 'me';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(
          title: 'Connect',
          trailing: _ThemeButton(onTap: widget.onThemeToggle),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            children: [
              SegmentedControl<String>(
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
                options: [
                  (value: 'me', label: 'My QR'),
                  (value: 'scan', label: 'Scan'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _tab == 'me'
              ? _MyQR(
                  linkedInUrl: widget.linkedInUrl,
                  onLinkedInChanged: widget.onLinkedInChanged,
                  displayName: widget.displayName,
                  onDisplayNameChanged: widget.onDisplayNameChanged,
                )
              : const _ScanView(),
        ),
      ],
    );
  }
}

class _MyQR extends StatefulWidget {
  final String? linkedInUrl;
  final void Function(String?) onLinkedInChanged;
  final String? displayName;
  final void Function(String?) onDisplayNameChanged;

  const _MyQR({
    required this.linkedInUrl,
    required this.onLinkedInChanged,
    this.displayName,
    required this.onDisplayNameChanged,
  });

  @override
  State<_MyQR> createState() => _MyQRState();
}

class _MyQRState extends State<_MyQR> {
  bool _editing = false;
  bool _editingName = false;
  String? _validationError;
  late TextEditingController _controller;
  late TextEditingController _nameController;

  static final _linkedInPattern = RegExp(
    r'^https?://(www\.)?linkedin\.com/in/[a-zA-Z0-9\-_%]+/?$',
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.linkedInUrl ?? '');
    _nameController = TextEditingController(text: widget.displayName ?? '');
  }

  @override
  void didUpdateWidget(_MyQR oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linkedInUrl != widget.linkedInUrl && !_editing) {
      _controller.text = widget.linkedInUrl ?? '';
    }
    if (oldWidget.displayName != widget.displayName && !_editingName) {
      _nameController.text = widget.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateUrl(String url) {
    if (url.isEmpty) return 'Please enter a LinkedIn URL';
    if (!_linkedInPattern.hasMatch(url)) {
      return 'Enter a valid LinkedIn URL (e.g. https://linkedin.com/in/yourname)';
    }
    return null;
  }

  void _save() {
    final url = _controller.text.trim();
    final error = _validateUrl(url);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    widget.onLinkedInChanged(url);
    setState(() {
      _editing = false;
      _validationError = null;
    });
  }

  void _remove() {
    widget.onLinkedInChanged(null);
    widget.onDisplayNameChanged(null);
    _controller.clear();
    _nameController.clear();
    setState(() {
      _editing = false;
      _editingName = false;
      _validationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final hasUrl = widget.linkedInUrl != null && widget.linkedInUrl!.isNotEmpty;

    if (!hasUrl && !_editing) {
      return _AddLinkedInPrompt(
        onAdd: () => setState(() => _editing = true),
        onLinkedInChanged: widget.onLinkedInChanged,
      );
    }

    if (_editing) {
      return _LinkedInEditor(
        controller: _controller,
        onSave: _save,
        onCancel: () => setState(() {
          _editing = false;
          _validationError = null;
          _controller.text = widget.linkedInUrl ?? '';
        }),
        validationError: _validationError,
        onChanged: () {
          if (_validationError != null) {
            setState(() => _validationError = null);
          }
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: jp.surface,
            border: Border.all(color: jp.border),
            borderRadius: BorderRadius.circular(JPSpacing.rLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const SpeakerAvatar(speakerId: 'venkat', size: 64),
              const SizedBox(height: 10),
              if (_editingName)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: jp.fg,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            hintStyle: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              color: jp.fgMuted,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: jp.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: jp.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: jp.accent, width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) {
                            final name = _nameController.text.trim();
                            widget.onDisplayNameChanged(
                                name.isNotEmpty ? name : null);
                            setState(() => _editingName = false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final name = _nameController.text.trim();
                          widget.onDisplayNameChanged(
                              name.isNotEmpty ? name : null);
                          setState(() => _editingName = false);
                        },
                        child: PhosphorIcon(PhosphorIconsRegular.check,
                            size: 22, color: jp.accent),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _editingName = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.displayName ?? 'Tap to set name',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: widget.displayName != null
                              ? jp.fg
                              : jp.fgMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PhosphorIcon(PhosphorIconsRegular.pencilSimple,
                          size: 16, color: jp.fgMuted),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(JPSpacing.rMd),
                  border: Border.all(color: jp.border),
                ),
                child: QrImageView(
                  data: widget.linkedInUrl!,
                  version: QrVersions.auto,
                  size: 168,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0E1726),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0E1726),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Show this to swap contacts',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: jp.fgMuted,
                ),
              ),
              const SizedBox(height: 18),
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionChip(
                    icon: PhosphorIconsRegular.pencilSimple,
                    label: 'Edit URL',
                    color: jp.accent,
                    onTap: () => setState(() => _editing = true),
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: PhosphorIconsRegular.linkedinLogo,
                    label: 'Reconnect',
                    color: const Color(0xFF0A66C2),
                    onTap: () async {
                      final url = await LinkedInFlowScreen.show(context,
                          skipInitialCheck: true);
                      if (url != null) widget.onLinkedInChanged(url);
                    },
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: PhosphorIconsRegular.trash,
                    label: 'Remove',
                    color: jp.fgMuted,
                    onTap: _remove,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddLinkedInPrompt extends StatelessWidget {
  final VoidCallback onAdd;
  final void Function(String?) onLinkedInChanged;

  const _AddLinkedInPrompt({
    required this.onAdd,
    required this.onLinkedInChanged,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: jp.surface,
            border: Border.all(color: jp.border),
            borderRadius: BorderRadius.circular(JPSpacing.rLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A66C2).withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: PhosphorIcon(PhosphorIconsFill.linkedinLogo,
                    size: 28, color: const Color(0xFF0A66C2)),
              ),
              const SizedBox(height: 16),
              Text(
                'Share your LinkedIn',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: jp.fg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to auto-fetch your profile, or enter the URL manually.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: jp.fgSecondary,
                ),
              ),
              const SizedBox(height: 22),
              // Sign in with LinkedIn button
              GestureDetector(
                onTap: () async {
                  final url = await LinkedInFlowScreen.show(context);
                  if (url != null) onLinkedInChanged(url);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A66C2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(PhosphorIconsFill.linkedinLogo,
                          size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Sign in with LinkedIn',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Or enter manually
              GestureDetector(
                onTap: onAdd,
                child: Text(
                  'Enter URL manually',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: jp.fgMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkedInEditor extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String? validationError;
  final VoidCallback? onChanged;

  const _LinkedInEditor({
    required this.controller,
    required this.onSave,
    required this.onCancel,
    this.validationError,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final hasError = validationError != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: jp.surface,
            border: Border.all(color: jp.border),
            borderRadius: BorderRadius.circular(JPSpacing.rLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LinkedIn Profile URL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: jp.fg,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => onChanged?.call(),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  color: jp.fg,
                ),
                decoration: InputDecoration(
                  hintText: 'https://linkedin.com/in/yourname',
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: jp.fgMuted,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: PhosphorIcon(PhosphorIconsRegular.linkedinLogo,
                        size: 20, color: hasError ? jp.warning : jp.fgMuted),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: jp.bg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: jp.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: hasError ? jp.warning : jp.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: hasError ? jp.warning : jp.accent, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.url,
                onSubmitted: (_) => onSave(),
              ),
              if (hasError) ...[
                const SizedBox(height: 8),
                Text(
                  validationError!,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: jp.warning,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: jp.border),
                          borderRadius:
                              BorderRadius.circular(JPSpacing.rPill),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: jp.fgSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onSave,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: jp.accent,
                          borderRadius:
                              BorderRadius.circular(JPSpacing.rPill),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Save',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: jp.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanView extends StatefulWidget {
  const _ScanView();

  @override
  State<_ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<_ScanView> {
  PermissionStatus? _permissionStatus;
  MobileScannerController? _scannerController;
  String? _scannedUrl;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (mounted) setState(() => _permissionStatus = status);
    if (status.isGranted) _startScanner();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (mounted) setState(() => _permissionStatus = status);
    if (status.isGranted) _startScanner();
  }

  void _startScanner() {
    _scannerController = MobileScannerController();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scannedUrl != null) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        setState(() => _scannedUrl = value);
        _scannerController?.stop();
        _showResult(value);
        break;
      }
    }
  }

  void _showResult(String url) {
    // If it's a URL, open it directly
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
      // Reset scanner after a short delay so it's ready when user comes back
      Future.delayed(const Duration(milliseconds: 500), _resetScanner);
      return;
    }

    // Non-URL QR code — show bottom sheet
    final jp = context.jp;
    showModalBottomSheet(
      context: context,
      backgroundColor: jp.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: jp.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            PhosphorIcon(PhosphorIconsFill.checkCircle,
                size: 48, color: jp.accent),
            const SizedBox(height: 12),
            Text(
              'QR Code Scanned',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: jp.fg,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              url,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: jp.accent,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _resetScanner();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: jp.accent,
                    borderRadius: BorderRadius.circular(JPSpacing.rPill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Scan Another',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: jp.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(_resetScanner);
  }

  void _resetScanner() {
    if (mounted) {
      setState(() => _scannedUrl = null);
      _scannerController?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;

    // Still loading permission status
    if (_permissionStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Permission denied — show prompt
    if (!_permissionStatus!.isGranted) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: jp.surface,
            border: Border.all(color: jp.border),
            borderRadius: BorderRadius.circular(JPSpacing.rLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: jp.accentSoft,
                ),
                alignment: Alignment.center,
                child: PhosphorIcon(PhosphorIconsRegular.camera,
                    size: 28, color: jp.accent),
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Access Needed',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: jp.fg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Allow camera access to scan QR codes from other attendees.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: jp.fgSecondary,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _permissionStatus!.isPermanentlyDenied
                    ? openAppSettings
                    : _requestPermission,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    color: jp.accent,
                    borderRadius: BorderRadius.circular(JPSpacing.rPill),
                  ),
                  child: Text(
                    _permissionStatus!.isPermanentlyDenied
                        ? 'Open Settings'
                        : 'Allow Camera',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: jp.onAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Permission granted — show scanner
    if (_scannerController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(JPSpacing.rLg),
        child: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onDetect,
            ),
            // Scan frame overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 60,
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: jp.accent, width: 2.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Point at someone\'s jPrime QR',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: Colors.white,
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

class _ThemeButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ThemeButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: jp.surface2,
          border: Border.all(color: jp.border),
          borderRadius: BorderRadius.circular(JPSpacing.rPill),
        ),
        alignment: Alignment.center,
        child: PhosphorIcon(
          isDark ? PhosphorIconsFill.sun : PhosphorIconsFill.moonStars,
          size: 19,
          color: jp.fg,
        ),
      ),
    );
  }
}
