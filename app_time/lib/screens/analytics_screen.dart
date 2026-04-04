import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Análise")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: AppTheme.spacingMD),
              Text("Em breve", style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                "Gráficos e análises do seu padrão de uso estarão disponíveis aqui.",
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
