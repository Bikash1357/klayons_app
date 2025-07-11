import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KlayonsText extends StatelessWidget {
  const KlayonsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'klayons',
      style: GoogleFonts.fredoka(
        // or try: baloo2, quicksand
        textStyle: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Color(0xFFED7733), // orange
        ),
      ),
    );
  }
}
