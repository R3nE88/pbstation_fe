import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/services/cajas_services.dart';
import 'package:pbstation_frontend/services/configuracion.dart';
import 'package:pbstation_frontend/theme/theme.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUsbDevices();
    _selectedDevice = Configuracion.impresora;
  }

  Future<void> _loadUsbDevices() async {
    try {
      List<UsbDevice> usbDevices = await PrintUsb.getList();
      List<String> usbstring = [];
      for (var device in usbDevices) {
        usbstring.add(device.name);
      }
      setState(() {
        _devices = usbstring;
      });
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
  
  @override
  Widget build(BuildContext context) {
    final changeTheme = Provider.of<ChangeTheme>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text('Modo Oscuro', style: AppTheme.subtituloConstraste,),
            Switch(value: changeTheme.isDarkTheme, onChanged: ( value ){
              changeTheme.isDarkTheme = value;
            }),
          ],
        ),

        ElevatedButton(
          onPressed: (){
            final cajaSvc = Provider.of<CajasServices>(context, listen: false);
            cajaSvc.eliminarCajaActualSoloDePrueba();
          }, 
          child: Text('Elimitar Caja Actual')
        ),


        Column(
          children: [
            Text('Seleccionar impresora para tickets', style: AppTheme.subtituloConstraste),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primario2,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: DropdownButton<String>(
                  hint: Text('Selecciona un dispositivo USB'),
                  value: _selectedDevice,
                  items: _devices.map((String device) {
                    return DropdownMenuItem<String>(
                      value: device,
                      child: Text(device, style: AppTheme.subtituloConstraste),
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
            ),
          ],
        ),

        Text(
          'Sistema en constante desarrollo.\nEl entorno no es definitivo y puede sufrir cambios\n\nEstoy abierto al feedback, ideas, y/o sugerencias.\nFavor de Reportar problemas y bugs a:\nR3nE88.pb@gmail.com',
          style: AppTheme.subtituloConstraste,
          textAlign: TextAlign.center,
         ),

      ],
    );
  }
}