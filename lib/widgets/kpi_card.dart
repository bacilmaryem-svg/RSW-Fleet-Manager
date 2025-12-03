import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blueGrey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              helper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blueGrey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
