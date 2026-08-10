import 'package:firebase_core/firebase_core.dart';

/// Maps domain/data exceptions to short Spanish messages for the UI.
///
/// Never pass [Object.toString] of an exception directly to the user.
String mapExceptionToUserMessage(Object error) {
  if (error is FirebaseException && error.code == 'failed-precondition') {
    return _failedPreconditionHistoryMessage;
  }

  final syncMessage = _mapGameSyncException(error);
  if (syncMessage != null) {
    return syncMessage;
  }

  final raw = _rawMessage(error);

  if (raw.contains('failed-precondition')) {
    return _failedPreconditionHistoryMessage;
  }

  if (raw.contains('Player limit reached')) {
    return 'No puedes añadir más jugadores. Has alcanzado el límite de la partida.';
  }
  if (raw.contains('Player name already exists') ||
      raw.contains('Player already exists in this game')) {
    return 'Ya hay un jugador con ese nombre en esta partida.';
  }
  if (raw.contains('Favorite with this display name already exists')) {
    return 'Ya tienes un favorito con ese nombre.';
  }
  if (raw.contains('Favorite with this user already exists')) {
    return 'Ese usuario ya está en tus favoritos.';
  }
  if (raw.contains('Must not be empty')) {
    return 'El nombre no puede estar vacío.';
  }
  if (raw.contains('Must be between 3 and 8')) {
    return 'Elige entre 3 y 8 jugadores para la partida.';
  }
  if (raw.contains('Favorite not found')) {
    return 'No encontramos ese favorito.';
  }
  if (raw.contains('Game not found')) {
    return 'No encontramos esa partida.';
  }
  if (raw.contains('Player not found')) {
    return 'No encontramos a ese jugador.';
  }
  if (raw.contains('Finished games cannot be cancelled')) {
    return 'No se puede cancelar una partida ya finalizada.';
  }
  if (raw.contains('Game must be in setup status to start')) {
    return 'Solo puedes iniciar la partida mientras está en preparación.';
  }
  if (raw.contains('Expected') && raw.contains('players')) {
    return 'Añade todos los jugadores antes de empezar la partida.';
  }
  if (raw.contains('Game round sequence is empty')) {
    return 'La secuencia de rondas no es válida. Vuelve a crear la partida.';
  }
  if (raw.contains('Dealer cannot bid') ||
      raw.contains('total would equal')) {
    return 'Esa apuesta no está permitida: haría que el total coincida con las bazas.';
  }
  if (raw.contains('Bid must be between') ||
      (raw.contains('Bid for') && raw.contains('must be between'))) {
    return 'La apuesta debe estar entre 0 y el número de cartas de la ronda.';
  }
  if (raw.contains('It is not') && raw.contains('turn to bid')) {
    return 'Todavía no es tu turno para apostar.';
  }
  if (raw.contains('Player has already submitted a bid')) {
    return 'Este jugador ya ha apostado.';
  }
  if (raw.contains('Player is not in bidding order')) {
    return 'Este jugador no forma parte del orden de apuestas.';
  }
  if (raw.contains('Bids can only be corrected while the round is playing')) {
    return 'Solo puedes corregir apuestas mientras la ronda está en juego.';
  }
  if (raw.contains('Missing bid for player')) {
    return 'Falta la apuesta de algún jugador.';
  }
  if (raw.contains('Tricks cannot be submitted yet')) {
    return 'Todavía no se pueden registrar las bazas.';
  }
  if (raw.contains('Bidding cannot be closed yet')) {
    return 'Todavía no se pueden cerrar las apuestas.';
  }
  if (raw.contains('Round is not in bidding status')) {
    return 'Esta ronda no está en fase de apuestas.';
  }
  if (raw.contains('Round is not in playing status')) {
    return 'Esta ronda no está en fase de juego.';
  }
  if (raw.contains('Only the current round can be repeated')) {
    return 'Solo se puede repetir la ronda actual.';
  }
  if (raw.contains('Closed rounds cannot be repeated')) {
    return 'No se puede repetir una ronda ya cerrada.';
  }
  if (raw.contains('Round cannot be repeated in status')) {
    return 'No se puede repetir la ronda en su estado actual.';
  }
  if (raw.contains('Game must be in progress to load bidding') ||
      raw.contains('Game must be in progress to load play state') ||
      raw.contains('Game must be in progress to advance') ||
      raw.contains('Game must be in progress to finish')) {
    return 'La partida debe estar en curso para continuar.';
  }
  if (raw.contains('Round not found')) {
    return 'No encontramos esa ronda.';
  }
  if (raw.contains('Round is not closed') ||
      raw.contains('is not closed')) {
    return 'Esta ronda aún no está cerrada.';
  }
  if (raw.contains('Round has no scores delta') ||
      raw.contains('has no scores delta')) {
    return 'Todavía no hay puntuaciones para esta ronda.';
  }
  if (raw.contains('Dealer not found')) {
    return 'No encontramos al repartidor de esta ronda.';
  }
  if (raw.contains('Current round must be closed to advance') ||
      raw.contains('Current round must be closed to finish')) {
    return 'Cierra la ronda actual antes de continuar.';
  }
  if (raw.contains('Cannot advance beyond the last round')) {
    return 'Ya estás en la última ronda.';
  }
  if (raw.contains('Cannot finish game before the last round')) {
    return 'Solo puedes finalizar la partida en la última ronda.';
  }
  if (raw.contains('Only finished games can be deleted from history')) {
    return 'Solo se pueden eliminar del historial las partidas finalizadas.';
  }
  if (raw.contains('Game is not finished')) {
    return 'Esta partida aún no ha finalizado.';
  }
  if (raw.contains('Players list must not be empty')) {
    return 'Hace falta al menos un jugador.';
  }
  if (raw.contains('Dealer not found in roster')) {
    return 'No encontramos al repartidor en la lista de jugadores.';
  }
  if (raw.contains('Invalid reorder indices')) {
    return 'No se pudo reordenar la lista. Inténtalo de nuevo.';
  }
  if (raw.contains('Unknown game status') ||
      raw.contains('Unknown round status')) {
    return 'Los datos de la partida no son válidos. Inténtalo de nuevo.';
  }
  if (raw.contains('Only finished games can be uploaded') ||
      raw.contains('Only closed rounds can be uploaded') ||
      raw.contains('Game must be finished to upload') ||
      raw.contains('Incomplete round data for upload')) {
    return 'No se pudo sincronizar; se reintentará.';
  }
  if (raw.contains('Finished game missing finishedAt')) {
    return 'Los datos de la partida no son válidos. Inténtalo de nuevo.';
  }
  if (raw.contains('network') ||
      raw.contains('unavailable') ||
      raw.contains('connection')) {
    return 'Comprueba tu conexión e inténtalo de nuevo.';
  }

  return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
}

const _failedPreconditionHistoryMessage =
    'No se pudo cargar el historial de la nube. '
    'Comprueba tu conexión e inténtalo de nuevo.';

/// Matches [GameSyncException] by runtime type name to avoid core→feature imports.
String? _mapGameSyncException(Object error) {
  if (error.runtimeType.toString() != 'GameSyncException') {
    return null;
  }

  final text = error.toString();
  if (text.contains('failed-precondition')) {
    return _failedPreconditionHistoryMessage;
  }
  if (text.contains('permissionDenied')) {
    return 'No tienes permiso para sincronizar esta partida.';
  }
  if (text.contains('networkUnavailable')) {
    return 'Comprueba tu conexión e inténtalo de nuevo.';
  }
  if (text.contains('invalidData')) {
    return 'Los datos de la partida no son válidos. Inténtalo de nuevo.';
  }
  return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
}

String _rawMessage(Object error) {
  if (error is ArgumentError) {
    final message = error.message;
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
  }
  if (error is StateError) {
    return error.message;
  }
  if (error is RangeError) {
    final message = error.message;
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
  }
  return error.toString();
}
