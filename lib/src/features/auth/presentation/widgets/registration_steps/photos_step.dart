import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

/// L-shaped corner brackets drawn at each corner of a photo slot,
/// giving it a viewfinder / rangefinder aesthetic.
class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.color});

  final Color color;

  static const double _len = 12.0;
  static const double _thick = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(0, _len), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(_len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - _len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, _len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - _len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(_len, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - _len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - _len), paint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => old.color != color;
}

class PhotosStep extends StatelessWidget {
  const PhotosStep({
    super.key,
    required this.photos,
    required this.onPickImage,
    required this.onRemovePhoto,
    required this.onBack,
    required this.onContinue,
    required this.tr,
  });

  final List<File?> photos;
  final Future<void> Function(int index) onPickImage;
  final void Function(int index) onRemovePhoto;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const isDev =
        String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';
    final hasAtLeastOne = isDev || photos.any((p) => p != null);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              TrembleBackButton(onPressed: onBack, label: tr('back')),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          StepHeader(tr('select_photo_title')),
          const SizedBox(height: 8),
          Text(
            tr('photos_lofi_hint'),
            style: GoogleFonts.lora(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: 6,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => onPickImage(i),
                child: Stack(clipBehavior: Clip.none, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: photos[i] != null
                                  ? Theme.of(context).colorScheme.primary
                                  : (isDark ? Colors.white24 : Colors.black12)),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: photos[i] != null
                              ? Container(
                                  key: ValueKey(photos[i]!.path),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    image: DecorationImage(
                                      image: FileImage(photos[i]!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Center(
                                  key: const ValueKey('empty'),
                                  child: Icon(LucideIcons.plus,
                                      color: isDark ? Colors.white38 : Colors.black26,
                                      size: 28),
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Viewfinder brackets on empty slots
                  if (photos[i] == null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ViewfinderPainter(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                    ),
                  if (i == 0)
                    Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.amber, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.star,
                              size: 10, color: Colors.black),
                        )),
                  if (photos[i] != null)
                    Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onRemovePhoto(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.x,
                                size: 12, color: Colors.white),
                          ),
                        )),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ContinueButton(
              enabled: hasAtLeastOne,
              onTap: onContinue,
              label: tr('continue_btn')),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
