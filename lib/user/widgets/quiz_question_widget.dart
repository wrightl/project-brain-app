import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/models/quiz.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Widget for rendering quiz questions with appropriate input types
class QuizQuestionWidget extends StatefulWidget {
  final QuizQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const QuizQuestionWidget({
    super.key,
    required this.question,
    this.value,
    required this.onChanged,
  });

  @override
  State<QuizQuestionWidget> createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget> {
  late dynamic _currentValue;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(QuizQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
      // Update controller text if it exists
      final controller = _controllers[widget.question.id];
      if (controller != null &&
          controller.text != (widget.value?.toString() ?? '')) {
        controller.text = widget.value?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  TextEditingController _getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: _currentValue?.toString() ?? '',
      );
    }
    return _controllers[key]!;
  }

  void _handleChanged(dynamic newValue) {
    setState(() {
      _currentValue = newValue;
    });
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question label
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.question.label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.question.mandatory)
              Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  '*',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),

        // Hint text
        if (widget.question.hint != null &&
            widget.question.hint!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            widget.question.hint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],

        SizedBox(height: AppSpacing.xl),

        // Input widget based on type
        _buildInputWidget(theme),
      ],
    );
  }

  Widget _buildInputWidget(ThemeData theme) {
    switch (widget.question.inputType) {
      case QuestionInputType.text:
        return _buildTextInput(theme);
      case QuestionInputType.number:
        return _buildNumberInput(theme);
      case QuestionInputType.email:
        return _buildEmailInput(theme);
      case QuestionInputType.tel:
        return _buildTelInput(theme);
      case QuestionInputType.url:
        return _buildUrlInput(theme);
      case QuestionInputType.date:
        return _buildDateInput(theme);
      case QuestionInputType.textarea:
        return _buildTextareaInput(theme);
      case QuestionInputType.choice:
        return _buildChoiceInput(theme);
      case QuestionInputType.multipleChoice:
        return _buildMultipleChoiceInput(theme);
      case QuestionInputType.scale:
        return _buildScaleInput(theme);
    }
  }

  Widget _buildTextInput(ThemeData theme) {
    final controller = _getController('${widget.question.id}_text');
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter your answer',
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => _handleChanged(value.isEmpty ? null : value),
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildNumberInput(ThemeData theme) {
    final controller = _getController('${widget.question.id}_number');
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter a number',
        border: const OutlineInputBorder(),
        suffixText:
            widget.question.minValue != null || widget.question.maxValue != null
                ? _buildRangeText()
                : null,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      onChanged: (value) {
        if (value.isEmpty) {
          _handleChanged(null);
          return;
        }
        final numValue = num.tryParse(value);
        if (numValue != null) {
          // Validate min/max
          if (widget.question.minValue != null &&
              numValue < widget.question.minValue!) {
            return;
          }
          if (widget.question.maxValue != null &&
              numValue > widget.question.maxValue!) {
            return;
          }
          _handleChanged(numValue);
        }
      },
    );
  }

  String _buildRangeText() {
    final parts = <String>[];
    if (widget.question.minValue != null) {
      parts.add('min: ${widget.question.minValue}');
    }
    if (widget.question.maxValue != null) {
      parts.add('max: ${widget.question.maxValue}');
    }
    return parts.join(', ');
  }

  Widget _buildEmailInput(ThemeData theme) {
    final controller = _getController('${widget.question.id}_email');
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter your email',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: (value) => _handleChanged(value.isEmpty ? null : value),
    );
  }

  Widget _buildTelInput(ThemeData theme) {
    final controller = _getController('${widget.question.id}_tel');
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter your phone number',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      onChanged: (value) => _handleChanged(value.isEmpty ? null : value),
    );
  }

  Widget _buildUrlInput(ThemeData theme) {
    final controller = _getController('${widget.question.id}_url');
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter a URL',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.link),
      ),
      keyboardType: TextInputType.url,
      onChanged: (value) => _handleChanged(value.isEmpty ? null : value),
    );
  }

  Widget _buildTextareaInput(ThemeData theme) {
    final controller = _getController('${widget.question.id}_textarea');
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter your answer',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      minLines: 3,
      onChanged: (value) => _handleChanged(value.isEmpty ? null : value),
    );
  }

  Widget _buildDateInput(ThemeData theme) {
    DateTime? currentDate;
    if (_currentValue != null) {
      if (_currentValue is DateTime) {
        currentDate = _currentValue as DateTime;
      } else if (_currentValue is String) {
        currentDate = DateTime.tryParse(_currentValue as String);
      }
    }

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initialDate = currentDate ?? now;

        // Parse min/max as years if they're reasonable year values
        DateTime? firstDate;
        DateTime? lastDate;

        if (widget.question.minValue != null) {
          final minVal = widget.question.minValue!.toInt();
          // If it's a reasonable year (1900-2100), treat as year
          if (minVal >= 1900 && minVal <= 2100) {
            firstDate = DateTime(minVal);
          } else {
            // Otherwise treat as days offset from now
            firstDate = now.subtract(Duration(days: minVal));
          }
        } else {
          firstDate = DateTime(1900);
        }

        if (widget.question.maxValue != null) {
          final maxVal = widget.question.maxValue!.toInt();
          if (maxVal >= 1900 && maxVal <= 2100) {
            lastDate = DateTime(maxVal);
          } else {
            lastDate = now.add(Duration(days: maxVal));
          }
        } else {
          lastDate = DateTime(2100);
        }

        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );

        if (pickedDate != null) {
          _handleChanged(pickedDate.toIso8601String().split('T')[0]);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: widget.question.placeholder ?? 'Select a date',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          currentDate != null
              ? '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}'
              : 'Select a date',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: currentDate != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceInput(ThemeData theme) {
    if (widget.question.choices == null || widget.question.choices!.isEmpty) {
      return Text(
        'No choices available',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return RadioGroup<String>(
      groupValue: _currentValue is String ? _currentValue as String : null,
      onChanged: (value) {
        if (value != null) _handleChanged(value);
      },
      child: Column(
        children: widget.question.choices!.map((choice) {
          return RadioListTile<String>(
            title: Text(choice),
            value: choice,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultipleChoiceInput(ThemeData theme) {
    if (widget.question.choices == null || widget.question.choices!.isEmpty) {
      return Text(
        'No choices available',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    final selectedValues =
        _currentValue is List ? List<String>.from(_currentValue) : <String>[];

    return Column(
      children: widget.question.choices!.map((choice) {
        final isSelected = selectedValues.contains(choice);
        return CheckboxListTile(
          title: Text(choice),
          value: isSelected,
          onChanged: (checked) {
            final newList = List<String>.from(selectedValues);
            if (checked == true) {
              if (!newList.contains(choice)) {
                newList.add(choice);
              }
            } else {
              newList.remove(choice);
            }
            _handleChanged(newList.isEmpty ? null : newList);
          },
        );
      }).toList(),
    );
  }

  Widget _buildScaleInput(ThemeData theme) {
    final min = widget.question.minValue?.toDouble() ?? 1.0;
    final max = widget.question.maxValue?.toDouble() ?? 5.0;
    final currentValue =
        _currentValue is num ? (_currentValue as num).toDouble() : min;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display current value prominently
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: Center(
            child: Text(
              currentValue.toInt().toString(),
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Slider
        Slider(
          value: currentValue.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: currentValue.toInt().toString(),
          onChanged: (value) {
            // Round to nearest integer for discrete scale values
            final roundedValue = value.round();
            _handleChanged(roundedValue);
          },
        ),
        // Min and max labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toInt().toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              max.toInt().toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
