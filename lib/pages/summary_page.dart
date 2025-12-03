import 'package:flutter/material.dart';
import '../models/cistern.dart';
import '../widgets/kpi_card.dart';
import '../services/pdf_service.dart';
import '../models/trip.dart';

class SummaryPage extends StatelessWidget {
  final List<Cistern> cisternsData;

  const SummaryPage({
    super.key,
    required this.cisternsData,
  });

  double _parseWeight(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double totalNet =
        cisternsData.fold(0.0, (sum, c) => sum + _parseWeight(c.netWeight));
    final String totalNetLabel =
        '${totalNet.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} kg';

    final int cisternCount = cisternsData.length;
    final int buyerCount = cisternsData.map((c) => c.buyer).toSet().length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final kpiWidth =
            isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;

        return Container(
          color: const Color(0xFFF5F8FC),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007BFF), Color(0xFF38BDF8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.water, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fish Tank Dashboard',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Overview of RSW tanks, cisterns, and buyers for this trip.',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: isNarrow
                                    ? constraints.maxWidth
                                    : constraints.maxWidth * 0.6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Summary & Dashboard',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Trip overview with export options.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.blueGrey[500]),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      final trip = Trip(
                                        id: 'TEMP',
                                        tripCode:
                                            'TRIP-${DateTime.now().millisecondsSinceEpoch}',
                                        tripDate: DateTime.now()
                                            .toString()
                                            .split(' ')
                                            .first,
                                        vessel: 'M/V Ocean Venture',
                                      );

                                      await PdfService.generateTripPdf(
                                          trip, cisternsData);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Color(0xFF007BFF)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                    child: const Text('Export Trip Report (PDF)',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      // Future: export CSV
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Color(0xFF007BFF)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                    child: const Text('Export CSV',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: kpiWidth,
                                child: KpiCard(
                                  label: 'Total Trip Weight',
                                  value: totalNetLabel,
                                  helper: 'Sum of net weight from cisterns',
                                ),
                              ),
                              SizedBox(
                                width: kpiWidth,
                                child: KpiCard(
                                  label: 'Cisterns',
                                  value: cisternCount.toString(),
                                  helper: 'Declared for this trip',
                                ),
                              ),
                              SizedBox(
                                width: kpiWidth,
                                child: KpiCard(
                                  label: 'Buyers',
                                  value: buyerCount.toString(),
                                  helper: 'Factories/buyers in this trip',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cisterns by Buyer',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...cisternsData.map((c) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text('${c.id} - ${c.buyer}'),
                              subtitle:
                                  Text('Tank ${c.tank} - Net: ${c.netWeight} kg'),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: isNarrow
                                ? constraints.maxWidth
                                : constraints.maxWidth * 0.6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checks & Traceability',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All cisterns = $totalNetLabel',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  'All tanks have cisterns & buyer data (wireframe assumption)',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              // Future: mark trip complete
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: const Text(
                              'Mark Trip as Completed',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
