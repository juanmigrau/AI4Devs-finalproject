import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';

class HowToPlayPage extends StatelessWidget {
  const HowToPlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PochaAppBar(title: '¿Cómo se juega?', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RulesSection(
                      title: 'El objetivo',
                      body:
                          'Ganar más puntos que el resto apostando correctamente '
                          'cuántas bazas ganarás.',
                      theme: theme,
                    ),
                    _RulesSection(
                      title: 'Una ronda',
                      body:
                          'Se reparten cartas, cada jugador apuesta bazas, se juega '
                          'y se anotan las bazas reales.',
                      theme: theme,
                    ),
                    _RulesSection(
                      title: 'La puntuación',
                      body:
                          'Acierto: 10 + 5×bazas. Fallo: −5×|apuesta − bazas|.',
                      theme: theme,
                    ),
                    _RulesSection(
                      title: 'La restricción del repartidor',
                      body:
                          'La suma de apuestas no puede igualar las cartas de la '
                          'ronda. El repartidor apuesta el último y no puede hacer '
                          'que la suma sea igual.',
                      theme: theme,
                    ),
                    _RulesSection(
                      title: 'La secuencia de rondas',
                      body:
                          'Sube hasta el máximo, se repite N veces (N = jugadores) '
                          'y luego baja.',
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({
    required this.title,
    required this.body,
    required this.theme,
  });

  final String title;
  final String body;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
