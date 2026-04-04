import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Insights")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_rounded, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: AppTheme.spacingMD),
              Text("Em breve", style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                "Resumos baseados em estudos científicos sobre uso de dispositivos estarão aqui.",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
