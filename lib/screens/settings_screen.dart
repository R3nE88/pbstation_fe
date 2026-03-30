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
      if (!_devices.contains(_selectedDevice)) {
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

  bool get _isAdmin => Login.usuarioLogeado.permisos == Permiso.admin;

  @override
  Widget build(BuildContext context) {
    final changeTheme = Provider.of<ChangeTheme>(context);
    final config = Provider.of<Configuracion>(context);

    return Padding(
      padding: const EdgeInsets.only(right: 24, left: 24, top: 20),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              children: [
                // ── Apariencia ──
                _SettingsSection(
                  icon: Icons.palette_outlined,
                  title: 'Apariencia',
                  children: [
                    _SettingsTile(
                      icon: changeTheme.isDarkTheme
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: 'Modo Oscuro',
                      subtitle: changeTheme.isDarkTheme
                          ? 'Tema oscuro activado'
                          : 'Tema claro activado',
                      trailing: Switch(
                        value: changeTheme.isDarkTheme,
                        thumbColor: WidgetStateProperty.all(AppTheme.letraClara),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) return AppTheme.primario1;
                          return AppTheme.primario1.withAlpha(80);
                        }),
                        onChanged: (value) async {
                          changeTheme.setIsDarkTheme(value, true);
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setBool('isDarkTheme', value);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Impresora ──
                _SettingsSection(
                  icon: Icons.print_outlined,
                  title: 'Impresora',
                  children: [
                    _SettingsTile(
                      icon: Icons.usb_rounded,
                      title: 'Impresora de Tickets',
                      subtitle: _selectedDevice ?? 'Sin dispositivo seleccionado',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _loadUsbDevices,
                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.letraClara),
                            tooltip: 'Refrescar dispositivos',
                            iconSize: 20,
                          ),
                          const SizedBox(width: 4),
                          _buildDropdown<String>(
                            value: _selectedDevice,
                            hint: 'Seleccionar',
                            items: _devices,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDevice = val);
                                _saveSelectedDevice(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _SettingsTile(
                      icon: Icons.straighten_rounded,
                      title: 'Tamaño de papel (Impresora de Tickets)',
                      subtitle: _selectedSize ?? '58mm',
                      trailing: _buildDropdown<String>(
                        value: _selectedSize,
                        hint: 'Tamaño',
                        items: _sizes,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSize = val);
                            _saveSelectedSize(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Configuración del Sistema (admin only) ──
                _SettingsSection(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Configuración del Sistema',
                  children: [
                    _SettingsTile(
                      icon: Icons.attach_money_rounded,
                      title: 'Tipo de Cambio (Dólar)',
                      subtitle: _buildDolarSubtitle(),
                      trailing: _buildEditButton(
                        onPressed: () => _showCambiarDolar(config),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _SettingsTile(
                      icon: Icons.percent_rounded,
                      title: 'IVA',
                      subtitle: '${Formatos.numero.format(Configuracion.iva)}%',
                      trailing: _buildEditButton(
                        onPressed: () => _showCambiarIVA(config),
                      ),
                    ),
                    if (_isAdmin) const Divider(height: 1, color: Colors.white12),
                    if (_isAdmin) _SettingsTile(
                      icon: Icons.system_update_alt_rounded,
                      title: 'Versión Mínima Requerida',
                      subtitle: Configuracion.lastVersion,
                      trailing: _buildEditButton(
                        onPressed: () => _showCambiarVersion(config),
                      ),
                      adminBadge: true,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Acerca del Sistema ──
                _SettingsSection(
                  icon: Icons.info_outline_rounded,
                  title: 'Acerca del Sistema',
                  children: [
                    _SettingsTile(
                      icon: Icons.apps_rounded,
                      title: 'Versión de la Aplicación',
                      subtitle: 'v${Constantes.version}',
                    ),
                    if(_isAdmin) const Divider(height: 1, color: Colors.white12),
                    if(_isAdmin) _SettingsTile(
                      icon: Icons.update_rounded,
                      title: 'Versión Mínima del Servidor',
                      subtitle: Configuracion.lastVersion,
                      adminBadge: true,
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _SettingsTile(
                      icon: Icons.computer_rounded,
                      title: 'Nombre del Equipo',
                      subtitle: Configuracion.nombrePC,
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _SettingsTile(
                      icon: Configuracion.esCaja
                          ? Icons.point_of_sale_rounded
                          : Icons.desktop_windows_rounded,
                      title: 'Tipo de Equipo',
                      subtitle: Configuracion.esCaja ? 'Caja registradora' : 'Estación de trabajo',
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    const _SettingsTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Contacto / Soporte',
                      subtitle: 'R3nE88.pb@gmail.com',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Sistema en constante desarrollo para PrinterBoy\nSan Luis Rio Colorado, Sonora, Mexico. 2026.',
                  style: TextStyle(
                    color: AppTheme.letraClara.withAlpha(100),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  String _buildDolarSubtitle() {
    final dolarStr = Formatos.moneda.format(Configuracion.dolar);
    if (CajasServices.cajaActual != null &&
        Configuracion.dolar != CajasServices.cajaActual?.tipoCambio) {
      final cajaStr = Formatos.moneda.format(CajasServices.cajaActual!.tipoCambio);
      return '$dolarStr  (En caja: $cajaStr)';
    }
    return dolarStr;
  }

  Widget _buildEditButton({required VoidCallback onPressed}) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_rounded, size: 15),
        label: const Text('Editar', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primario1,
          foregroundColor: AppTheme.letraClara,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primario1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          iconEnabledColor: Colors.white70,
          iconSize: 18,
          dropdownColor: AppTheme.tablaColorHeader,
          isDense: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text('$item', style: const TextStyle(color: Colors.white, fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Diálogos ──────────────────────────────────────────────

  void _showCambiarDolar(Configuracion config) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void submited() async {
      if (!formKey.currentState!.validate()) return;
      double tc = double.parse(controller.text.replaceAll('MX\$', '').replaceAll(',', ''));
      bool exito = await config.actualizarPrecioDolar(tc);
      if (exito) {
        if (!context.mounted) return;
        Navigator.pop(context);
      }
    }

    showDialog(
      context: context,
      builder: (_) => Stack(
        alignment: Alignment.topRight,
        children: [
          AlertDialog(
            elevation: 6,
            shadowColor: Colors.black54,
            backgroundColor: AppTheme.containerColor1,
            shape: AppTheme.borde,
            title: const Column(
              children: [
                Text(
                  'El precio del dólar se actualizará en todas las sucursales.',
                  textAlign: TextAlign.center, style: AppTheme.tituloPrimario, textScaler: TextScaler.linear(0.65),
                ),
                Text(
                  'Si alguna caja está abierta, el cambio se aplicará\nla próxima vez que se abra una nueva caja.',
                  textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.63),
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
                        inputFormatters: [PesosInputFormatter()],
                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                        decoration: const InputDecoration(
                          labelText: 'Precio del dólar',
                          labelStyle: AppTheme.labelStyle,
                        ),
                        autofocus: true,
                        maxLength: 8,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingrese el precio del dólar';
                          return null;
                        },
                        onFieldSubmitted: (_) => submited(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Regresar'),
                        ),
                        ElevatedButton(
                          onPressed: () => submited(),
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const WindowBar(overlay: true),
        ],
      ),
    );
  }

  void _showCambiarIVA(Configuracion config) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void submited() async {
      if (!formKey.currentState!.validate()) return;
      int iva = int.parse(controller.text.replaceAll(',', ''));
      bool exito = await config.actualizarIva(iva);
      if (exito) {
        if (!context.mounted) return;
        Navigator.pop(context);
      }
    }

    showDialog(
      context: context,
      builder: (_) => Stack(
        alignment: Alignment.topRight,
        children: [
          AlertDialog(
            backgroundColor: AppTheme.containerColor2,
            elevation: 6,
            shadowColor: Colors.black54,
            shape: AppTheme.borde,
            title: const Column(
              children: [
                Text(
                  'El porcentaje del IVA se actualizará en todas\nlas sucursales',
                  textAlign: TextAlign.center, style: AppTheme.tituloPrimario, textScaler: TextScaler.linear(0.65),
                ),
                Text(
                  'Al cambiar el IVA, los precios de los artículos se\nactualizarán automáticamente. Asegúrese de que\ndesea continuar antes de aplicar el cambio.',
                  textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.63),
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
                        inputFormatters: [NumericFormatter()],
                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                        decoration: const InputDecoration(
                          labelText: 'Porcentaje del IVA %',
                          labelStyle: AppTheme.labelStyle,
                        ),
                        autofocus: true,
                        maxLength: 2,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingrese el porcentaje del IVA';
                          return null;
                        },
                        onFieldSubmitted: (_) => submited(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Regresar'),
                        ),
                        ElevatedButton(
                          onPressed: () => submited(),
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const WindowBar(overlay: true),
        ],
      ),
    );
  }

  void _showCambiarVersion(Configuracion config) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void submited() async {
      if (!formKey.currentState!.validate()) return;
      String version = controller.text.trim();
      bool exito = await config.actualizarVersion(version);
      if (exito) {
        if (!mounted) return;
        Navigator.pop(context);
      }
    }

    showDialog(
      context: context,
      builder: (_) => Stack(
        alignment: Alignment.topRight,
        children: [
          AlertDialog(
            backgroundColor: AppTheme.containerColor1,
            elevation: 6,
            shadowColor: Colors.black54,
            shape: AppTheme.borde,
            title: const Column(
              children: [
                Text(
                  'Versión Mínima Requerida',
                  textAlign: TextAlign.center, style: AppTheme.tituloPrimario, textScaler: TextScaler.linear(0.65),
                ),
                SizedBox(height: 4),
                Text(
                  'Los clientes con una versión inferior a la especificada\nrecibirán una alerta para actualizar el sistema.',
                  textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.63),
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
                        decoration: InputDecoration(
                          labelText: 'Versión (ej: ${Configuracion.lastVersion})',
                          labelStyle: AppTheme.labelStyle,
                        ),
                        autofocus: true,
                        maxLength: 12,
                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese la versión';
                          }
                          final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
                          if (!versionRegex.hasMatch(value.trim())) {
                            return 'Formato inválido (use X.Y.Z)';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => submited(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Actual: ${Configuracion.lastVersion}',
                      style: TextStyle(color: AppTheme.letraClara.withAlpha(150), fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Regresar'),
                        ),
                        ElevatedButton(
                          onPressed: () => submited(),
                          child: const Text('Actualizar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const WindowBar(overlay: true),
        ],
      ),
    );
  }
}

// ─── Widgets reutilizables ──────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
    
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.isDarkTheme ? AppTheme.primario2 : AppTheme.primario1,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.letraClara, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.letraClara,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                
              ],
            ),
          ),
          // Content
          Container(
            decoration: BoxDecoration(
              color: AppTheme.isDarkTheme
                  ? Colors.black.withAlpha(30)
                  : Colors.black.withAlpha(15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool adminBadge;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.adminBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.letraClara.withAlpha(180), size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.letraClara,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.letraClara.withAlpha(140),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (adminBadge) ...[
            const SizedBox(width: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withAlpha(80), width: 0.5),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}