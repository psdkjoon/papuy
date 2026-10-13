import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';

Future<String?> askStreamUrl(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _StreamDialog(),
  );
}

class _StreamDialog extends StatefulWidget {
  const _StreamDialog();

  @override
  State<_StreamDialog> createState() => _StreamDialogState();
}

class _StreamDialogState extends State<_StreamDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Network stream'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(hintText: 'http://, https://, rtsp://'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Play'),
        ),
      ],
    );
  }
}
