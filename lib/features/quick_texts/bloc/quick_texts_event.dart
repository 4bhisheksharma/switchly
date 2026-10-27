part of 'quick_texts_bloc.dart';

sealed class QuickTextsEvent extends Equatable {
  const QuickTextsEvent();

  @override
  List<Object?> get props => [];
}

final class QuickTextsStarted extends QuickTextsEvent {
  const QuickTextsStarted();
}

/// Adds a new snippet, or replaces the one with the same id.
final class QuickTextSaved extends QuickTextsEvent {
  const QuickTextSaved(this.text);

  final QuickText text;

  @override
  List<Object?> get props => [text];
}

final class QuickTextDeleted extends QuickTextsEvent {
  const QuickTextDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Undo for [QuickTextDeleted].
final class QuickTextRestored extends QuickTextsEvent {
  const QuickTextRestored(this.text, this.index);

  final QuickText text;
  final int index;

  @override
  List<Object?> get props => [text, index];
}

final class QuickTextsReordered extends QuickTextsEvent {
  const QuickTextsReordered(this.oldIndex, this.newIndex);

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}
