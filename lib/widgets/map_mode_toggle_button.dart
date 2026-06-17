import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/map_mode_service.dart';

/// Moderner Toggle-Button für Tag-/Nachtmodus auf der Karte
/// Position: Oben rechts über der Karte
class MapModeToggleButton extends StatefulWidget {
  final VoidCallback? onModeChanged;

  const MapModeToggleButton({
    Key? key,
    this.onModeChanged,
  }) : super(key: key);

  @override
  State<MapModeToggleButton> createState() => _MapModeToggleButtonState();
}

class _MapModeToggleButtonState extends State<MapModeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotateAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _scaleAnim = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapModeService>(
      builder: (context, mapModeService, _) {
        if (!mapModeService.isLoaded) {
          return const SizedBox.shrink();
        }

        final isDayMode = mapModeService.isDayMode;

        return GestureDetector(
          onTap: () async {
            _animController.forward().then((_) {
              _animController.reverse();
            });
            await mapModeService.toggleMode();
            widget.onModeChanged?.call();
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotateAnim, _scaleAnim]),
            builder: (_, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: Transform.rotate(
                angle: _rotateAnim.value * 3.14159 * 2, // Full rotation
                child: child,
              ),
            ),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDayMode
                      ? [Colors.amber[400]!, Colors.orange[500]!]
                      : [Colors.indigo[800]!, Colors.purple[900]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDayMode ? Colors.orange : Colors.purple)
                        .withOpacity(0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: null, // Handled by parent GestureDetector
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDayMode ? Icons.wb_sunny : Icons.nights_stay,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDayMode ? 'Tag' : 'Nacht',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
