import 'package:eschool/utils/app_config.dart';
import 'package:eschool/utils/env_switcher_util.dart';
import 'package:flutter/material.dart';

class GlobalEnvFab extends StatefulWidget {
  const GlobalEnvFab({Key? key}) : super(key: key);

  @override
  State<GlobalEnvFab> createState() => _GlobalEnvFabState();
}

class _GlobalEnvFabState extends State<GlobalEnvFab> {
  // Posisi draggable FAB — default pojok kanan atas
  double _fabDx = 16;
  double _fabDy = 60;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Environment>(
      valueListenable: AppConfig.envNotifier,
      builder: (context, currentEnv, child) {
        if (currentEnv == Environment.prod) return const SizedBox.shrink();

        final label = currentEnv == Environment.dev ? 'DEV' : 'TEST';
        final color = currentEnv == Environment.dev
            ? Colors.orange.shade700
            : Colors.blue.shade700;

        return Positioned(
          key: ValueKey('GlobalEnvFab_${currentEnv.name}'),
          left: _fabDx,
          top: _fabDy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _fabDx += details.delta.dx;
                _fabDy += details.delta.dy;
              });
            },
            onTap: () {
              EnvSwitcherUtil.showEnvDialog(context);
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
