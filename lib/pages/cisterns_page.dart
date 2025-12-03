// lib/pages/cisterns_page.dart
import 'package:flutter/material.dart';
import '../models/cistern.dart';

class CisternsPage extends StatefulWidget {
  final List<String> rswTanks;
  final List<String> buyers;
  final List<Cistern> cisternsData;
  final ValueChanged<List<Cistern>> onCisternsChange;

  const CisternsPage({
    super.key,
    required this.rswTanks,
    required this.buyers,
    required this.cisternsData,
    required this.onCisternsChange,
  });

  @override
  State<CisternsPage> createState() => _CisternsPageState();
}

class _CisternsPageState extends State<CisternsPage> {
  static const double _kLeftMaxWidth = 320;
  static const double _kInputHeight = 32;
  static const EdgeInsets _kPad = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  static const BorderRadius _kRadius = BorderRadius.all(Radius.circular(8));
  static const TextStyle _kInputText = TextStyle(fontSize: 12, height: 1.1);

  static const double _wTruck = 96;
  static const double _wTank = 96;
  static const double _wStart = 60;
  static const double _wEnd = 60;
  static const double _wWater = 64;
  static const double _wBuyer = 128;
  static const double _wIn = 84;
  static const double _wOut = 84;
  static const double _wNet = 90;

  static const double _kColSpacing = 4;
  static const double _kHeadH = 26;
  static const double _kRowH = 42;

