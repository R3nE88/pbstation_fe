import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/models.dart';

class Ventas {
  Ventas({
    this.id,
    this.folio,
    required this.clienteId,
    required this.usuarioId,
    required this.sucursalId,
    required this.pedidoPendiente,
    this.fechaEntrega,
    required this.detalles,
    this.fechaVenta,
    this.comentariosVenta,
    required this.subTotal,
    required this.descuento,
    required this.iva,
    required this.total,
    this.tipoTarjeta,
    this.referenciaTarj,
    this.referenciaTrans,
    this.recibidoMxn,
    this.recibidoUs,
    this.recibidoTarj,
    this.recibidoTrans,
    required this.recibidoTotal,
    this.abonadoMxn,
    this.abonadoUs,
    this.abonadoTarj,
    this.abonadoTrans,
    Decimal? abonadoTotal,
    Decimal? cambio,
    required this.liquidado,
    bool? wasDeuda,
  })  : abonadoTotal = abonadoTotal ?? Decimal.parse('0'),
        cambio = cambio ?? Decimal.parse('0'),
        wasDeuda = wasDeuda ?? false;

  String? id;
  String? folio;
  String clienteId;
  String usuarioId;
  String sucursalId;
  bool pedidoPendiente;
  String? fechaEntrega;
  List<DetallesVenta> detalles;
  String? fechaVenta;
  String? comentariosVenta;
  Decimal subTotal; 
  Decimal descuento; 
  Decimal iva; 
  Decimal total; 
  String? tipoTarjeta; 
  String? referenciaTarj; 
  String? referenciaTrans;
  Decimal? recibidoMxn;
  Decimal? recibidoUs;
  Decimal? recibidoTarj;
  Decimal? recibidoTrans;
  Decimal recibidoTotal;
  Decimal? abonadoMxn;
  Decimal? abonadoUs;
  Decimal? abonadoTarj;
  Decimal? abonadoTrans;
  Decimal abonadoTotal; 
  Decimal cambio;
  bool liquidado;
  bool wasDeuda;

  factory Ventas.fromJson(String str) => Ventas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Ventas.fromMap(Map<String, dynamic> json) => Ventas(
    id: json['id']?.toString(),
    folio: json['folio'],
    clienteId: json['cliente_id'],
    usuarioId: json['usuario_id'],
    sucursalId: json['sucursal_id'],
    pedidoPendiente: json['pedido_pendiente'],
    fechaEntrega: json['fecha_entrega'],
    detalles: List<DetallesVenta>.from(
      json['detalles'].map((x) => DetallesVenta.fromMap(x as Map<String, dynamic>)),
    ),
    fechaVenta: json['fecha_venta'],
    comentariosVenta: json['comentarios_venta'],
    subTotal: Decimal.parse(json['subtotal']),
    descuento: Decimal.parse(json['descuento']),
    iva: Decimal.parse(json['iva']),
    total: Decimal.parse(json['total']),
    tipoTarjeta: json['tipo_tarjeta'],
    referenciaTarj: json['referencia_tarj'],
    referenciaTrans: json['referencia_trans'],
    recibidoMxn: json['recibido_mxn']!=null ? Decimal.parse(json['recibido_mxn']) : null, 
    recibidoUs: json['recibido_us']!=null ? Decimal.parse(json['recibido_us']) : null, 
    recibidoTarj: json['recibido_tarj']!=null ? Decimal.tryParse(json['recibido_tarj']): null, 
    recibidoTrans: json['recibido_trans']!=null ? Decimal.tryParse(json['recibido_trans']): null, 
    recibidoTotal : Decimal.parse(json['recibido_total']),
    abonadoMxn: json['abonado_mxn']!=null ? Decimal.tryParse(json['abonado_mxn']): null, 
    abonadoUs: json['abonado_us']!=null ? Decimal.tryParse(json['abonado_us']): null, 
    abonadoTarj: json['abonado_tarj']!=null ? Decimal.tryParse(json['abonado_tarj']): null, 
    abonadoTrans: json['abonado_trans']!=null ? Decimal.tryParse(json['abonado_trans']): null,
    abonadoTotal: Decimal.parse(json['abonado_total']), 
    cambio: Decimal.parse(json['cambio']), 
    liquidado: json['liquidado'],
    wasDeuda: json['was_deuda'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'folio': folio,
    'cliente_id': clienteId,
    'usuario_id': usuarioId,
    'sucursal_id': sucursalId,
    'pedido_pendiente': pedidoPendiente,
    'fecha_entrega': fechaEntrega,
    'detalles': detalles.map((d) => d.toMap()).toList(),
    'fecha_venta': fechaVenta,
    'comentarios_venta': comentariosVenta,
    'subtotal': subTotal,
    'descuento': descuento,
    'iva': iva,
    'total': total,
    'tipo_tarjeta':tipoTarjeta,
    'referencia_tarj':referenciaTarj,
    'referencia_trans':referenciaTrans,
    'recibido_mxn':recibidoMxn,
    'recibido_us': recibidoUs,
    'recibido_tarj': recibidoTarj,
    'recibido_trans': recibidoTrans,
    'recibido_total': recibidoTotal,
    'abonado_mxn': abonadoMxn,
    'abonado_us': abonadoUs,
    'abonado_tarj': abonadoTarj,
    'abonado_trans': abonadoTrans,
    'abonado_total': abonadoTotal,
    'cambio': cambio,
    'liquidado':liquidado,
    'was_deuda':wasDeuda,
  };
}