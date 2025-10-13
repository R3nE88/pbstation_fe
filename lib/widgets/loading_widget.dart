import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({
    super.key,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _startDelayedVisibility();
  }

  void _startDelayedVisibility() async {
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (mounted) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink(); // Widget invisible
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Espere un momento\n', style: AppTheme.subtituloConstraste),
          CircularProgressIndicator(color: AppTheme.primario1),
          Text('\ncargando datos...', style: AppTheme.subtituloConstraste),
        ],
      ),
    );
  }
}