  InputDecoration get _decoration => const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: _kRadius),
        contentPadding: _kPad,
      );

  late String _selectedTank;

  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _stopCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController(text: '');

  final TextEditingController _tonnageCtrl = TextEditingController();
  static const double _capacityPerCistern = 25000;
  int _requiredCisterns = 0;
  final Map<String, double> _tankTonnage = {};

  late final Set<String> _buyerOptions = {
    'SJOVIK',
    'AFROPISCA',
    'DIPROMER',
    ...widget.buyers.map((e) => e.trim()).where((e) => e.isNotEmpty),
  };

  bool _starterInserted = false;

  @override
  void initState() {
    super.initState();
    _selectedTank = widget.rswTanks.isNotEmpty ? widget.rswTanks.first : '';
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _stopCtrl.dispose();
    _durationCtrl.dispose();
    _tonnageCtrl.dispose();
    super.dispose();
  }

  void _onStartChanged(String _) => _updateOffloadingDuration();
  void _onStopChanged(String _) => _updateOffloadingDuration();

  void _updateOffloadingDuration() {
    final s = _parseTime(_startCtrl.text);
    final e = _parseTime(_stopCtrl.text);
    if (s == null || e == null) {
      _durationCtrl.text = '';
      setState(() {});
      return;
    }
    int diff = e - s;
    if (diff < 0) diff += 24 * 60;
    final hh = diff ~/ 60, mm = diff % 60;
    _durationCtrl.text = '${hh}h ${mm.toString().padLeft(2, '0')}m';
    setState(() {});
  }

  int? _parseTime(String text) {
    if (text.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final mi = int.tryParse(m.group(2)!);
    if (h == null || mi == null || h < 0 || h > 23 || mi < 0 || mi > 59) return null;
    return h * 60 + mi;
  }

  void _onTonnageChanged(String value) {
    final tonnage = double.tryParse(value.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
    setState(() {
      _tankTonnage[_selectedTank] = tonnage;
      _requiredCisterns = tonnage <= 0 ? 0 : (tonnage / _capacityPerCistern).ceil();
    });
  }

  void _onTankChanged(String? newTank) {
    if (newTank == null) return;
    setState(() {
      _selectedTank = newTank;
      final t = _tankTonnage[_selectedTank];
      _tonnageCtrl.text = (t == null || t == 0) ? '' : t.toStringAsFixed(0);
      _onTonnageChanged(_tonnageCtrl.text);
      _starterInserted = false;
    });
  }

  List<MapEntry<int, Cistern>> get _rowsForSelectedTank =>
      widget.cisternsData.asMap().entries.where((e) => e.value.tank == _selectedTank).toList();

  void _updateCistern(int index, void Function(Cistern c) updater) {
    final list = List<Cistern>.from(widget.cisternsData);
    updater(list[index]);
    widget.onCisternsChange(list);
  }

  void _addCistern() {
    final list = List<Cistern>.from(widget.cisternsData)
      ..add(Cistern(
        id: '',
        tank: _selectedTank,
        start: '',
        end: '',
        water: '',
        buyer: '',
        weightIn: '',
        weightOut: '',
        netWeight: '',
      ));
    widget.onCisternsChange(list);
  }

  void _duplicateLastForTank() {
    final all = List<Cistern>.from(widget.cisternsData);
    final lastIndex = all.lastIndexWhere((c) => c.tank == _selectedTank);
    if (lastIndex == -1) return;
    final last = all[lastIndex];
    all.add(Cistern(
      id: '',
      tank: _selectedTank,
      start: last.start,
      end: last.end,
      water: last.water,
      buyer: last.buyer,
      weightIn: last.weightIn,
      weightOut: last.weightOut,
      netWeight: last.netWeight,
    ));
    widget.onCisternsChange(all);
  }

  void _autoGenerateFromTonnage() {
    if (_requiredCisterns <= 0) return;
    final others = widget.cisternsData.where((c) => c.tank != _selectedTank).toList();
    final generated = List<Cistern>.generate(
      _requiredCisterns,
      (_) => Cistern(
        id: '',
        tank: _selectedTank,
        start: '',
        end: '',
        water: '',
        buyer: '',
        weightIn: '',
        weightOut: '',
        netWeight: '',
      ),
    );
    widget.onCisternsChange([...others, ...generated]);
  }

  void _updateWeightsAuto(int index, {String? inText, String? outText}) {
    final list = List<Cistern>.from(widget.cisternsData);
    final c = list[index];

    final inStr = inText ?? c.weightIn;
    final outStr = outText ?? c.weightOut;

    final inVal = double.tryParse(inStr.replaceAll(' ', '').replaceAll(',', '.'));
    final outVal = double.tryParse(outStr.replaceAll(' ', '').replaceAll(',', '.'));

    c.weightIn = inStr;
    c.weightOut = outStr;

    if (inVal != null && outVal != null) {
      c.netWeight = (inVal - outVal).toStringAsFixed(0);
    } else {
      c.netWeight = '';
    }
    widget.onCisternsChange(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _rowsForSelectedTank;
    final hasRows = rows.isNotEmpty;

    if (!hasRows && !_starterInserted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_starterInserted) {
          _starterInserted = true;
          _addCistern();
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;

        final leftPanel = SizedBox(
          width: isNarrow ? constraints.maxWidth : _kLeftMaxWidth,
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Text(
                    'Offloading & Tank setup',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Capture offloading times and RSW tank tonnage.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[600]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: _LabeledTable(rows: [
                      LabeledRow(
                        label: 'Start offloading',
                        field: SizedBox(
                          height: _kInputHeight,
                          child: TextField(
                            controller: _startCtrl,
                            keyboardType: TextInputType.datetime,
                            decoration: _decoration,
                            style: _kInputText,
                            onChanged: _onStartChanged,
                          ),
                        ),
                      ),
                      LabeledRow(
                        label: 'Stop offloading',
                        field: SizedBox(
                          height: _kInputHeight,
                          child: TextField(
                            controller: _stopCtrl,
                            keyboardType: TextInputType.datetime,
                            decoration: _decoration,
                            style: _kInputText,
                            onChanged: _onStopChanged,
                          ),
                        ),
                      ),
                      LabeledRow(
                        label: 'Hours of offloading (auto)',
                        field: SizedBox(
                          height: _kInputHeight,
                          child: TextField(
                            controller: _durationCtrl,
                            readOnly: true,
                            decoration: _decoration,
                            style: _kInputText,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RSW Tank Selection',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _LabeledTable(rows: [
                          LabeledRow(
                            label: 'RSW Tank',
                            field: SizedBox(
                              height: _kInputHeight,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedTank.isEmpty ? null : _selectedTank,
                                items: widget.rswTanks
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: _onTankChanged,
                                decoration: _decoration,
                                style: _kInputText,
                                isDense: true,
                              ),
                            ),
                          ),
                          LabeledRow(
                            label: 'Tonnage tank (kg)',
                            field: SizedBox(
                              height: _kInputHeight,
                              child: TextField(
                                controller: _tonnageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _decoration,
                                style: _kInputText,
                                onChanged: _onTonnageChanged,
                              ),
                            ),
                          ),
                          LabeledRow(
                            label: 'Capacity per cistern (kg)',
                            field: SizedBox(
                              height: _kInputHeight,
                              child: TextField(
                                controller: TextEditingController(text: _capacityPerCistern.toStringAsFixed(0)),
                                readOnly: true,
                                decoration: _decoration,
                                style: _kInputText,
                              ),
                            ),
                          ),
                          LabeledRow(
                            label: 'Cisterns required (auto)',
                            field: SizedBox(
                              height: _kInputHeight,
                              child: TextField(
                                controller: TextEditingController(
                                    text: _requiredCisterns == 0 ? '' : _requiredCisterns.toString()),
                                readOnly: true,
                                decoration: _decoration,
                                style: _kInputText,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            onPressed: _autoGenerateFromTonnage,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            child: const Text('Auto-generate cisterns'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final rightPanel = Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
                  children: [
                    FilledButton.tonal(
                      onPressed: _duplicateLastForTank,
                      child: const Text('Duplicate last cistern'),
                    ),
                    OutlinedButton(onPressed: _addCistern, child: const Text('+ Add Cistern')),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 880),
                    child: _buildDataTable(theme),
                  ),
                ),
              ],
            ),
          ),
        );

        return Container(
          color: const Color(0xFFF5F8FC),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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
                        const Icon(Icons.local_shipping_outlined, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unloading & Cisterns',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Allocate cisterns from each tank\'s tonnage (25,000 kg base).',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leftPanel,
                            const SizedBox(height: 12),
                            rightPanel,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leftPanel,
                            const SizedBox(width: 12),
                            Expanded(child: rightPanel),
                          ],
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(ThemeData theme) {
    InputDecoration cellDec() => _decoration.copyWith(contentPadding: _kPad);

    return DataTable(
      columnSpacing: _kColSpacing,
      headingRowHeight: _kHeadH,
      dataRowMinHeight: _kRowH,
      dataRowMaxHeight: _kRowH,
      columns: const [
        DataColumn(label: Text('Truck / Cistern')),
        DataColumn(label: Text('RSW Tank')),
        DataColumn(label: Text('Start')),
        DataColumn(label: Text('End')),
        DataColumn(label: Text('Water (m3)')),
        DataColumn(label: Text('Buyer')),
        DataColumn(label: Text('Weight IN (kg)')),
        DataColumn(label: Text('Weight OUT (kg)')),
        DataColumn(label: Text('Net weight (kg)')),
      ],
      rows: _rowsForSelectedTank.map((entry) {
        final index = entry.key;
        final c = entry.value;

        return DataRow(cells: [
          DataCell(SizedBox(
            width: _wTruck,
            child: TextFormField(
              initialValue: c.id,
              decoration: cellDec(),
              style: _kInputText,
              onChanged: (v) => _updateCistern(index, (ci) => ci.id = v),
            ),
          )),
          DataCell(SizedBox(
            width: _wTank,
            child: DropdownButtonFormField<String>(
              initialValue: c.tank.isEmpty ? _selectedTank : c.tank,
              items: widget.rswTanks.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val == null) return;
                _updateCistern(index, (ci) => ci.tank = val);
              },
              decoration: cellDec(),
              style: _kInputText,
              isDense: true,
            ),
          )),
          DataCell(SizedBox(
            width: _wStart,
            child: TextFormField(
              initialValue: c.start,
              decoration: cellDec(),
              style: _kInputText,
              onChanged: (v) => _updateCistern(index, (ci) => ci.start = v),
            ),
          )),
          DataCell(SizedBox(
            width: _wEnd,
            child: TextFormField(
              initialValue: c.end,
              decoration: cellDec(),
              style: _kInputText,
              onChanged: (v) => _updateCistern(index, (ci) => ci.end = v),
            ),
          )),
          DataCell(SizedBox(
            width: _wWater,
            child: TextFormField(
              initialValue: c.water,
              decoration: cellDec(),
              style: _kInputText,
              onChanged: (v) => _updateCistern(index, (ci) => ci.water = v),
            ),
          )),
          DataCell(SizedBox(
            width: _wBuyer,
            child: _BuyerInput(
              initial: c.buyer,
              options: _buyerOptions,
              inputHeight: _kInputHeight,
              decoration: _decoration,
              textStyle: _kInputText,
              onChanged: (val) {
                final v = val.trim();
                if (v.isEmpty) return;
                setState(() => _buyerOptions.add(v));
                _updateCistern(index, (ci) => ci.buyer = v);
              },
            ),
          )),
          DataCell(SizedBox(
            width: _wIn,
            child: TextFormField(
              initialValue: c.weightIn,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: cellDec(),
              style: _kInputText,
              onChanged: (v) => _updateWeightsAuto(index, inText: v),
            ),
          )),
          DataCell(SizedBox(
            width: _wOut,
            child: TextFormField(
              initialValue: c.weightOut,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: cellDec(),
              style: _kInputText,
              onChanged: (v) => _updateWeightsAuto(index, outText: v),
            ),
          )),
          DataCell(SizedBox(
            width: _wNet,
            child: TextFormField(
              initialValue: c.netWeight,
              readOnly: true,
              textAlign: TextAlign.right,
              decoration: cellDec(),
              style: _kInputText,
            ),
          )),
        ]);
      }).toList(),
    );
  }
}

class _LabeledTable extends StatelessWidget {
  final List<LabeledRow> rows;
  const _LabeledTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows
          .map((r) => TableRow(children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                  child: Text(r.label, style: const TextStyle(fontSize: 12)),
                ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: r.field),
              ]))
          .toList(),
    );
  }
}

class LabeledRow {
  final String label;
  final Widget field;
  LabeledRow({required this.label, required this.field});
}

class _BuyerInput extends StatefulWidget {
  final String initial;
  final Set<String> options;
  final double inputHeight;
  final InputDecoration decoration;
  final TextStyle textStyle;
  final ValueChanged<String> onChanged;

  const _BuyerInput({
    required this.initial,
    required this.options,
    required this.inputHeight,
    required this.decoration,
    required this.textStyle,
    required this.onChanged,
  });

  @override
  State<_BuyerInput> createState() => _BuyerInputState();
}

class _BuyerInputState extends State<_BuyerInput> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commitIfValid() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _ctrl,
      focusNode: _focus,
      optionsBuilder: (TextEditingValue tev) {
        final q = tev.text.trim().toLowerCase();
        if (q.isEmpty) return widget.options.toList();
        return widget.options.where((o) => o.toLowerCase().contains(q)).toList();
      },
      onSelected: (String selection) {
        _ctrl.text = selection;
        _commitIfValid();
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        return SizedBox(
          height: widget.inputHeight,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            decoration: widget.decoration,
            style: widget.textStyle,
            onEditingComplete: _commitIfValid,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180, minWidth: 140),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    title: Text(opt, style: const TextStyle(fontSize: 12)),
                    onTap: () => onSelected(opt),
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
