import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';

class FacturasServices{
  final String _baseUrl = 'http:${Constantes.baseUrl}facturacion/';

  Future<String> facturarVenta(Cfdi cfdi) async {
    try {
      final url = Uri.parse('${_baseUrl}crear');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cfdi.toJson()),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        print(data);
        return 'exito';
      } else {
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      return 'Hubo un problema al crear la factura.\n$e';
    }
  }
}
// 251115B01