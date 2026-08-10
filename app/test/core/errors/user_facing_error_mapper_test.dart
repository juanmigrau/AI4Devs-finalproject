import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/sync/data/datasources/game_firestore_datasource.dart';

void main() {
  group('mapExceptionToUserMessage', () {
    test('maps player limit ArgumentError without English prefixes', () {
      final message = mapExceptionToUserMessage(
        ArgumentError('Player limit reached for this game'),
      );

      expect(
        message,
        'No puedes añadir más jugadores. Has alcanzado el límite de la partida.',
      );
      expect(message, isNot(contains('Invalid argument')));
      expect(message, isNot(contains('Player limit')));
    });

    test('maps duplicate player name from ArgumentError.value', () {
      final message = mapExceptionToUserMessage(
        ArgumentError.value(
          'Ana',
          'name',
          'Player name already exists in this game',
        ),
      );

      expect(message, 'Ya hay un jugador con ese nombre en esta partida.');
    });

    test('maps player already exists from favorite', () {
      final message = mapExceptionToUserMessage(
        ArgumentError.value(
          'Ana',
          'displayName',
          'Player already exists in this game',
        ),
      );

      expect(message, 'Ya hay un jugador con ese nombre en esta partida.');
    });

    test('maps favorite duplicate name', () {
      final message = mapExceptionToUserMessage(
        ArgumentError.value(
          'Ana',
          'displayName',
          'Favorite with this display name already exists',
        ),
      );

      expect(message, 'Ya tienes un favorito con ese nombre.');
    });

    test('maps favorite duplicate user', () {
      final message = mapExceptionToUserMessage(
        ArgumentError.value(
          'uid-1',
          'userId',
          'Favorite with this user already exists',
        ),
      );

      expect(message, 'Ese usuario ya está en tus favoritos.');
    });

    test('maps empty name', () {
      final message = mapExceptionToUserMessage(
        ArgumentError.value('', 'name', 'Must not be empty'),
      );

      expect(message, 'El nombre no puede estar vacío.');
    });

    test('maps game not found StateError', () {
      final message = mapExceptionToUserMessage(
        StateError('Game not found: abc'),
      );

      expect(message, 'No encontramos esa partida.');
      expect(message, isNot(contains('Bad state')));
    });

    test('maps dealer forbidden bid', () {
      final message = mapExceptionToUserMessage(
        StateError(
          'Dealer cannot bid 2 because the total would equal 5 tricks',
        ),
      );

      expect(
        message,
        'Esa apuesta no está permitida: haría que el total coincida con las bazas.',
      );
    });

    test('maps expected players count', () {
      final message = mapExceptionToUserMessage(
        ArgumentError('Expected 4 players, got 2'),
      );

      expect(
        message,
        'Añade todos los jugadores antes de empezar la partida.',
      );
    });

    test('maps GameSyncException network', () {
      final message = mapExceptionToUserMessage(
        const GameSyncException(
          GameSyncFailureType.networkUnavailable,
          'Some English Firebase message',
        ),
      );

      expect(message, 'Comprueba tu conexión e inténtalo de nuevo.');
    });

    test('maps GameSyncException permission denied', () {
      final message = mapExceptionToUserMessage(
        const GameSyncException(
          GameSyncFailureType.permissionDenied,
          'Permission denied',
        ),
      );

      expect(message, 'No tienes permiso para sincronizar esta partida.');
    });

    test('maps FirebaseException failed-precondition to history cloud message', () {
      final message = mapExceptionToUserMessage(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'The query requires an index',
        ),
      );

      expect(
        message,
        'No se pudo cargar el historial de la nube. '
        'Comprueba tu conexión e inténtalo de nuevo.',
      );
      expect(message, isNot(contains('failed-precondition')));
      expect(message, isNot(contains('index')));
    });

    test('maps wrapped GameSyncException failed-precondition', () {
      final message = mapExceptionToUserMessage(
        const GameSyncException(
          GameSyncFailureType.unknown,
          'failed-precondition: The query requires an index',
        ),
      );

      expect(
        message,
        'No se pudo cargar el historial de la nube. '
        'Comprueba tu conexión e inténtalo de nuevo.',
      );
    });

    test('uses Spanish fallback for unknown errors', () {
      final message = mapExceptionToUserMessage(Exception('weird boom'));

      expect(
        message,
        'Ha ocurrido un error inesperado. Inténtalo de nuevo.',
      );
    });

    test('never returns English technical prefixes', () {
      final messages = [
        mapExceptionToUserMessage(
          ArgumentError('Player limit reached for this game'),
        ),
        mapExceptionToUserMessage(StateError('Round is not closed')),
        mapExceptionToUserMessage(Exception('x')),
      ];

      for (final message in messages) {
        expect(message, isNot(contains('Invalid argument')));
        expect(message, isNot(contains('Bad state')));
        expect(message, isNot(contains('Exception:')));
        expect(message, isNot(contains('Error:')));
      }
    });
  });
}
