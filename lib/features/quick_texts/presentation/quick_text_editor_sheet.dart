import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/quick_text.dart';

/// Opens the add/edit sheet. Returns the saved snippet, or null if dismissed.
Future<QuickText?> showQuickTextEditor(BuildContext context, {QuickText? editing}) {
  return showModalBottomSheet<QuickText>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _QuickTextEditor(editing: editing),
  );
}

class _QuickTextEditor extends StatefulWidget {
  const _QuickTextEditor({this.editing});

  final QuickText? editing;

  @override
  State<_QuickTextEditor> createState() => _QuickTextEditorState();
}

class _QuickTextEditorState extends State<_QuickTextEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.editing?.title);
  late final _text = TextEditingController(text: widget.editing?.text);

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      QuickText(
        id: widget.editing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        text: _text.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.editing == null ? 'New quick text' : 'Edit quick text', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'e.g. Home address',
                  prefixIcon: Icon(Symbols.label_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _text,
                autofocus: widget.editing == null,
                minLines: 4,
                maxLines: 12,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Text', alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the text to copy' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
