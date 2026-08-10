part of 'history_list_bloc.dart';

sealed class HistoryListState extends Equatable {
  const HistoryListState();

  @override
  List<Object?> get props => [];
}

class HistoryListInitial extends HistoryListState {
  const HistoryListInitial();
}

class HistoryListLoading extends HistoryListState {
  const HistoryListLoading();
}

class HistoryListLoaded extends HistoryListState {
  const HistoryListLoaded({
    required this.items,
    this.cloudError = false,
  });

  final List<GameHistoryItem> items;
  final bool cloudError;

  @override
  List<Object?> get props => [items, cloudError];
}

class HistoryListEmpty extends HistoryListState {
  const HistoryListEmpty();
}

class HistoryListFailure extends HistoryListState {
  const HistoryListFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
