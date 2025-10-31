import 'dart:convert';

import 'package:pbstation_frontend/constantes.dart';

class Archivos {
  final String nombre;
  final String ruta;
  final String tipo;
  final int? tamano;

  Archivos({
    required this.nombre,
    required this.ruta,
    required this.tipo,
    this.tamano,
  });

  factory Archivos.fromMap(Map<String, dynamic> json) => Archivos(
        nombre: json['nombre'],
        ruta: json['ruta'],
        tipo: json['tipo'],
        tamano: json['tamano'],
      );

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'ruta': ruta,
        'tipo': tipo,
        'tamano': tamano,
      };
}

class Pedidos {
  String? id;
  String? folio;
  String clienteId;
  String usuarioId;
  String sucursalId;
  String ventaId;
  String ventaFolio;
  String? descripcion;
  String fecha;
  String fechaEntrega;
  List<Archivos> archivos;
  Estado estado;

  Pedidos({
    this.id,
    this.folio,
    required this.clienteId,
    required this.usuarioId,
    required this.sucursalId,
    required this.ventaId,
    required this.ventaFolio,
    this.descripcion,
    required this.fecha,
    required this.fechaEntrega,
    required this.archivos,
    this.estado = Estado.pendiente,
  });

  factory Pedidos.fromMap(Map<String, dynamic> json) => Pedidos(
        id: json['id']?.toString(),
        clienteId: json['cliente_id'],
        usuarioId: json['usuario_id'],
        sucursalId: json['sucursal_id'],
        ventaId: json['venta_id'],
        ventaFolio: json ['venta_folio'],
        folio: json['folio'],
        descripcion: json['descripcion'],
        fecha: json['fecha'],
        fechaEntrega: json['fecha_entrega'],
        archivos: (json['archivos'] as List)
            .map((a) => Archivos.fromMap(a))
            .toList(),
        estado: Estado.values.firstWhere(
        (e) => e.name == json['estado']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'cliente_id': clienteId,
        'usuario_id': usuarioId,
        'sucursal_id': sucursalId,
        'venta_id': ventaId,
        'venta_folio': ventaFolio,
        'folio': folio,
        'descripcion': descripcion,
        'fecha': fecha,
        'fecha_entrega': fechaEntrega,
        'archivos': archivos.map((a) => a.toMap()).toList(),
        'estado': estado.name,
      };

  factory Pedidos.fromJson(String str) => Pedidos.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
}
