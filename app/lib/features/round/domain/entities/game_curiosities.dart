import 'package:equatable/equatable.dart';

class GameCuriosities extends Equatable {
  const GameCuriosities({
    required this.mostEqualRoundNumber,
    required this.riskiestPlayerId,
    required this.riskiestPlayerName,
    required this.mostConservativePlayerId,
    required this.mostConservativePlayerName,
  });

  final int? mostEqualRoundNumber;
  final String? riskiestPlayerId;
  final String? riskiestPlayerName;
  final String? mostConservativePlayerId;
  final String? mostConservativePlayerName;

  const GameCuriosities.empty()
      : mostEqualRoundNumber = null,
        riskiestPlayerId = null,
        riskiestPlayerName = null,
        mostConservativePlayerId = null,
        mostConservativePlayerName = null;

  @override
  List<Object?> get props => [
        mostEqualRoundNumber,
        riskiestPlayerId,
        riskiestPlayerName,
        mostConservativePlayerId,
        mostConservativePlayerName,
      ];
}
