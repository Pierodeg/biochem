import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../home_sections.dart';

/// Home — hub a griglia di card verso tutte le sezioni dell'app.
///
/// Un solo widget per desktop e mobile (regola componenti condivisi):
/// cambia solo il numero di colonne e la presenza del sottotitolo.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Tutte le sezioni tranne la Home stessa.
  List<SezioneApp> get _sezioni =>
      sezioniApp.where((s) => s.id != 'home').toList();

  void _vaiA(BuildContext context, SezioneApp s) {
    // I branch dello shell si aprono con go (cambio tab); le route a sé
    // (Registro/Configurazione) con push per mantenere il tasto indietro.
    if (s.branchIndex != null) {
      context.go(s.route);
    } else {
      context.push(s.route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nome = ref.watch(currentUserProvider).valueOrNull?.displayName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 600;
        final crossAxisCount =
            isDesktop ? (width / 300).floor().clamp(2, 4) : 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome != null && nome.isNotEmpty ? 'Ciao, $nome' : 'Ciao',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scegli una sezione',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textOnDarkSecondary),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sezioni.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isDesktop ? 1.5 : 1.05,
                ),
                itemBuilder: (context, i) => _CardSezione(
                  sezione: _sezioni[i],
                  mostraSottotitolo: isDesktop,
                  onTap: () => _vaiA(context, _sezioni[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardSezione extends StatelessWidget {
  final SezioneApp sezione;
  final bool mostraSottotitolo;
  final VoidCallback onTap;

  const _CardSezione({
    required this.sezione,
    required this.mostraSottotitolo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: AppColors.glassCardHover,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: Icon(sezione.icona,
                    color: AppColors.accentGreenDark, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                sezione.titolo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDark,
                ),
              ),
              if (mostraSottotitolo) ...[
                const SizedBox(height: 4),
                Text(
                  sezione.sottotitolo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
              ],
              if (sezione.inArrivo) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmberDark.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'in arrivo',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentAmberDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
