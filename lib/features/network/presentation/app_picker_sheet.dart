import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../bloc/network_bloc.dart';

/// Multi-select list of installed apps; saves the kill switch exceptions on "Done".
Future<void> showAppPicker(BuildContext context) {
  final bloc = context.read<NetworkBloc>()..add(const InstalledAppsRequested());
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(value: bloc, child: const _AppPicker()),
  );
}

class _AppPicker extends StatefulWidget {
  const _AppPicker();

  @override
  State<_AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<_AppPicker> {
  late final Set<String> _selected = {...context.read<NetworkBloc>().state.allowedApps};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apps = context.select((NetworkBloc bloc) => bloc.state.installedApps);
    final visible = apps
        ?.where((a) => _query.isEmpty || a.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
            child: Row(
              children: [
                Expanded(child: Text('Apps that stay online', style: theme.textTheme.titleLarge)),
                FilledButton(
                  onPressed: () {
                    context.read<NetworkBloc>().add(AllowedAppsChanged(_selected.toList()));
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search apps', prefixIcon: Icon(Symbols.search_rounded)),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: visible == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final app = visible[i];
                      final checked = _selected.contains(app.package);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (_) => setState(
                          () => checked ? _selected.remove(app.package) : _selected.add(app.package),
                        ),
                        secondary: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(app.icon, width: 40, height: 40, gaplessPlayback: true),
                        ),
                        title: Text(app.label),
                        subtitle: Text(app.package, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
