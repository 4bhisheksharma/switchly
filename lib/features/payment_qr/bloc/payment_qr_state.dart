part of 'payment_qr_bloc.dart';

final class PaymentQrState extends Equatable {
  const PaymentQrState({this.loaded = false, this.qrs = const []});

  final bool loaded;
  final List<PaymentQr> qrs;

  @override
  List<Object?> get props => [loaded, qrs];
}
