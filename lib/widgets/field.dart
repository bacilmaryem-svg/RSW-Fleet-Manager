// lib/widgets/field.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Field extends StatelessWidget {
  final String label;
  final String? value;
  final String? placeholder;
  final bool readOnly;
  final Widget? child;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const Field({
    super.key,
    required this.label,
    this.value,
    this.placeholder,
    this.readOnly = false,
    this.child,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 6),

        // --- Custom child (dropdown etc.)
        if (child != null)
          child!
        else
          SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              readOnly: readOnly || onTap != null,
              onChanged: onChanged,
              onTap: onTap,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: onTap != null
                    ? const Icon(Icons.calendar_today, size: 16)
                    : null,
                filled: true,
                fillColor: readOnly ? Colors.grey[100] : Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class DateField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value.isNotEmpty
          ? DateTime.tryParse(widget.value) ?? now
          : now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      widget.onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: widget.value);

    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_month),
          ),
        ),
      ),
    );
  }
}
