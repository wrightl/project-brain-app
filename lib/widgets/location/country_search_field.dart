import 'package:flutter/material.dart';
import 'package:projectbrain/models/location.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

class CountrySearchField extends StatelessWidget {
  final List<CountryOption> countries;
  final CountryOption? value;
  final ValueChanged<CountryOption?> onChanged;
  final bool isLoading;
  final bool enabled;

  const CountrySearchField({
    super.key,
    required this.countries,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<CountryOption>(
      key: ValueKey(value?.code ?? 'no-country'),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return countries;
        }
        return countries.where((country) {
          return country.name.toLowerCase().contains(query) ||
              country.code.toLowerCase().contains(query);
        });
      },
      displayStringForOption: (option) => option.name,
      initialValue: value != null ? TextEditingValue(text: value!.name) : null,
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (value != null && controller.text.isEmpty) {
          controller.text = value!.name;
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled && !isLoading,
          decoration: InputDecoration(
            labelText: 'Country',
            hintText: 'Select country',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.public),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : value != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: enabled
                            ? () {
                                controller.clear();
                                onChanged(null);
                              }
                            : null,
                      )
                    : null,
          ),
          onChanged: (text) {
            if (text.trim().isEmpty) {
              onChanged(null);
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
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
                    title: Text(option.name),
                    subtitle: Text(option.code),
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
