import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/quick_text.dart';

part 'quick_texts_event.dart';
part 'quick_texts_state.dart';

/// The user's saved snippets. Every change is saved immediately for the tile.
class QuickTextsBloc extends Bloc<QuickTextsEvent, QuickTextsState> {
  QuickTextsBloc(this._repository) : super(const QuickTextsState()) {
    on<QuickTextsStarted>(_onStarted);
    on<QuickTextSaved>(_onSaved);
    on<QuickTextDeleted>(_onDeleted);
    on<QuickTextRestored>(_onRestored);
    on<QuickTextsReordered>(_onReordered);
  }

  final QuickTextsRepository _repository;

  Future<void> _onStarted(QuickTextsStarted event, Emitter<QuickTextsState> emit) async {
    emit(QuickTextsState(loaded: true, texts: await _repository.load()));
  }

  Future<void> _onSaved(QuickTextSaved event, Emitter<QuickTextsState> emit) async {
    final texts = [...state.texts];
    final index = texts.indexWhere((t) => t.id == event.text.id);
    if (index == -1) {
      texts.add(event.text);
    } else {
      texts[index] = event.text;
    }
    await _save(emit, texts);
  }

  Future<void> _onDeleted(QuickTextDeleted event, Emitter<QuickTextsState> emit) =>
      _save(emit, state.texts.where((t) => t.id != event.id).toList());

  Future<void> _onRestored(QuickTextRestored event, Emitter<QuickTextsState> emit) =>
      _save(emit, [...state.texts]..insert(event.index.clamp(0, state.texts.length), event.text));

  Future<void> _onReordered(QuickTextsReordered event, Emitter<QuickTextsState> emit) {
    final texts = [...state.texts];
    // newIndex is already adjusted for the removal (onReorderItem semantics).
    texts.insert(event.newIndex, texts.removeAt(event.oldIndex));
    return _save(emit, texts);
  }

  Future<void> _save(Emitter<QuickTextsState> emit, List<QuickText> texts) async {
    emit(QuickTextsState(loaded: true, texts: texts));
    await _repository.save(texts);
  }
}
