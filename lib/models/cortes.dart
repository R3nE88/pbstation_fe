import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/models.dart';

class Cortes {
    Cortes({
      this.id,
      this.folio,
      required this.usuarioId,
      this.usuarioIdCerro,
      required this.sucursalId,
      required this.fechaApertura,
      this.fechaCorte,
      this.contadoresFinales,
      required this.fondoInicial,
      this.proximoFondo,
      this.conteoPesos,
      this.conteoDolares,
      this.conteoDebito,
      this.conteoCredito,
      this.conteoTransf,
      this.conteoTotal,
      this.ventaPesos,
      this.ventaDolares,
      this.ventaDebito,
      this.ventaCredito,
      this.ventaTransf,
      this.ventaTotal,
      this.diferencia,
      required this.movimientosCaja,
      this.desglosePesos,
      this.desgloseDolares,
      required this.ventasIds,
      this.comentarios,
      this.isCierre = false,
    });

    String? id;
    String? folio;
    String usuarioId;
    String? usuarioIdCerro;
    String sucursalId;
    String fechaApertura; 
    String? fechaCorte; 
    Map<String, int>? contadoresFinales;
    Decimal fondoInicial;
    Decimal? proximoFondo;
    Decimal? conteoPesos;
    Decimal? conteoDolares;
    Decimal? conteoDebito;
    Decimal? conteoCredito;
    Decimal? conteoTransf;
    Decimal? conteoTotal;
    Decimal? ventaPesos;
    Decimal? ventaDolares;
    Decimal? ventaDebito;
    Decimal? ventaCredito;
    Decimal? ventaTransf;
    Decimal? ventaTotal;
    Decimal? diferencia;
    List<MovimientosCajas> movimientosCaja;
    List<Desglose>? desglosePesos;
    List<Desglose>? desgloseDolares;
    List<String> ventasIds;
    String? comentarios;
    bool isCierre; 

    factory Cortes.fromJson(String str) => Cortes.fromMap(json.decode(str));
    String toJson() => json.encode(toMap());

    factory Cortes.fromMap(Map<String, dynamic> json) => Cortes(
      id: json['id']?.toString(),
      folio: json['folio'],
      usuarioId: json['usuario_id'],
      usuarioIdCerro: json['usuario_id_cerro'],
      sucursalId: json['sucursal_id'],
      fechaApertura: json['fecha_apertura'],
      fechaCorte: json['fecha_corte'],
      contadoresFinales: json['contadores_finales'] != null ? Map<String, int>.from(json['contadores_finales']) : null,
      fondoInicial: Decimal.parse(json['fondo_inicial']),
      proximoFondo: json['proximo_fondo'] != null ? Decimal.parse(json['proximo_fondo']) : null,
      conteoPesos: json['conteo_pesos'] != null ? Decimal.parse(json['conteo_pesos']) : null,
      conteoDolares: json['conteo_dolares'] != null ? Decimal.parse(json['conteo_dolares']) : null,
      conteoDebito: json['conteo_debito'] != null ? Decimal.parse(json['conteo_debito']) : null,
      conteoCredito: json['conteo_credito'] != null ? Decimal.parse(json['conteo_credito']) : null,
      conteoTransf: json['conteo_transf'] != null ? Decimal.parse(json['conteo_transf']) : null,
      conteoTotal: json['conteo_total'] != null ? Decimal.parse(json['conteo_total']) : null,
      ventaPesos: json['venta_pesos'] != null ? Decimal.parse(json['venta_pesos']) : null,
      ventaDolares: json['venta_dolares'] != null ? Decimal.parse(json['venta_dolares']) : null,
      ventaDebito: json['venta_debito'] != null ? Decimal.parse(json['venta_debito']) : null,
      ventaCredito: json['venta_credito'] != null ? Decimal.parse(json['venta_credito']) : null,
      ventaTransf: json['venta_transf'] != null ? Decimal.parse(json['venta_transf']) : null,
      ventaTotal: json['venta_total'] != null ? Decimal.parse(json['venta_total']) : null,
      diferencia: json['diferencia'] != null ? Decimal.parse(json['diferencia']) : null,
      movimientosCaja: List<MovimientosCajas>.from(
        json['movimiento_caja'].map((x) => MovimientosCajas.fromMap(x as Map<String, dynamic>)),
      ),
      desglosePesos: json['desglose_pesos'] != null
        ? List<Desglose>.from(json['desglose_pesos'].map((x) => Desglose.fromMap(x)))
        : null,
      desgloseDolares: json['desglose_dolares'] != null
        ? List<Desglose>.from(json['desglose_dolares'].map((x) => Desglose.fromMap(x)))
        : null,
      ventasIds: List<String>.from(json['ventas_ids'] ?? []),
      comentarios: json['comentarios'],
      isCierre: json['is_cierre'] ?? false,
    );

    Map<String, dynamic> toMap() => {
      'id': id,
      'folio': folio,
      'usuario_id': usuarioId,
      'usuario_id_cerro': usuarioIdCerro,
      'sucursal_id': sucursalId,
      'fecha_apertura': fechaApertura,
      'fecha_corte': fechaCorte,
      'contadores_finales': contadoresFinales,
      'fondo_inicial': fondoInicial,
      'proximo_fondo': proximoFondo,
      'conteo_pesos': conteoPesos,
      'conteo_dolares': conteoDolares,
      'conteo_debito': conteoDebito,
      'conteo_credito': conteoCredito,
      'conteo_transf': conteoTransf,
      'conteo_total': conteoTotal,
      'venta_pesos': ventaPesos,
      'venta_dolares': ventaDolares,
      'venta_debito': ventaDebito,
      'venta_credito': ventaCredito,
      'venta_transf': ventaTransf,
      'venta_total': ventaTotal,
      'diferencia': diferencia,
      'movimiento_caja': List<dynamic>.from(movimientosCaja.map((x) => x.toMap())),
      'desglose_pesos': desglosePesos?.map((x) => x.toMap()).toList(),
      'desglose_dolares': desgloseDolares?.map((x) => x.toMap()).toList(),
      'ventas_ids': ventasIds,
      'comentarios': comentarios,
      'is_cierre': isCierre,
    };
}

class Desglose {
  final double denominacion;
  final int cantidad;

  Desglose({
    required this.denominacion,
    required this.cantidad,
  });

  factory Desglose.fromMap(Map<String, dynamic> json) => Desglose(
        denominacion: (json['denominacion'] as num).toDouble(),
        cantidad: json['cantidad'] as int,
      );

  Map<String, dynamic> toMap() => {
        'denominacion': denominacion,
        'cantidad': cantidad,
      };
}