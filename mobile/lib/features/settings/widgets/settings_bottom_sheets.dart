import 'package:flutter/material.dart';
import '../constants/settings_constants.dart';

/// Base bottom sheet with consistent styling
class SettingsBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isScrollControlled;

  const SettingsBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.isScrollControlled = false,
  });

  /// Show this bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: SettingsTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SettingsTheme.bottomSheetBorderRadius),
        ),
      ),
      builder: (ctx) => SettingsBottomSheet(
        title: title,
        isScrollControlled: isScrollControlled,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );

    if (isScrollControlled) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: content,
    );
  }
}

/// Radio option picker bottom sheet
class RadioPickerSheet<T> extends StatelessWidget {
  final String title;
  final T currentValue;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  const RadioPickerSheet({
    super.key,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onSelected,
  });

  /// Show a radio picker bottom sheet
  static Future<void> show<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required Map<T, String> options,
    required ValueChanged<T> onSelected,
  }) {
    return SettingsBottomSheet.show(
      context: context,
      title: title,
      child: RadioPickerSheet<T>(
        title: title,
        currentValue: currentValue,
        options: options,
        onSelected: (value) {
          onSelected(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.entries.map((entry) {
        return ListTile(
          leading: Icon(
            entry.key == currentValue
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: entry.key == currentValue
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          title: Text(entry.value),
          onTap: () => onSelected(entry.key),
        );
      }).toList(),
    );
  }
}

/// Form bottom sheet with text fields
class FormBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final String submitLabel;
  final VoidCallback onSubmit;

  const FormBottomSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields,
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              onSubmit();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(submitLabel),
          ),
        ),
      ],
    );
  }
}

/// Styled text field for settings forms
class SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;

  const SettingsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
