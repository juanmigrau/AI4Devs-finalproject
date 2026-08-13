import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/home/presentation/pages/how_to_play_page.dart';

void main() {
  testWidgets('shows title and scoring rules', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HowToPlayPage()),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    expect(find.text('¿Cómo se juega?'), findsOneWidget);
    expect(find.text('El objetivo'), findsOneWidget);
    expect(find.text('La puntuación'), findsOneWidget);
    expect(
      find.text('Acierto: 10 + 5×bazas. Fallo: −5×|apuesta − bazas|.'),
      findsOneWidget,
    );
  });
}
