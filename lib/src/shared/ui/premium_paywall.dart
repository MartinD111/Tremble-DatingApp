import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'glass_card.dart';
import 'primary_button.dart';

class PremiumPaywallBottomSheet extends StatelessWidget {
  const PremiumPaywallBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => const PremiumPaywallBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A beautiful glassmorphic bottom sheet for Premium upgrades
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: GlassCard(
        opacity: 0.15,
        borderRadius: 32,
        padding:
            const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Icon & Title
            const Center(
              child: Icon(
                LucideIcons.crown,
                color: Color(0xFFFFD700), // Gold
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Odkleni Premium',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pridobi dostop do vseh ekskluzivnih funkcij in izstopaj iz množice.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Feature List
            _buildFeatureRow(LucideIcons.map, 'Napredni zemljevid in Radar'),
            _buildFeatureRow(LucideIcons.filter, 'Neomejeni napredni filtri'),
            _buildFeatureRow(LucideIcons.eye, 'Poglej, komu si všeč'),
            _buildFeatureRow(LucideIcons.rocket, '1x Boost profil na teden'),

            const SizedBox(height: 36),

            // Price Display
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '9,99 €',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: ' / mesec',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upgrade CTA
            PrimaryButton(
              text: 'Naroči se zdaj',
              onPressed: () {
                // TODO: Wire up to RevenueCat / In-App Purchases
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kmalu na voljo! (Integracija plačil)'),
                    backgroundColor: Color(0xFF00D9A6),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Restore Purchases & Cancel
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Ne, hvala',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
