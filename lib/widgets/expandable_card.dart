import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class ExpandableCard extends StatefulWidget {
  final String title;
  final Widget expandedContent;
  final Duration duration;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onChanged;

  const ExpandableCard({
    super.key,
    required this.title,
    required this.expandedContent,
    this.duration = const Duration(milliseconds: 300),
    this.initiallyExpanded = false,
    this.onChanged,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.tablaColorHeader,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(widget.title, style: AppTheme.subtituloPrimario),
                  ),
                  Icon(_isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                      color: AppTheme.letraClara,
                  ),
                ],
              ),
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _animation,
                axisAlignment: -1,
                child: widget.expandedContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
