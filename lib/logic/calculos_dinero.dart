import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/detalles_venta.dart';
import 'package:pbstation_frontend/services/configuracion.dart';

class CalculosDinero {

  Decimal leerIva(){
    return Decimal.parse((Configuracion.iva/100).toString());
  }

  Map<String, dynamic> calcularSubtotal (Decimal productoPrecio, int productoCantidad, int descuento){
    Decimal subtotal = productoPrecio * Decimal.fromInt(productoCantidad);

    Decimal descuentoAplicado = subtotal * (Decimal.fromInt(descuento) / Decimal.fromInt(100)).toDecimal();
    Decimal totalSinIva = subtotal-descuentoAplicado;

    Decimal iva = totalSinIva * leerIva().round(scale: 2);
    Decimal total = (totalSinIva + iva).round(scale: 1); 

    return {
      'descuento' : descuentoAplicado,
      'iva' : iva.toDouble(),
      'total' : total.toDouble()
    };
  }

  Map<String, dynamic> calcularSubtotalConMedida (Decimal productoPrecio, int productoCantidad, Decimal ancho, Decimal alto, int descuento){ 
    Decimal subtotal = productoPrecio * Decimal.fromInt(productoCantidad);
    Decimal totalMedida = ((ancho * alto) * subtotal);
  
    Decimal descuentoAplicado = totalMedida * (Decimal.fromInt(descuento) / Decimal.fromInt(100)).toDecimal();
    Decimal totalSinIva = totalMedida-descuentoAplicado;

    Decimal iva = totalSinIva * leerIva().round(scale: 2);
    Decimal total = (totalSinIva + iva).round(scale: 1); 

    return {
      'descuento' : descuentoAplicado,
      'iva' : iva.toDouble(),
      'total' : total.toDouble()
    };
  }

  Map<String, double> calcularTotal(List<DetallesVenta> detallesVenta){
    Decimal subtotal = Decimal.parse('0');
    Decimal totalDescuento = Decimal.parse('0');
    Decimal totalIva = Decimal.parse('0');
    Decimal total = Decimal.parse('0');

    for (var detalle in detallesVenta) {
      subtotal += detalle.subtotal-detalle.iva+detalle.descuentoAplicado;
      totalDescuento += detalle.descuentoAplicado;
      totalIva += detalle.iva;
      total += detalle.subtotal;
    }

    return {
      'subtotal' : subtotal.toDouble(),
      'descuento' : totalDescuento.toDouble(),
      'iva' : totalIva.toDouble(),
      'total' : total.toDouble(),
    };
  }

  double dolarAPesos(double importe){
    Decimal imp = Decimal.parse(importe.toString());
    Decimal precioDolar = Decimal.parse(Configuracion.dolar.toString());
    Decimal total = (imp * precioDolar).round(scale: 2);
    return total.toDouble();
  }

  double pesosADolar(double importe){
    Decimal imp = Decimal.parse(importe.toString());
    Decimal precioDolar = Decimal.parse(Configuracion.dolar.toString());
    Decimal total = (imp / precioDolar).toDecimal();
    return total.toDouble();
  }

  Decimal calcularConIva(Decimal precio){
    Decimal iva = Decimal.parse(precio.toString()) * leerIva().round(scale: 6);
    return iva + precio; 
  }

  Decimal calcularSinIva(Decimal precioConIva) {
    Decimal iva = leerIva();
    Decimal base = Decimal.fromInt(1) + iva;
    Decimal precioSinIva = (precioConIva / base).toDecimal(scaleOnInfinitePrecision: 6);
    return precioSinIva;
  }

}

//8000 tabloides round0 = 80,006.00
//8000 tabloides round1 = 80,006.40
//8000 tabloides round2 = 80,006.40

//50,000 tabloides round0 = 500,040.00
//50,000 tabloides round1 = 500,040.00
//50,000 tabloides round2 = 500,040.00
