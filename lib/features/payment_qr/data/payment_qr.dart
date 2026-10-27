import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/pref_keys.dart';

/// A saved payment QR image. Mirrors `PaymentQr` in android/.../payments/PaymentQrs.kt.
class PaymentQr extends Equatable {
  const PaymentQr({required this.id, required this.name, required this.path});

  factory PaymentQr.fromJson(Map<String, Object?> json) => PaymentQr(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        path: json['path'] as String? ?? '',
      );

  final String id;
  final String name;

  /// Absolute path of the copy in the app's private files dir.
  final String path;

  PaymentQr copyWith({String? name}) => PaymentQr(id: id, name: name ?? this.name, path: path);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'path': path};

  @override
  List<Object?> get props => [id, name, path];
}

/// Copies picked images into private storage (the original can be deleted from the gallery)
/// and stores the list where the tile reads it.
class PaymentQrRepository {
  const PaymentQrRepository();

  Future<List<PaymentQr>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.paymentQrs);
    if (raw == null) return const [];
    try {
      return [for (final q in jsonDecode(raw) as List) PaymentQr.fromJson(q as Map<String, Object?>)];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<PaymentQr> qrs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.paymentQrs, jsonEncode([for (final q in qrs) q.toJson()]));
  }

  /// Copies [source] into the app's files dir and returns the new entry (not yet saved).
  Future<PaymentQr> import(String source, String name) async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/payment_qr');
    await dir.create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final ext = source.contains('.') ? source.substring(source.lastIndexOf('.')) : '.png';
    final copy = await File(source).copy('${dir.path}/$id$ext');
    return PaymentQr(id: id, name: name, path: copy.path);
  }

  Future<void> deleteFile(PaymentQr qr) async {
    final file = File(qr.path);
    if (await file.exists()) await file.delete();
  }
}
