import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

class VentaScreen extends StatefulWidget {
  const VentaScreen({super.key});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
    int indexSelected = 0;
    int pestanias = 2;
    int maximoPestanias = 4;

  @override
  Widget build(BuildContext context) {
    void agregarPestania() {
      if (pestanias >= maximoPestanias) {
        return;
      }
      setState(() {
        pestanias++;
      });
    }

    void selectedPestania(int index) {
      setState(() {
        indexSelected = index;
      });
    }

    return Padding(
      padding: const EdgeInsets.only(top:8, bottom: 5, left: 54, right: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox( //Pestañas
                height: 36,
                width: 500,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pestanias,
                  itemBuilder: (context, index) {
              
                    if (index == pestanias - 1) {
                      return Pestania(last: true, selected: false, agregarPestania: agregarPestania, index: index);
                    }
                    return Pestania(last: false, selected: index == indexSelected, selectedPestania: selectedPestania, index: index);
              
                  },
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: ElevatedButton(
                  onPressed: (){}, 
                  child: Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(-8, 1),
                        child: Icon(Icons.search, color: AppTheme.containerColor1, size: 26)
                      ),
                      Text('Leer Corizacion', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700) ),
                      Text('   F11', style: TextStyle(color: AppTheme.containerColor1.withAlpha(180), fontWeight: FontWeight.w700) ),
                    ],
                  ),
                ),
              )
            ],
          ),

          Flexible( //Contenido (Body)
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.containerColor1,
                borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row( 
                      children: [

                        Expanded(
                          child: Column( //Formulario de clientes
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('   Cliente *', style: AppTheme.subtituloPrimario),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField( //TODO: Controller Cliente
                                      autofocus: true,  
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
                                          borderSide: BorderSide(color: AppTheme.letraClara)
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
                                          borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
                                        ),
                                        isDense: true,
                                        prefixIcon: Icon(Icons.perm_contact_cal_sharp, size: 25, color: AppTheme.letra70),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: AppTheme.letraClara,
                                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30))
                                    ),
                                    child: Center(
                                      child: FeedBackButton(
                                        onPressed: () {
                                        },
                                        child: Icon(Icons.add, color: AppTheme.containerColor1, size: 28)
                                      )
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        SizedBox(width: 15),

                        Column( //Fecha de Entrega
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(' Fecha de Entrega:', style: AppTheme.subtituloPrimario),
                            SizedBox(height: 2),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(43, 255, 255, 255),
                                border: Border.all(color: AppTheme.letraClara),
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: true, 
                                      focusColor: AppTheme.focusColor,
                                      onChanged: (value){
                                        
                                      } 
                                    ),
                                    Text('Se entrega en este momento  ')
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),

                        //SizedBox(width: 15),

                        Column( 
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(''),
                            SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(43, 255, 255, 255),
                                    border: Border.all(color: AppTheme.letraClara),
                                    //borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          focusColor: AppTheme.focusColor,
                                          value: false, 
                                          onChanged: (value){
                                            
                                          } 
                                        ),
                                        Text('Entregar en otro día  ')
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.letraClara,
                                    borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30))
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('07:55 P.M', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700) ),
                                      ),
                                      Center(
                                        child: FeedBackButton(
                                          onPressed: () {
                                          },
                                          child: Icon(Icons.calendar_month, color: AppTheme.containerColor1, size: 28)
                                        )
                                      ),
                                      SizedBox(width: 6)
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),

                    SizedBox(height: 10),

                    Row(
                      children: [

                        Expanded(
                          child: Column( //Formulario de Producto
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('   Producto *', style: AppTheme.subtituloPrimario),
                              SizedBox(height: 2),
                              TextFormField( //TODO: Controller Producto
                                decoration: InputDecoration(
                                  hintText: 'F2',
                                  hintStyle: TextStyle(color: AppTheme.letra70),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.copy, size: 25, color: AppTheme.letra70),
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(width: 15),

                        Column( //Precio por unidad
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(' Precio/Unidad', style: AppTheme.subtituloPrimario),
                            SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              width: 100,
                              child: TextFormField(
                                canRequestFocus: false,
                                readOnly: true,
                                initialValue: '0.00',
                              ),
                            )
                          ],
                        ),

                        SizedBox(width: 15),

                        Column( //Precio por unidad
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('   Cantidad', style: AppTheme.subtituloPrimario),
                            SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              width: 100,
                              child: TextFormField(
                                initialValue: '1',
                              ),
                            )
                          ],
                        ),

                        SizedBox(width: 15),

                        Column( //Precio por unidad
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('   Ancho', style: AppTheme.subtituloPrimario),
                            SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              width: 100,
                              child: TextFormField( //TODO: Controller Ancho
                              ),
                            )
                          ],
                        ),

                        SizedBox(width: 15),

                        Column( //Precio por unidad
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('   Alto', style: AppTheme.subtituloPrimario),
                            SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              width: 100,
                              child: TextFormField( //TODO: Controller Alto
                              ),
                            )
                          ],
                        ),

                      ],
                    ),

                    SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        Expanded(
                          flex: 2,
                          child: Column( //Formulario de Producto
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('   Comentario', style: AppTheme.subtituloPrimario),
                              SizedBox(height: 2),
                              TextFormField( //TODO: Comentario
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(Icons.comment, size: 25, color: AppTheme.letra70),
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(width: 15),

                        Expanded(
                          child: Column( //Formulario de Producto
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('   % Descuento', style: AppTheme.subtituloPrimario),
                              SizedBox(height: 2),
                              TextFormField( //TODO: descuento
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(Icons.discount_outlined, size: 25, color: AppTheme.letra70),
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(width: 15),

                        Expanded(
                          child: Column( //Formulario de Producto
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('   IVA (16%)', style: AppTheme.subtituloPrimario),
                              SizedBox(height: 2),
                              SizedBox(
                                height: 40,
                                child: TextFormField( //TODO: iva
                                  canRequestFocus: false,
                                  readOnly: true,
                                  initialValue: '\$0.00',
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(width: 15),

                        Expanded(
                          child: Column( //Formulario de Producto
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('   Total', style: AppTheme.subtituloPrimario),
                              SizedBox(height: 2),
                              SizedBox(
                                height: 40,
                                child: TextFormField( //TODO: subtotal
                                canRequestFocus: false,
                                readOnly: true,
                                initialValue: '\$0.00',
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(width: 15),

                        ElevatedButton(
                          onPressed: (){}, 
                          style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.focused)) {
                                  return AppTheme.letra70; // Color cuando está enfocado
                                }
                                return AppTheme.letraClara; // Color normal
                              }),
                              foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
                            ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Agregar Producto', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700) ),
                          ),
                        )

                      ],
                    ),

                    SizedBox(height: 30),

                    Expanded(
                      child: Column(
                        children: [
                          // Cabecera
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              color: AppTheme.tablaColorHeader, //TODO: agregar a temas
                            ),
                            child: Row(
                              children: const [
                                Expanded(child: Text('Cant', textAlign: TextAlign.center)),
                                Expanded(child: Text('Producto', textAlign: TextAlign.center)),
                                Expanded(child: Text('Precio/Unidad', textAlign: TextAlign.center)),
                                Expanded(child: Text('Descuento', textAlign: TextAlign.center)),
                                Expanded(child: Text('Subtotal', textAlign: TextAlign.center)),
                                Expanded(child: Text('Impuestos', textAlign: TextAlign.center)),
                                Expanded(child: Text('Total', textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          // Lista de datos
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              child: ListView.builder(
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: const EdgeInsets.all(8.0),
                                    color: index % 2 == 0
                                        ? AppTheme.tablaColor1
                                        : AppTheme.tablaColor2,
                                    child: Row(
                                      children: [
                                        Expanded(child: Text('1', textAlign: TextAlign.center)),
                                        Expanded(child: Text('Producto $index', textAlign: TextAlign.center)),
                                        Expanded(child: Text('\$10.00', textAlign: TextAlign.center)),
                                        Expanded(child: Text('5%', textAlign: TextAlign.center)),
                                        Expanded(child: Text('\$9.50', textAlign: TextAlign.center)),
                                        Expanded(child: Text('\$0.50', textAlign: TextAlign.center)),
                                        Expanded(child: Text('\$10.00', textAlign: TextAlign.center)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    
                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Comentarios de la venta',
                              hintStyle: TextStyle(color: AppTheme.letra70),
                              isDense: true,
                              //prefixIcon: Icon(Icons.comment, size: 25, color: AppTheme.letra70),
                              contentPadding: const EdgeInsets.only(left: 10, top: 20),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: const BorderRadius.all(Radius.circular(12))
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
                                borderRadius: const BorderRadius.all(Radius.circular(12))
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: (){},
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                          if (states.contains(WidgetState.focused)) {
                                            return AppTheme.botonPrincipalFocus;// Color cuando está enfocado
                                          }
                                          return AppTheme.botonPrincipal; // Color normal
                                        }),
                                        foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
                                      ), 
                                      child: Text('          Realizar Pago          ', 
                                        style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700)
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: (){},
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                          if (states.contains(WidgetState.focused)) {
                                            return AppTheme.botonSecundarioFocus; // Color cuando está enfocado
                                          }
                                          return AppTheme.botonSecundario; // Color normal
                                        }),
                                        foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
                                      ), 
                                      child: Text('Guardar como cotizacion', 
                                        style: TextStyle(color: AppTheme.isDarkTheme==true?AppTheme.containerColor1:Colors.black54, fontWeight: FontWeight.w700)
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('Subtotal:  ', style: AppTheme.subtituloPrimario),
                                      SizedBox(
                                        height: 32,
                                        width: 150,
                                        child: TextFormField(
                                          canRequestFocus: false,
                                          readOnly: true,
                                          decoration: AppTheme.inputDecorationCustom,
                                          initialValue: '\$0.00',
                                        )
                                      )
                                    ],
                                  ), SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('- Descuento:  ', style: AppTheme.subtituloPrimario),
                                      SizedBox(
                                        height: 32,
                                        width: 150,
                                        child: TextFormField(
                                          canRequestFocus: false,
                                          readOnly: true,
                                          decoration: AppTheme.inputDecorationCustom,
                                          initialValue: '\$0.00',
                                        )
                                      )
                                    ],
                                  ), SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('+ IVA:  ', style: AppTheme.subtituloPrimario),
                                      SizedBox(
                                        height: 32,
                                        width: 150,
                                        child: TextFormField(
                                          canRequestFocus: false,
                                          readOnly: true,
                                          decoration: AppTheme.inputDecorationCustom,
                                          initialValue: '\$0.00',
                                        )
                                      )
                                    ],
                                  ), SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('Total:  ', style: AppTheme.tituloPrimario),
                                      SizedBox(
                                        height: 36,
                                        width: 150,
                                        child: TextFormField(
                                          canRequestFocus: false,
                                          readOnly: true,
                                          decoration: AppTheme.inputDecorationCustom.copyWith(
                                          ),
                                          initialValue: '\$0.00',
                                          style: TextStyle(fontSize: 22),
                                        )
                                      )
                                    ],
                                  ), SizedBox(height: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class Pestania extends StatelessWidget {
  const Pestania({
    super.key, required this.last, required this.selected, this.agregarPestania, this.selectedPestania, required this.index,
  });

  final bool last; 
  final bool selected;
  final Function? agregarPestania;
  final Function? selectedPestania;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 2),
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: DiagonalCornerContainer(
          color: selected == true ? AppTheme.containerColor1 : AppTheme.containerColor2,
          child: last != true ? Padding(
            padding: const EdgeInsets.only(top:8, bottom: 8, left: 8, right: 20),
            child: FeedBackButton(
              onPressed: () {
                selectedPestania!(index);
              },
              child: Text('Venta Nueva', style: AppTheme.tituloPrimario)
            ),
          ) 
          : Padding(
            padding: const EdgeInsets.only(top:8, bottom: 8, left: 10, right: 16),
            child: FeedBackButton(
              onPressed: () {
                //Agregar una pestaña en VentaScreen
                agregarPestania!();
              },
              child: Icon(Icons.add, color: AppTheme.letraClara, size: 21)
            ),
          ),
        ),
      ),
    );
  }
}
