import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pbstation_frontend/env.dart';

/// Servicio de autenticación HMAC-SHA256
///
/// Genera headers seguros para cada petición HTTP usando:
/// - x-timestamp: Tiempo Unix en milisegundos
/// - x-signature: HMAC-SHA256(timestamp, secret_key)
///
/// El secret nunca viaja por la red, solo la firma.
class AuthService {
  /// Genera los headers de autenticación HMAC para usar en peticiones HTTP
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final resp = await http.get(
  ///   url,
  ///   headers: {...AuthService.getAuthHeaders()},
  /// );
  /// ```
  static Map<String, String> getAuthHeaders() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final signature = _generateSignature(timestamp);

    return {'x-timestamp': timestamp, 'x-signature': signature};
  }

  /// Genera firma HMAC-SHA256 a partir del timestamp
  static String _generateSignature(String timestamp) {
    final key = utf8.encode(Env.secretKey);
    final message = utf8.encode(timestamp);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(message);
    return digest.toString();
  }
}
