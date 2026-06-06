import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tremble/src/core/theme.dart';

/// Shown when the backend rejects a request with permission-denied + "suspended".
///
/// Non-dismissible: the user cannot navigate back. They must contact support.
class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: TrembleTheme.textColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'tremble',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: TrembleTheme.rose,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Tvoj račun je začasno onemogočen.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Za pomoč se obrni na:\ninfo@trembledating.com',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white54,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
