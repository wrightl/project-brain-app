import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projectbrain/models/location.dart';
import 'package:projectbrain/services/location_service.dart';

class CitySearchField extends StatefulWidget {
  final LocationService locationService;
  final String? countryCode;
  final CityOption? value;
  final ValueChanged<CityOption?> onChanged;
  final bool enabled;

  const CitySearchField({
    super.key,
    required this.locationService,
    required this.countryCode,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<CitySearchField> {
  Timer? _debounce;
  List<CityOption> _options = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final countryCode = widget.countryCode;
    if (countryCode == null || countryCode.isEmpty || query.trim().length < 2) {
      setState(() {
        _options = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await widget.locationService.searchCities(
        query: query,
        countryCode: countryCode,
      );
      if (!mounted) return;
      setState(() {
        _options = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _options = [];
        _loading = false;
        _error = 'Failed to load cities';
      });
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      widget.onChanged(null);
      setState(() {
        _options = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () {
      _search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.countryCode != null;

    return Autocomplete<CityOption>(
      key: ValueKey(widget.countryCode ?? 'no-country'),
      optionsBuilder: (textEditingValue) => _options,
      displayStringForOption: (option) => option.displayLabel,
      initialValue:
          widget.value != null ? TextEditingValue(text: widget.value!.displayLabel) : null,
      onSelected: widget.onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (widget.value != null && controller.text.isEmpty) {
          controller.text = widget.value!.displayLabel;
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: isEnabled,
          decoration: InputDecoration(
            labelText: 'City',
            hintText: widget.countryCode == null
                ? 'Select a country first'
                : 'Start typing a city…',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_city),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.value != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: isEnabled
                            ? () {
                                controller.clear();
                                widget.onChanged(null);
                                setState(() {
                                  _options = [];
                                });
                              }
                            : null,
                      )
                    : null,
            errorText: _error,
          ),
          onChanged: _onQueryChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isEmpty) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.city),
                    subtitle: Text(option.formattedAddress),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
