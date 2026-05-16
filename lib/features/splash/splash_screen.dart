import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../services/fcm_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Inizializzazione FCM pesante in background — non blocca l'animazione
    final container = ProviderScope.containerOf(context, listen: false);
    FcmService.setRouter(container.read(routerProvider));
    FcmService(container).inizializzaDopoAvvio();

    // Dopo 4 secondi segnala al router che il minimo è trascorso.
    // Se il caricamento auth è già finito il router naviga subito,
    // altrimenti aspetta anche il completamento dell'auth.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        ref.read(minSplashElapsedProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMid1,
              AppColors.gradientMid2,
              AppColors.gradientEnd,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Luce decorativa verde in alto a destra (stessa del MainScreen)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF00A843).withValues(alpha: 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Luce decorativa blu in basso a sinistra
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF1565C0).withValues(alpha: 0.15),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Contenuto centrato
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/loading-animation.json',
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
