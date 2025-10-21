
// ignore: unused_element
class _Documentacion {
  //TODO: IMPORTANTE CREAR LA BUILD ASI: flutter build windows --release --obfuscate --split-debug-info=build/debug-info --tree-shake-icons

  //Lugares donde se formatea dinero
  //VENTA.dart (ninguno de estos usa el inputFormatter, cada uno se formateo desde el metodo que hace los calculos)
    ///precioController
    ///IvaController
    ///productoTotalController
    ///
    ///subtotalController
    ///totalDescuentoController
    ///totalIvaController
    ///totalController    
  //PRODUCTOS_FORM.dart (este si usa formatter)
    ///controllers['precio']!,

    ///final String fechaFormateada = DateFormat('EEEE dd-MMM-yyyy hh:mm a', 'es_MX').format(fecha);

  // ESPERAR TIEMPO
  //await Future.delayed(const Duration(seconds: 2));

  //Establecer un limite en TextFormField y no mostrar el contador de caracteres restantes
  //buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,       
  // maxLength: 6,

  //Solo digitos sin formatear
  //inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],

  /* //ANTES USABA ESTO PARA DARLE EL FORMATO A LOS NUMEROS CON ,
  inputFormatters:[
    FilteringTextInputFormatter.digitsOnly, // Solo números enteros positivos
    CurrencyInputFormatter(
      leadingSymbol: '',
      useSymbolPadding: false,
      thousandSeparator: ThousandSeparator.Comma,
      mantissaLength: 0, // sin decimales
    ),
  ], 
  //AHORA SIMPLEMENTE USAMOS: 
  inputFormatters: [ NumericFormatter() ],
  

WidgetsBinding.instance.addPostFrameCallback((_) {
      final cajasService = Provider.of<CajasServices>(context, listen: false);
      cajasService.cargarHistorialCajas();
    });




  */

  


}