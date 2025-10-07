import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klayons/utils/colour.dart';
import 'package:google_fonts/google_fonts.dart';

class KlayonsText extends StatelessWidget {
  const KlayonsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'klayons',
      style: GoogleFonts.poetsenOne(
        textStyle: const TextStyle(
          fontSize: 70,
          //fontWeight: FontWeight.bold,
          color: AppColors.orangeHighlight,
        ),
      ),
    );
  }
}
