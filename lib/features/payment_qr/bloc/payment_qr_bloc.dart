import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/payment_qr.dart';

part 'payment_qr_event.dart';
part 'payment_qr_state.dart';

/// Saved payment QR codes, in the order the tile shows them.
class PaymentQrBloc extends Bloc<PaymentQrEvent, PaymentQrState> {
  PaymentQrBloc(this._repository) : super(const PaymentQrState()) {
    on<PaymentQrsStarted>(_onStarted);
    on<PaymentQrAdded>(_onAdded);
    on<PaymentQrRenamed>(_onRenamed);
    on<PaymentQrDeleted>(_onDeleted);
    on<PaymentQrsReordered>(_onReordered);
  }

  final PaymentQrRepository _repository;

  Future<void> _onStarted(PaymentQrsStarted event, Emitter<PaymentQrState> emit) async {
    emit(PaymentQrState(loaded: true, qrs: await _repository.load()));
  }

  Future<void> _onAdded(PaymentQrAdded event, Emitter<PaymentQrState> emit) async {
    final qr = await _repository.import(event.sourcePath, event.name);
    await _save(emit, [...state.qrs, qr]);
  }

  Future<void> _onRenamed(PaymentQrRenamed event, Emitter<PaymentQrState> emit) => _save(emit, [
        for (final q in state.qrs) q.id == event.id ? q.copyWith(name: event.name) : q,
      ]);

  Future<void> _onDeleted(PaymentQrDeleted event, Emitter<PaymentQrState> emit) async {
    final target = state.qrs.where((q) => q.id == event.id).firstOrNull;
    if (target == null) return;
    await _save(emit, [...state.qrs]..remove(target));
    await _repository.deleteFile(target);
  }

  Future<void> _onReordered(PaymentQrsReordered event, Emitter<PaymentQrState> emit) {
    final qrs = [...state.qrs];
    // newIndex is already adjusted for the removal (onReorderItem semantics).
    qrs.insert(event.newIndex, qrs.removeAt(event.oldIndex));
    return _save(emit, qrs);
  }

  Future<void> _save(Emitter<PaymentQrState> emit, List<PaymentQr> qrs) async {
    emit(PaymentQrState(loaded: true, qrs: qrs));
    await _repository.save(qrs);
  }
}
