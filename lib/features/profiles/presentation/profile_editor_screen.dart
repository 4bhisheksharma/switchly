import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/select_chip.dart';
import '../../display/data/display_models.dart';
import '../../dns/bloc/dns_bloc.dart';
import '../../dns/data/dns_models.dart';
import '../../network/bloc/network_bloc.dart';
import '../bloc/profiles_bloc.dart';
import '../data/profile_models.dart';

/// Create or edit a profile. Each setting can be left as "Don't change".
class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, this.editing});

  final Profile? editing;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final _name = TextEditingController(text: widget.editing?.name);
  late String _icon = widget.editing?.icon ?? 'focus';
  late PrivateDnsState? _dns = widget.editing?.dns;
  late bool? _grayscale = widget.editing?.grayscale;
  late double? _animationSpeed = widget.editing?.animationSpeed;
  late bool? _wirelessDebugging = widget.editing?.wirelessDebugging;
  late bool? _killSwitch = widget.editing?.killSwitch;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    context.read<ProfilesBloc>().add(
          ProfileSaved(
            Profile(
              id: widget.editing?.id ?? 'p${DateTime.now().microsecondsSinceEpoch}',
              name: _name.text.trim(),
              icon: _icon,
              dns: _dns,
              grayscale: _grayscale,
              animationSpeed: _animationSpeed,
              wirelessDebugging: _wirelessDebugging,
              killSwitch: _killSwitch,
            ),
          ),
        );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “${widget.editing!.name}”?'),
        content: const Text('Settings it changed stay as they are.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<ProfilesBloc>().add(ProfileDeleted(widget.editing!.id));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = context.select((DnsBloc bloc) => bloc.state.config.providers);
    final wirelessSupported = context.select((NetworkBloc bloc) => bloc.state.status?.wirelessSupported ?? true);

    final dnsOptions = <(String, PrivateDnsState?)>[
      ("Don't change", null),
      ('Off', const PrivateDnsState(PrivateDnsMode.off)),
      ('Automatic', const PrivateDnsState(PrivateDnsMode.automatic)),
      for (final p in providers) (p.name, PrivateDnsState(PrivateDnsMode.hostname, p.host)),
      // Keep a host that was removed from the provider list selectable.
      if (_dns case PrivateDnsState(mode: PrivateDnsMode.hostname, :final host?)
          when !providers.any((p) => p.host == host))
        (host, _dns),
    ];

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _save,
            child: const Text('Save profile'),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(widget.editing == null ? 'New profile' : 'Edit profile'),
            actions: [
              if (widget.editing != null)
                IconButton(tooltip: 'Delete', icon: const Icon(Symbols.delete_rounded), onPressed: _delete),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                TextField(
                  controller: _name,
                  autofocus: widget.editing == null,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Focus, Night, Travel'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final MapEntry(key: key, value: icon) in profileIcons.entries)
                      _IconChoice(icon: icon, selected: key == _icon, onTap: () => setState(() => _icon = key)),
                  ],
                ),
                const SectionHeader('Private DNS'),
                _Options(options: dnsOptions, value: _dns, onChanged: (v) => setState(() => _dns = v)),
                const SectionHeader('Grayscale'),
                _Options(
                  options: const [("Don't change", null), ('On', true), ('Off', false)],
                  value: _grayscale,
                  onChanged: (v) => setState(() => _grayscale = v),
                ),
                const SectionHeader('Animation speed'),
                _Options(
                  options: [("Don't change", null), for (final s in animationSpeeds) (speedLabel(s), s)],
                  value: _animationSpeed,
                  onChanged: (v) => setState(() => _animationSpeed = v),
                ),
                if (wirelessSupported) ...[
                  const SectionHeader('Wireless debugging'),
                  _Options(
                    options: const [("Don't change", null), ('On', true), ('Off', false)],
                    value: _wirelessDebugging,
                    onChanged: (v) => setState(() => _wirelessDebugging = v),
                  ),
                ],
                const SectionHeader('Internet kill switch'),
                _Options(
                  options: const [("Don't change", null), ('Block internet', true), ('Allow internet', false)],
                  value: _killSwitch,
                  onChanged: (v) => setState(() => _killSwitch = v),
                ),
                const SizedBox(height: 24),
                Text(
                  'Restoring puts back each setting this profile changed, exactly as it was before.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Options<T> extends StatelessWidget {
  const _Options({required this.options, required this.value, required this.onChanged});

  final List<(String, T?)> options;
  final T? value;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, option) in options)
          SelectChip(label: label, selected: option == value, onTap: () => onChanged(option)),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? colors.primary : colors.outlineVariant),
        ),
        child: Icon(icon, fill: selected ? 1 : 0, color: selected ? colors.onPrimary : colors.onSurfaceVariant),
      ),
    );
  }
}
