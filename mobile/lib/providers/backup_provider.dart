// mobile/lib/providers/backup_provider.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/database_provider.dart';
import 'package:mobile/repositories/backup_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(appDatabaseProvider)),
);

Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(backupRepositoryProvider);
  final json = await repo.buildExportJson();
  final directory = await getTemporaryDirectory();
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-');
  final file = File('${directory.path}/backup_$timestamp.json');
  await file.writeAsString(jsonEncode(json));

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: 'Backup AnalisadorFinanceiro'),
  );
}

Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.single.path == null) return;

  final file = File(result.files.single.path!);
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo inválido ou corrompido.')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Restaurar backup?'),
      content: const Text(
        'Isso vai substituir todos os dados atuais (transações, receitas, categorias e planos). Essa ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Restaurar',
            style: TextStyle(color: AppColors.accentDanger),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final repo = ref.read(backupRepositoryProvider);
  try {
    await repo.restoreFromJson(json);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restaurado com sucesso.')),
      );
    }
  } on BackupVersionMismatch {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este backup foi feito com uma versão mais nova do app.'),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo de backup inválido.')),
      );
    }
  }
}
