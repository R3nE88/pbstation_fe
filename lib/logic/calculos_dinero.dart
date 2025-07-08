import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/detalles_venta.dart';

class CalculosDinero {

  Map<String, dynamic> calcularSubtotal (Decimal productoPrecio, int productoCantidad, int descuento){
    Decimal subtotal = productoPrecio * Decimal.fromInt(productoCantidad);

    Decimal descuentoAplicado = subtotal * (Decimal.fromInt(descuento) / Decimal.fromInt(100)).toDecimal();
    Decimal totalSinIva = subtotal-descuentoAplicado;

    Decimal iva = totalSinIva * Decimal.parse('0.08'); //TODO: 8% de iva
    Decimal total = (totalSinIva + iva).round(scale: 0); 

    return {
      'descuento' : descuentoAplicado,
      'iva' : iva.toDouble(),
      'total' : total.toDouble()
    };
  }

  Map<String, dynamic> calcularSubtotalConMedida (Decimal productoPrecio, int productoCantidad, Decimal ancho, Decimal alto, int descuento){ 
    Decimal subtotal = productoPrecio * Decimal.fromInt(productoCantidad);
    Decimal totalMedida = ((ancho * alto) * subtotal);
  
    Decimal descuentoAplicado = subtotal * (Decimal.fromInt(descuento) / Decimal.fromInt(100)).toDecimal();
    Decimal totalSinIva = totalMedida-descuentoAplicado;

    Decimal iva = totalSinIva * Decimal.parse('0.08'); //TODO: 8% de iva
    Decimal total = (totalSinIva + iva).round(scale: 0); 

    return {
      'descuento' : descuentoAplicado,
      'iva' : iva.toDouble(),
      'total' : total.toDouble()
    };
  }

  Map<String, double> calcularTotal(List<DetallesVenta> detallesVenta){
    Decimal subtotal = Decimal.parse("0");
    Decimal totalDescuento = Decimal.parse("0");
    Decimal totalIva = Decimal.parse("0");
    Decimal total = Decimal.parse("0");

    for (var detalle in detallesVenta) {
      subtotal += detalle.subtotal-detalle.iva+detalle.descuentoAplicado;
      totalDescuento += detalle.descuentoAplicado; // Asumiendo que descuento es un porcentaje
      totalIva += detalle.iva; // Asumiendo que iva ya está calculado
      total += detalle.subtotal; // Total final
    }

    return {
      'subtotal' : subtotal.toDouble(),
      'descuento' : totalDescuento.toDouble(),
      'iva' : totalIva.toDouble(),
      'total' : total.toDouble(),
    };
  }

  double conversionADolar(double importe){
    Decimal imp = Decimal.parse(importe.toString());
    Decimal precioDolar = Decimal.parse("18.5");
    Decimal total = (imp * precioDolar).round(scale: 2);
    return total.toDouble();
  }
}

//8000 tabloides round0 = 80,006.00
//8000 tabloides round1 = 80,006.40
//8000 tabloides round2 = 80,006.40

//50,000 tabloides round0 = 500,040.00
//50,000 tabloides round1 = 500,040.00
//50,000 tabloides round2 = 500,040.00
