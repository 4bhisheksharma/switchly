import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/dns_models.dart';

/// Opens the add/edit sheet. Returns the saved provider, or null if dismissed.
///
/// [existing] is used to reject duplicate hostnames.
Future<DnsProvider?> showProviderEditor(
  BuildContext context, {
  required List<DnsProvider> existing,
  DnsProvider? editing,
}) {
  return showModalBottomSheet<DnsProvider>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ProviderEditor(existing: existing, editing: editing),
  );
}

class _ProviderEditor extends StatefulWidget {
  const _ProviderEditor({required this.existing, this.editing});

  final List<DnsProvider> existing;
  final DnsProvider? editing;

  @override
  State<_ProviderEditor> createState() => _ProviderEditorState();
}

class _ProviderEditorState extends State<_ProviderEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _host = TextEditingController(text: widget.editing?.host);

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    super.dispose();
  }

  String? _validateHost(String? value) {
    final host = normalizeHostname(value ?? '');
    if (host.isEmpty) return 'Enter a hostname';
    if (!isValidHostname(host)) return 'Enter a hostname like dns.example.com';
    final duplicate = widget.existing.any((p) => p.id != widget.editing?.id && p.host.toLowerCase() == host);
    if (duplicate) return 'This provider is already in your list';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final host = normalizeHostname(_host.text);
    final name = _name.text.trim();
    final editing = widget.editing;
    Navigator.of(context).pop(
      editing != null
          ? editing.copyWith(name: name, host: host)
          : DnsProvider(id: 'custom_${DateTime.now().microsecondsSinceEpoch}', name: name, host: host),
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
              Text(widget.editing == null ? 'Add provider' : 'Edit provider', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                "Any DNS-over-TLS hostname works. You'll find it on your provider's setup page.",
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                autofocus: widget.editing == null,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Symbols.label_rounded)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _host,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Hostname',
                  hintText: 'dns.example.com',
                  prefixIcon: Icon(Symbols.dns_rounded),
                ),
                validator: _validateHost,
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
