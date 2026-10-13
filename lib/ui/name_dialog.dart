import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';

Future<String?> askName(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Save',
}) async {
  final controller = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: 'Name'.tr),
        onSubmitted: (text) => Navigator.of(dialogContext).pop(text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(action),
        ),
      ],
    ),
  );
  controller.dispose();
  if (value == null || value.isEmpty) return null;
  return value;
}
