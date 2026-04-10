import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

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
          TrembleBackButton(label: tr('back'), onPressed: onBack),
          const SizedBox(height: 24),
          StepHeader(tr('select_photo_title')),
          const SizedBox(height: 8),
          Text(tr('photos_hint'),
              style: GoogleFonts.instrumentSans(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 13)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: 6,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => onPickImage(i),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: photos[i] != null
                              ? const Color(0xFFF4436C)
                              : (isDark ? Colors.white24 : Colors.black12)),
                      image: photos[i] != null
                          ? DecorationImage(
                              image: FileImage(photos[i]!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: photos[i] == null
                        ? Center(
                            child: Icon(LucideIcons.plus,
                                color: isDark ? Colors.white38 : Colors.black26,
                                size: 28))
                        : null,
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
