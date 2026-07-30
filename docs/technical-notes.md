# Notas técnicas

## Menú de tres puntos (cancelar partida)

**Fecha:** 29/07/2026
**Decisión:** eliminado de las pantallas de setup (Crear partida,
Añadir jugadores, Orden de mesa) donde el botón atrás con
diálogo de confirmación ya cubre el mismo caso de uso.
Mantenido en las pantallas del ciclo de ronda donde "Cancelar
partida" es funcionalmente distinto a "Ver ronda anterior".

## WakeLock durante el ciclo de ronda

**Fecha:** 29/07/2026
**Paquete:** wakelock_plus
**Motivo:** la pantalla se bloqueaba durante el juego físico,
interrumpiendo la experiencia. Activo en bidding/play/scoring/
round_result; desactivado en home, historial y resultado final.

## Panel de debug en runtime (DebugConfigNotifier)

**Fecha:** 10/07/2026
**Motivo:** probar el flujo E2E completo requería 22 rondas reales.
El panel permite configurar secuencias cortas desde la app sin
tocar código. Solo visible en kDebugMode.

## Template de email de Firebase en español

**Fecha:** pendiente
**Motivo:** el email de recuperación de contraseña llegaba en
inglés. Personalizar en Firebase Console → Authentication →
Templates → Password reset.
