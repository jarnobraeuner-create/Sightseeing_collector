import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum AppLottieType {
  loading,
  success,
  empty,
  error,
  onboarding,
  monumentDrop,
  monumentCollect,
}

class AppLottie extends StatelessWidget {
  final AppLottieType type;
  final double size;
  final bool repeat;
  final bool animate;

  const AppLottie({
    super.key,
    required this.type,
    this.size = 120,
    this.repeat = true,
    this.animate = true,
  });

  String get _assetPath {
    switch (type) {
      case AppLottieType.loading:
        return 'assets/lottie/loading_pulse.json';
      case AppLottieType.success:
        return 'assets/lottie/success_pop.json';
      case AppLottieType.empty:
        return 'assets/lottie/empty_idle.json';
      case AppLottieType.error:
        return 'assets/lottie/error_alert.json';
      case AppLottieType.onboarding:
        return 'assets/lottie/onboarding_intro.json';
      case AppLottieType.monumentDrop:
        return 'assets/lottie/monument_drop.json';
      case AppLottieType.monumentCollect:
        return 'assets/lottie/monument_collect.json';
    }
  }

  IconData get _fallbackIcon {
    switch (type) {
      case AppLottieType.loading:
        return Icons.hourglass_top;
      case AppLottieType.success:
        return Icons.check_circle;
      case AppLottieType.empty:
        return Icons.inbox_outlined;
      case AppLottieType.error:
        return Icons.error_outline;
      case AppLottieType.onboarding:
        return Icons.explore;
      case AppLottieType.monumentDrop:
        return Icons.auto_awesome;
      case AppLottieType.monumentCollect:
        return Icons.library_add_check;
    }
  }

  Color get _fallbackColor {
    switch (type) {
      case AppLottieType.loading:
        return Colors.amber;
      case AppLottieType.success:
        return Colors.greenAccent;
      case AppLottieType.empty:
        return Colors.lightBlueAccent;
      case AppLottieType.error:
        return Colors.redAccent;
      case AppLottieType.onboarding:
        return Colors.amberAccent;
      case AppLottieType.monumentDrop:
        return Colors.purpleAccent;
      case AppLottieType.monumentCollect:
        return Colors.tealAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _assetPath,
        repeat: repeat,
        animate: animate,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          _fallbackIcon,
          color: _fallbackColor,
          size: size * 0.65,
        ),
      ),
    );
  }
}
