import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../widgets/field.dart';
import '../models/trip.dart';

class SpeciesPage extends StatefulWidget {
  final Trip tripData;
  final ValueChanged<String> onDateChange;
  final List<String> rswTanks;

  const SpeciesPage({
    super.key,
    required this.tripData,
    required this.onDateChange,
    required this.rswTanks,
  });

  @override
  State<SpeciesPage> createState() => _SpeciesPageState();
}

class _SpeciesSample {
  String species;
  String size;
  double weight;
  double percent;
  String coreTemp;

  _SpeciesSample({
    required this.species,
    required this.size,
    this.weight = 0,
    this.percent = 0,
    this.coreTemp = '',
  });
}

class _SpeciesPageState extends State<SpeciesPage> {
  late String activeTank;
  final Map<String, List<_SpeciesSample>> _samplesByTank = {};
  final TextEditingController _totalTripController = TextEditingController();
  final Map<String, String> _tankTonnages = {};
  final TextEditingController _tonnageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    activeTank = widget.rswTanks.isNotEmpty ? widget.rswTanks.first : 'Port 1';
    for (final tank in widget.rswTanks) {
      _samplesByTank[tank] = [
        _createEmptySample(),
      ];
      _tankTonnages[tank] = '';
    }
  }

  _SpeciesSample _createEmptySample() {
    final defaultSpecies = SPECIES_OPTIONS.first;
    final sizes = SPECIES_SIZE_OPTIONS[defaultSpecies]!;
    return _SpeciesSample(
      species: defaultSpecies,
      size: sizes.first,
      weight: 0,
      percent: 0,
      coreTemp: '',
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(widget.tripData.tripDate) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      widget.onDateChange(formatted);
      setState(() {
        widget.tripData.tripDate = formatted;
      });
    }
  }

  List<_SpeciesSample> get _currentSamples =>
      _samplesByTank[activeTank] ?? <_SpeciesSample>[];

  void _recomputePercents() {
    final samples = _currentSamples;
    final totalWeight =
        samples.fold<double>(0, (sum, s) => sum + (s.weight.isNaN ? 0 : s.weight));

    if (totalWeight <= 0) {
      for (final s in samples) {
        s.percent = 0;
      }
    } else {
      for (final s in samples) {
        s.percent = (s.weight / totalWeight) * 100;
      }
    }
    setState(() {});
  }

  void _updateWeight(int index, String value) {
    final w = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    _currentSamples[index].weight = w;
    _recomputePercents();
  }

  void _updateSpecies(int index, String newSpecies) {
    final sizes = SPECIES_SIZE_OPTIONS[newSpecies] ?? <String>[];
    _currentSamples[index].species = newSpecies;
    if (sizes.isNotEmpty) {
      _currentSamples[index].size = sizes.first;
    }
    _recomputePercents();
  }

  void _updateSize(int index, String newSize) {
    _currentSamples[index].size = newSize;
    setState(() {});
  }

  void _updateCoreTemp(int index, String value) {
    _currentSamples[index].coreTemp = value;
    setState(() {});
  }

  void _addRow() {
    _currentSamples.add(_createEmptySample());
    _recomputePercents();
  }

  int _gridColsForWidth(double width, {int max = 3}) {
    if (width < 560) return 1;
    if (width < 960) return 2;
    return max;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final samples = _currentSamples;
        final totalSampleWeight =
            samples.fold<double>(0, (sum, s) => sum + (s.weight.isNaN ? 0 : s.weight));

        _tonnageController.text = _tankTonnages[activeTank] ?? '';

        final tripGridCount = _gridColsForWidth(constraints.maxWidth, max: 3);
        final summaryGridCount = _gridColsForWidth(constraints.maxWidth, max: 2);
        final isNarrow = constraints.maxWidth < 1100;

        final leftCard = Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RSW Tanks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a tank to view and edit sampling details.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[600]),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildTankRow(['Port 1', 'Cent 1', 'Stb 1']),
                    const SizedBox(height: 8),
                    _buildTankRow(['Port 2', 'Cent 2', 'Stb 2']),
                    const SizedBox(height: 8),
                    _buildTankRow(['Port 3', 'Cent 3', 'Stb 3']),
                  ],
                ),
              ],
            ),
          ),
        );

        final rightColumn = Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details for: $activeTank',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: summaryGridCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 3.5,
                      ),
                      children: [
                        Field(
                          label: 'Tonnage tank (kg)',
                          value: _tonnageController.text.isEmpty
                              ? null
                              : _tonnageController.text,
                          onChanged: (v) {
                            _tonnageController.text = v;
                            _tankTonnages[activeTank] = v;
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const Field(
                          label: 'Hold / bay',
                          placeholder: 'Hold 1',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sample total for $activeTank: ${totalSampleWeight.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Species Sampling for $activeTank',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: _addRow,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            side: const BorderSide(color: Color(0xFF007BFF)),
                          ),
                          child: const Text(
                            '+ Add Row',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        headingTextStyle: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey[600],
                        ),
                        columns: const [
                          DataColumn(label: Text('Species')),
                          DataColumn(label: Text('Hold / Tank')),
                          DataColumn(label: Text('Weight (kg)')),
                          DataColumn(label: Text('%')),
                          DataColumn(label: Text('Core temp (C)')),
                          DataColumn(label: Text('Size')),
                        ],
                        rows: List.generate(samples.length, (index) {
                          final row = samples[index];
                          final sizes = SPECIES_SIZE_OPTIONS[row.species] ?? <String>[];
                          final displayedSize = sizes.contains(row.size)
                              ? row.size
                              : (sizes.isNotEmpty ? sizes.first : '');

                          return DataRow(
                            cells: [
                              DataCell(
                                DropdownButton<String>(
                                  value: row.species,
                                  items: SPECIES_OPTIONS
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      _updateSpecies(index, v);
                                    }
                                  },
                                ),
                              ),
                              DataCell(Text(activeTank)),
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue:
                                        row.weight == 0 ? '' : row.weight.toStringAsFixed(1),
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => _updateWeight(index, v),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  row.percent.isNaN
                                      ? '0.0'
                                      : row.percent.toStringAsFixed(1),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: row.coreTemp,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => _updateCoreTemp(index, v),
                                  ),
                                ),
                              ),
                              DataCell(
                                DropdownButton<String>(
                                  value: displayedSize.isEmpty ? null : displayedSize,
                                  items: sizes
                                      .map(
                                        (sz) => DropdownMenuItem(
                                          value: sz,
                                          child: Text(sz),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      _updateSize(index, v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Percentage = (Weight of species / Sample Total) x 100',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Species & Sampling',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture sampling weights and temps per RSW tank.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[600]),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Trip Info',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: tripGridCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 3.5,
                          ),
                          children: [
                            Field(
                              label: 'Trip code',
                              value: widget.tripData.tripCode,
                              readOnly: true,
                            ),
                            Field(
                              label: 'Trip date',
                              value: widget.tripData.tripDate,
                              onTap: _pickDate,
                            ),
                            Field(
                              label: 'Vessel',
                              value: widget.tripData.vessel,
                              readOnly: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: summaryGridCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 3.5,
                          ),
                          children: [
                            Field(
                              label: 'Total trip (kg)',
                              value: _totalTripController.text.isEmpty
                                  ? null
                                  : _totalTripController.text,
                              onChanged: (v) {
                                _totalTripController.text = v;
                              },
                            ),
                            Field(
                              label: 'Number of RSW tanks',
                              value: widget.rswTanks.length.toString(),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftCard,
                          const SizedBox(height: 16),
                          rightColumn,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: leftCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: rightColumn),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTankRow(List<String> tanks) {
    return Row(
      children: tanks.map((tank) {
        final isActive = tank == activeTank;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: isActive ? Colors.lightBlue : Colors.blueGrey[50],
                foregroundColor: isActive ? Colors.white : Colors.blueGrey[800],
              ),
              onPressed: () {
                setState(() {
                  activeTank = tank;
                });
              },
              child: Text(
                tank,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
