part of 'payment_qr_bloc.dart';

sealed class PaymentQrEvent extends Equatable {
  const PaymentQrEvent();

  @override
  List<Object?> get props => [];
}

final class PaymentQrsStarted extends PaymentQrEvent {
  const PaymentQrsStarted();
}

/// Copies the picked image into app storage and adds it.
final class PaymentQrAdded extends PaymentQrEvent {
  const PaymentQrAdded(this.sourcePath, this.name);

  final String sourcePath;
  final String name;

  @override
  List<Object?> get props => [sourcePath, name];
}

final class PaymentQrRenamed extends PaymentQrEvent {
  const PaymentQrRenamed(this.id, this.name);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Removes the entry and its stored image.
final class PaymentQrDeleted extends PaymentQrEvent {
  const PaymentQrDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class PaymentQrsReordered extends PaymentQrEvent {
  const PaymentQrsReordered(this.oldIndex, this.newIndex);

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}
