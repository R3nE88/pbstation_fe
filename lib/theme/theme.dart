import 'package:flutter/material.dart';
import '../provider/change_theme_provider.dart';

class AppTheme{
  static ChangeTheme? changeThemeInstance;

  static void initialize(ChangeTheme instance) {
    changeThemeInstance = instance;
  }

  static const Color letraClara = Colors.white;
  static const Color letraOscura = Colors.black;
  static const Color letra70 = Colors.white70;
  static final Color focusColor = letraClara.withAlpha(88);
  static const Color filledColor = Color.fromARGB(33, 255, 255, 255);

  static Color get primario1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 60, 60, 60)
      : const Color.fromARGB(255, 78, 175, 255);
  static Color get secundario1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 16, 16, 16)
      : const Color.fromARGB(255, 54, 134, 233);
  static Color get primario2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 43, 43, 43)
      : const Color.fromARGB(255, 93, 182, 255);
  static Color get secundario2 => changeThemeInstance?.isDarkTheme == true
      ? Colors.black
      : const Color.fromARGB(255, 5, 77, 186);

  static Color get backgroundColor => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 30, 30, 30)
      : const Color.fromARGB(255, 231, 229, 229);
  static Color get backgroundWidgetColor1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 50, 50, 50)
      : const Color.fromARGB(255, 227, 247, 255);
  static Color get backgroundWidgetColor2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 40, 40, 40)
      : const Color.fromARGB(255, 160, 201, 255);
  static Color get backgroundWidgetColor3 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(123, 20, 20, 20)
      : const Color.fromARGB(123, 32, 103, 255);
  static Color get backgroundWidgetColor4 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(167, 60, 60, 60)
      : const Color.fromARGB(167, 73, 158, 255);

  static Color get containerColor1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 40, 40, 40)
      : const Color.fromARGB(255, 84, 167, 244);
    
  static Color get containerColor2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 52, 52, 52)
      : const Color.fromARGB(255, 87, 160, 227);

  static Color get backgroundWidgetFormColor1 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(0, 195, 195, 195)
      : Color.fromARGB(30, 99, 180, 255);
  static Color get backgroundWidgetFormColor2 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(53, 0, 0, 0)
      : Color.fromARGB(123, 32, 103, 255);
  static Color get backgroundWidgetFormColor3 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(11, 42, 42, 42)
      : Color.fromARGB(50, 63, 162, 255);
  static Color get backgroundWidgetFormColor4 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(28, 146, 146, 146)
      : Color.fromARGB(167, 73, 158, 255);
    
  static Color get botonPrincipal => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 89, 89, 89)
      : AppTheme.primario1;

  static Color get botonPrincipalFocus => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 61, 61, 61)
      : AppTheme.secundario1;
    
  static Color get botonSecundario => changeThemeInstance?.isDarkTheme == true
      ? AppTheme.letraClara
      : AppTheme.letraClara;

  static Color get botonSecundarioFocus => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 165, 165, 165)
      : const Color.fromARGB(255, 205, 205, 210);

  static Color get tablaColorHeader => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 78, 78, 78)
      : const Color.fromARGB(255, 30, 128, 221);

  static Color get tablaColor1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 115, 115, 115)
      : const Color.fromARGB(255, 62, 160, 251);
    
  static Color get tablaColor2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 103, 103, 103)
      : const Color.fromARGB(255, 49, 145, 235);

    static Color get tablaColorFondo => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 57, 57, 57)
      : const Color.fromARGB(255, 120, 190, 255);

  static bool get isDarkTheme => changeThemeInstance?.isDarkTheme == true
      ? true
      : false;

  static Color get colorContraste => changeThemeInstance?.isDarkTheme == true
      ? letraClara
      : letraOscura;

  static final Color colorError = Color.fromARGB(255, 228, 15, 0);
  
  static TextStyle get subtituloConstraste => TextStyle(
    color: changeThemeInstance?.isDarkTheme == true ? letraClara : letraOscura
  );

  static const TextStyle subtituloPrimario = TextStyle(
    color: letraClara
  );
  static const TextStyle subtituloSecundario = TextStyle(
    color: letraOscura
  );
   static const TextStyle tituloPrimario = TextStyle(
    color: letraClara,
    fontWeight: FontWeight.w600
  );
   static const TextStyle tituloClaro = TextStyle(
    color: letraClara,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2
  );

  static final TextStyle errorStyle = TextStyle(
    color: colorError.withAlpha(180),
    fontSize: 13,
  );

  static const TextStyle labelStyle = TextStyle(
    color: Colors.white54
  );

  static final botonSecStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.focused)) {
        return AppTheme.botonPrincipalFocus;// Color cuando está enfocado
      }
      return AppTheme.botonPrincipal; // Color normal
    }),
    foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
  );

  static final ButtonStyle botonGuardar = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.focused)) {
        return AppTheme.letra70; // Color cuando está enfocado
      }
      return AppTheme.letraClara; // Color normal
    }),
    foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
  );
  
  static const TextStyle textFormField = TextStyle(fontWeight: FontWeight.w400, color: Colors.white);

  static const InputDecoration inputDecorationCustom = InputDecoration(
    contentPadding: EdgeInsets.only(left: 10),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
  );


  static final InputDecoration inputError = InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),
    );

    static final InputDecoration inputNormal = InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),
    );

  static final ThemeData customTheme = ThemeData.light().copyWith(
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: AppTheme.letraClara),
      checkColor: WidgetStateProperty.all(AppTheme.containerColor1),
      fillColor: WidgetStateProperty.all(AppTheme.letraClara),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTheme.primario2, // Cambia aquí tu color base
    ),

    dialogTheme: DialogTheme(
      surfaceTintColor: Colors.transparent
    ),
     
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.secundario1, // button text color
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppTheme.botonSecundarioFocus; // Color cuando está enfocado
          }
          return AppTheme.botonSecundario; // Color normal
        }),
        foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
        shape: WidgetStateProperty.all(StadiumBorder()),
        elevation: WidgetStateProperty.all(1),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5
          )
        ),
      ),
    ),

    textTheme: TextTheme(
      bodyMedium: TextStyle(color: AppTheme.letraClara), // texto principal del campo
    ),

    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.only(left: 10),
      floatingLabelStyle: TextStyle(color: Colors.white, fontSize: 15),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),

      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),

      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      labelStyle: const TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),

      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      filled: true,

      fillColor: filledColor,

      alignLabelWithHint: true,
    )
  );

  static final ThemeData customThemeDark = ThemeData.dark().copyWith(
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: AppTheme.letraClara),
      checkColor: WidgetStateProperty.all(AppTheme.containerColor1),
      fillColor: WidgetStateProperty.all(AppTheme.letraClara),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.white // Cambia aquí tu color base
    ),

    dialogTheme: DialogTheme(
      surfaceTintColor: Colors.transparent
    ),
     
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.secundario1, // button text color
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppTheme.botonSecundarioFocus; // Color cuando está enfocado
          }
          return AppTheme.botonSecundario; // Color normal
        }),
        foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
        shape: WidgetStateProperty.all(StadiumBorder()),
        elevation: WidgetStateProperty.all(1),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5
          )
        ),
      ),
    ),

    textSelectionTheme: TextSelectionThemeData(
      selectionColor: const Color.fromARGB(65, 255, 255, 255),// Fondo de selección
      cursorColor: Colors.white, // Cursor (también se puede poner individualmente en cada TextField)
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.filledColor,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppTheme.primario1), // Fondo del menú
        elevation: WidgetStatePropertyAll(4), // Sombra
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        )), // Bordes redondeados
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.only(left: 10),
      floatingLabelStyle: TextStyle(color: Colors.white, fontSize: 15),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),

      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),

      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 224, 224, 224),
        fontSize: 15,
      ),

      labelStyle: const TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),

      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      filled: true,

      fillColor: filledColor,

      alignLabelWithHint: true,
    )
  );
}