class Cfdi {
  final String cfdiType;
  final String expeditionPlace;
  final String paymentForm;
  final String paymentMethod;
  final Receiver receiver;
  final List<CfdiItem> items;

  Cfdi({
    required this.cfdiType,
    required this.expeditionPlace,
    required this.paymentForm,
    required this.paymentMethod,
    required this.receiver,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'CfdiType': cfdiType,
        'ExpeditionPlace': expeditionPlace,
        'PaymentForm': paymentForm,
        'PaymentMethod': paymentMethod,
        'Receiver': receiver.toJson(),
        'Items': items.map((x) => x.toJson()).toList(),
      };
}

class Receiver {
  final String rfc;
  final String name;
  final String cfdiUse;
  final String fiscalRegime;
  final String taxZipCode;

  Receiver({
    required this.rfc,
    required this.name,
    required this.cfdiUse,
    required this.fiscalRegime,
    required this.taxZipCode,
  });

  Map<String, dynamic> toJson() => {
        'Rfc': rfc,
        'Name': name,
        'CfdiUse': cfdiUse,
        'FiscalRegime': fiscalRegime,
        'TaxZipCode': taxZipCode,
      };
}

class CfdiItem {
  final String productCode;
  final String description;
  final String unit;
  final String unitCode;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final String taxObject;
  final List<CfdiTax> taxes;
  final double total;

  CfdiItem({
    required this.productCode,
    required this.description,
    required this.unit,
    required this.unitCode,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.taxObject,
    required this.taxes,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'ProductCode': productCode,
        'Description': description,
        'Unit': unit,
        'UnitCode': unitCode,
        'Quantity': quantity,
        'UnitPrice': unitPrice,
        'Subtotal': subtotal,
        'TaxObject': taxObject,
        'Taxes': taxes.map((x) => x.toJson()).toList(),
        'Total': total,
      };
}

class CfdiTax {
  final String name;
  final double rate;
  final double total;
  final double base;
  final bool isRetention;

  CfdiTax({
    required this.name,
    required this.rate,
    required this.total,
    required this.base,
    required this.isRetention,
  });

  Map<String, dynamic> toJson() => {
        'Name': name,
        'Rate': rate,
        'Total': total,
        'Base': base,
        'IsRetention': isRetention,
      };
}
