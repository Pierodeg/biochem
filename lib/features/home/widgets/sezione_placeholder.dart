import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Placeholder condiviso per le sezioni non ancora implementate.
///
/// Verrà sostituito dal contenuto reale nelle rispettive AREE del piano
/// (vedi PIANO_GENERALE.md). Usato in modo uniforme da tutte le nuove sezioni.
class SezionePlaceholder extends StatelessWidget {
  final String titolo;
  final IconData icona;
  final String? nota;

  const SezionePlaceholder({
    super.key,
    required this.titolo,
    required this.icona,
    this.nota,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icona, size: 64, color: AppColors.textOnDarkMuted),
          const SizedBox(height: 16),
          Text(
            titolo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nota ?? 'Sezione in costruzione',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textOnDarkMuted),
          ),
        ],
      ),
    );
  }
}
