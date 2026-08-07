// mobile/lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/backup_provider.dart';
import 'package:mobile/screens/settings/category_toggles_screen.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/money_format.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = SettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SettingsSection(title: 'Preferências'),
          _OptionGroup<AppCurrency>(
            label: 'Moeda',
            value: settings.currency,
            options: AppCurrency.values,
            optionLabel: currencyLabel,
            onChanged: settings.setCurrency,
          ),
          const SizedBox(height: 10),
          _OptionGroup<AppDateFormat>(
            label: 'Formato de data',
            value: settings.dateFormat,
            options: AppDateFormat.values,
            optionLabel: (f) => switch (f) {
              AppDateFormat.dmy => 'DD/MM/AAAA',
              AppDateFormat.mdy => 'MM/DD/AAAA',
              AppDateFormat.ymd => 'AAAA/MM/DD',
            },
            onChanged: settings.setDateFormat,
          ),
          const SizedBox(height: 10),
          _OptionGroup<DecimalSeparator>(
            label: 'Separador decimal',
            value: settings.decimalSeparator,
            options: DecimalSeparator.values,
            optionLabel: (s) => switch (s) {
              DecimalSeparator.comma => 'Vírgula (1.234,56)',
              DecimalSeparator.dot => 'Ponto (1,234.56)',
            },
            onChanged: settings.setDecimalSeparator,
          ),
          const SizedBox(height: 20),
          const _SettingsSection(title: 'Categorias'),
          _ActionTile(
            label: 'Gerenciar categorias ativas',
            icon: Icons.category_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryTogglesScreen()),
            ),
          ),
          const SizedBox(height: 20),
          const _SettingsSection(title: 'Dados'),
          _ActionTile(
            label: 'Exportar backup',
            icon: Icons.upload_outlined,
            onTap: () => exportBackup(context, ref),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            label: 'Restaurar backup',
            icon: Icons.download_outlined,
            onTap: () => restoreBackup(context, ref),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _OptionGroup<T> extends StatelessWidget {
  const _OptionGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          for (final option in options)
            RadioListTile<T>(
              value: option,
              groupValue: value,
              dense: true,
              activeColor: AppColors.accentPrimary,
              title: Text(optionLabel(option)),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentPrimary),
        title: Text(label),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
