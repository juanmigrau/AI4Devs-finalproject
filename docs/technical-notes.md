# Notas técnicas

keytool -genkey -v -keystore app/android/la-pocha.keystore -alias la-pocha -keyalg RSA -keysize 2048 -validity 10000
K4nk4m9s4p!
Juanmi Grau
Almussafes
Valencia
ES




## Identidad de usuario — decisión de producto

**Fecha:** 14/08/2026

La app tiene dos tipos de identidad que no se vinculan
automáticamente:

- Registrado: userId (Firebase Auth UID) — estable y único
- Invitado: displayName (string libre) — mutable y ambiguo

DECISIONES:

- Estadísticas: solo partidas donde userId aparece en
  players[].userId. Sin heurísticas de nombre (eliminar
  criterio C de GetPlayerStatsUseCase).
- Historial local: todas las partidas del dispositivo.
  El usuario borra manualmente las ajenas (LPT-17).
- Vinculación post-registro: pantalla única tras primer
  login ofreciendo reclamar partidas locales por nombre.
- Cambio de nombre: no afecta partidas pasadas.
  Estadísticas calculadas por userId, no por displayName.

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
