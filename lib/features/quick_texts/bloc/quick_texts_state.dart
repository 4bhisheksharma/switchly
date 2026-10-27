part of 'quick_texts_bloc.dart';

final class QuickTextsState extends Equatable {
  const QuickTextsState({this.loaded = false, this.texts = const []});

  final bool loaded;

  /// In the order shown by the tile.
  final List<QuickText> texts;

  @override
  List<Object?> get props => [loaded, texts];
}
