import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/home_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ElevatedButton(
          onPressed: () {

            
            homeScreenKey.currentState?.setState(() {});
          },
          child: Text('Forzar Build'),
        ),
      ),
    );
  }
}