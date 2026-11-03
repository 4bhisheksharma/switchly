part of 'payment_qr_bloc.dart';

final class PaymentQrState extends Equatable {
  const PaymentQrState({
    this.loaded = false,
    this.qrs = const [],
    this.maxBrightness = true,
  });

  final bool loaded;
  final List<PaymentQr> qrs;
  final bool maxBrightness;

  PaymentQrState copyWith({
    bool? loaded,
    List<PaymentQr>? qrs,
    bool? maxBrightness,
  }) =>
      PaymentQrState(
        loaded: loaded ?? this.loaded,
        qrs: qrs ?? this.qrs,
        maxBrightness: maxBrightness ?? this.maxBrightness,
      );

  @override
  List<Object?> get props => [loaded, qrs, maxBrightness];
}
