# Notas técnicas

## Mensajes de error al usuario en español

**Fecha:** 29/07/2026
**Implementación:** `app/lib/core/errors/user_facing_error_mapper.dart`
**Patrón:** las excepciones de dominio permanecen en inglés
(logs y tests); la capa presentation usa UserFacingErrorMapper
para convertirlas a mensajes en español humanizados antes de
mostrarlos al usuario. Nunca se muestra el toString() de una
excepción directamente en la UI.
**Fallback:** "Ha ocurrido un error inesperado. Inténtalo de nuevo."

## Menú de tres puntos (cancelar partida)

**Fecha:** 29/07/2026
**Decisión:** eliminado de las pantallas de setup (Crear partida,
Añadir jugadores, Orden de mesa). Mantenido en las pantallas del
ciclo de ronda donde "Cancelar partida" es funcionalmente distinto
a "Ver ronda anterior".

## Navegación atrás en el wizard de setup

**Fecha:** 01/08/2026
**Decisión:** el botón atrás entre pasos del wizard navega sin
diálogo de confirmación (Orden de mesa → Añadir jugadores;
Añadir jugadores → Crear partida). Los datos se conservan en
Drift. El diálogo de descarte / cancelar partida completa queda
solo en el overflow mid-game (u otra acción explícita a Home).

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
