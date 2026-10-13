import 'package:flutter/material.dart' hide Text, Icon;
import 'package:flutter/services.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/ui/widgets/choice_sheet.dart';

const int _custom = -1;

const Map<int, String> _options = <int, String>{
  0: 'Off',
  15: '15 minutes',
  30: '30 minutes',
  45: '45 minutes',
  60: '1 hour',
  90: '90 minutes',
  _custom: 'Custom…',
};

Future<int?> pickSleepMinutes(BuildContext context) async {
  final picked = await showChoices<int>(
    context,
    title: 'Sleep timer',
    options: _options,
  );
  if (picked != _custom) return picked;
  if (!context.mounted) return null;
  return _askMinutes(context);
}

Future<int?> _askMinutes(BuildContext context) async {
  final controller = TextEditingController();
  int? parse(String text) {
    final value = int.tryParse(text.trim());
    if (value == null || value <= 0) return null;
    return value > 1440 ? 1440 : value;
  }

  final value = await showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Custom sleep timer'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(
          hintText: 'Minutes'.tr,
          suffixText: 'min'.tr,
        ),
        onSubmitted: (text) => Navigator.of(dialogContext).pop(parse(text)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(parse(controller.text)),
          child: const Text('Start'),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}
