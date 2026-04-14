import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Pagina Fatture — placeholder
class FatturePage extends StatelessWidget {
  const FatturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textDisabled),
          SizedBox(height: 16),
          Text(
            'Fatture',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Funzionalità in arrivo',
            style: TextStyle(fontSize: 14, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}
