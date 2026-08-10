import 'package:equatable/equatable.dart';

import 'game_history_item.dart';

/// Result of loading game history from local and optionally cloud sources.
class GameHistoryLoadResult extends Equatable {
  const GameHistoryLoadResult({
    required this.items,
    this.cloudError = false,
  });

  final List<GameHistoryItem> items;
  final bool cloudError;

  @override
  List<Object?> get props => [items, cloudError];
}
