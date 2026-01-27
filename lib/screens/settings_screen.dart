import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/windows_bar.dart';
import 'package:print_usb/model/usb_device.dart';
import 'package:print_usb/print_usb.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _devices = [];
  String? _selectedDevice;

  final List<String> _sizes = ['58mm', '72mm', '80mm'];
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedDevice = Configuracion.impresora;
    _selectedSize = Configuracion.size;
    _loadUsbDevices();
  }

  Future<void> _loadUsbDevices() async {
    try {
      List<UsbDevice> usbDevices = await PrintUsb.getList();
      List<String> usbstring = [];
      for (var device in usbDevices) {
        usbstring.add(device.name);
      }
      _devices = usbstring;
      if (!_devices.contains(_selectedDevice)){
        _selectedDevice = null;
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error loading USB devices: $e');
      }
    }
  }

  Future<void> _saveSelectedDevice(String device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedUsbDevice', device);
    Configuracion.impresora = device;
  }

  Future<void> _saveSelectedSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSize', size);
    Configuracion.size = size;
  }
  
  @override
  Widget build(BuildContext context) {
    final changeTheme = Provider.of<ChangeTheme>(context);
    final config = Provider.of<Configuracion>(context);

    _devices;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         
          const Expanded(child: Column()),
          
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            
                Column(
                  children: [
                    Text('Modo Oscuro', style: AppTheme.subtituloConstraste,),
                    Switch(
                      value: changeTheme.isDarkTheme, 
                      activeThumbColor: Colors.grey,
                      onChanged: ( value ) async {
                      changeTheme.setIsDarkTheme(value, true);
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool('isDarkTheme', value);
                      }
                    ),
                  ],
                ),
            
                /*ElevatedButton(
                  onPressed: () async{
                    Provider.of<LoadingProvider>(context, listen: false).show();
                    await Future.delayed(const Duration(seconds: 5));
                    Provider.of<LoadingProvider>(context, listen: false).hide();
                  }, 
                  child: const Text('Probar cosas')
                ),*/
            
                Column(
                  children: [
                    Text('Seleccionar impresora para tickets', style: AppTheme.subtituloConstraste),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: AppTheme.isDarkTheme?AppTheme.primario1:AppTheme.primario2,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text('Selecciona un dispositivo USB'),
                          value: _selectedDevice,
                          iconEnabledColor: Colors.white,
                          dropdownColor: AppTheme.isDarkTheme?AppTheme.tablaColorHeader:AppTheme.tablaColorHeader,
                          items: _devices.map((String device) {
                            return DropdownMenuItem<String>(
                              value: device,
                              child: Text(device, style: AppTheme.subtituloPrimario),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedDevice = newValue;
                              });
                              _saveSelectedDevice(newValue);
                            }
                          },
                        ),
                      ),
                    ), const SizedBox(height: 15),

                    Text('Tamaño de papel', style: AppTheme.subtituloConstraste),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: AppTheme.isDarkTheme?AppTheme.primario1:AppTheme.primario2,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text('Selecciona un tamaño'),
                          value: _selectedSize,
                          iconEnabledColor: Colors.white,
                          dropdownColor: AppTheme.isDarkTheme?AppTheme.tablaColorHeader:AppTheme.tablaColorHeader,
                          items: _sizes.map((String size) {
                            return DropdownMenuItem<String>(
                              value: size,
                              child: Text(size, style: AppTheme.subtituloPrimario),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedSize = newValue;
                              });
                              _saveSelectedSize(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            
                //const Spacer(),

                const SizedBox(height: 25),
            
                Text(
                  'Sistema en constante desarrollo.\nEl entorno no es definitivo y puede sufrir cambios\n\nEstoy abierto al feedback, ideas, y/o sugerencias.\nFavor de Reportar problemas y bugs a:\nR3nE88.pb@gmail.com',
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                 ),
            
              ],
            ),
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.isDarkTheme?AppTheme.primario2:AppTheme.secundario1,
                    borderRadius: BorderRadius.circular(14)
                  ),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          CajasServices.cajaActual!=null && Configuracion.dolar != CajasServices.cajaActual?.tipoCambio ? 
                          Text('Dolar: ${Formatos.moneda.format(Configuracion.dolar)}  (De caja: ${Formatos.moneda.format(CajasServices.cajaActual!.tipoCambio)})', style: AppTheme.subtituloPrimario)
                          :
                          Text('Dolar: ${Formatos.moneda.format(Configuracion.dolar)}', style: AppTheme.subtituloPrimario),
                          Tooltip(
                            message: Login.usuarioLogeado.permisos == Permiso.admin ? '' : 'No tienes permisos para cambiar el precio del dolar',
                            child: Transform.scale(
                              scale: 0.8,
                              child: ElevatedButton(
                                onPressed: Login.usuarioLogeado.permisos == Permiso.admin ? 
                                () => showDialog(
                                  context: context,
                                  builder: (_) => Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      cambiarDolar(context, config),
                                      const WindowBar(overlay: true),
                                    ],
                                  ),
                                )
                                : null, 
                                 style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(AppTheme.isDarkTheme?AppTheme.primario1:AppTheme.primario2)
                                ),
                                child: const Text('Cambiar Tipo de Cambio', style: AppTheme.subtituloPrimario)
                              )
                            ),
                          )
                        ]
                      ), const SizedBox(height: 15),
                      Column(
                        children: [
                          Text('IVA: ${Formatos.numero.format(Configuracion.iva)}%', style: AppTheme.subtituloPrimario,),
                          Tooltip(
                            message: Login.usuarioLogeado.permisos == Permiso.admin ? '' : 'No tienes permisos para cambiar el porcentaje del iva',
                            child: Transform.scale(
                              scale: 0.8,
                              child: ElevatedButton(
                                onPressed: Login.usuarioLogeado.permisos == Permiso.admin ? 
                                () => showDialog(
                                  context: context,
                                  builder: (_) => Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      cambiarIVA(context, config),
                                      const WindowBar(overlay: true),
                                    ],
                                  ),
                                )
                                : null, 
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(AppTheme.isDarkTheme?AppTheme.primario1:AppTheme.primario2)
                                ),
                                child: const Text('Cambiar IVA', style: AppTheme.subtituloPrimario)
                              )
                            ),
                          )
                        ]
                      ),
                    ],
                  ),
                ),
              ],
            )
          ),        
        ],
      ),
    );
  }

  AlertDialog cambiarDolar(BuildContext context, config) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void submited() async{
      if (!formKey.currentState!.validate()) return;
      double tc = double.parse(controller.text.replaceAll('MX\$', '').replaceAll(',', ''));
      bool exito = await config.actualizarPrecioDolar(tc);
      if (exito){
        if (!context.mounted) return;
        Navigator.pop(context);
      }
    }

    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Column(
        children: [
          Text(
            'El precio del dólar se actualizará en todas las sucursales.',
            textAlign: TextAlign.center, style: AppTheme.tituloPrimario, textScaler: TextScaler.linear(0.65)
          ),
          Text(
            'Si alguna caja está abierta, el cambio se aplicará\nla próxima vez que se abra una nueva caja.',
            textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.63)
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextFormField(
                  controller: controller,
                  inputFormatters: [ PesosInputFormatter() ],
                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                  decoration: const InputDecoration(
                    labelText: 'precio del dolar',
                    labelStyle: AppTheme.labelStyle,
                  ),
                  autofocus: true,
                  maxLength: 8,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el precio del dolar-';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) => submited(),
                ),
              ),const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context, false);
                    }, 
                    child: const Text('Regresar')
                  ),

                  ElevatedButton(
                    onPressed: () => submited(),
                    child: const Text('Continuar')
                  ),
                ],
              ),
            ],
          )
        )
      ),
    );
  }

  AlertDialog cambiarIVA(BuildContext context, Configuracion config) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void submited() async{
      if (!formKey.currentState!.validate()) return;
      int iva = int.parse(controller.text.replaceAll(',', ''));
      bool exito = await config.actualizarIva(iva);
      if (exito){
        if (!context.mounted) return;
        Navigator.pop(context);
      }
    }

    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Column(
        children: [
          Text(
            'El porcentaje del iva se actualizara en todas\nlas sucursales',
            textAlign: TextAlign.center, style: AppTheme.tituloPrimario, textScaler: TextScaler.linear(0.65)
          ),
          Text(
            'Al cambiar el IVA, los precios de los artículos s\nautomáticamente. Asegúrese de que\ndesea continuar antes de aplicar el cambio.',
            textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.63)
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextFormField(
                  controller: controller,
                  inputFormatters: [ NumericFormatter() ],
                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                  decoration: const InputDecoration(
                    labelText: 'porcentaje del iva %18',
                    labelStyle: AppTheme.labelStyle,
                  ),
                  autofocus: true,
                  maxLength: 2,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el porcentaje del iva-';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) => submited(),
                ),
              ),const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context, false);
                    }, 
                    child: const Text('Regresar')
                  ),

                  ElevatedButton(
                    onPressed: () => submited(),
                    child: const Text('Continuar')
                  ),
                ],
              ),
            ],
          )
        )
      ),
    );
  }
}