import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  static const double _kLeftMaxWidth = 340;
  static const EdgeInsets _kPad = EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  static const BorderRadius _kRadius = BorderRadius.all(Radius.circular(8));
  
  TextStyle get _kInputText => GoogleFonts.lato(fontSize: 13, color: const Color(0xFF0F172A));
  TextStyle get _kLabelText => GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B));

  InputDecoration get _decoration => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hoverColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: _kRadius,
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _kRadius,
          borderSide: BorderSide(color: Colors.blueGrey.shade100),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _kRadius,
          borderSide: BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
        contentPadding: _kPad,
        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
    });
  }

  List<Cistern> get _rowsForSelectedTank =>
      widget.cisternsData.where((c) => c.tank == _selectedTank).toList();

  void _addOrUpdateCistern(Cistern cistern, {bool isNew = false}) {
    final list = List<Cistern>.from(widget.cisternsData);
    if (isNew) {
      list.add(cistern);
    } else {
      final index = list.indexWhere((c) => c == cistern); // Note: Cistern needs equality or ID
      // Since we don't have IDs, we might need to pass the index or original object
      // For now, let's assume we replace the object in the list if it exists, or we might need to handle this better
      // A better approach for this demo: remove the old one and add the new one, or update in place if we have index
    }
    widget.onCisternsChange(list);
  }
  
  void _updateCisternList(List<Cistern> newList) {
    widget.onCisternsChange(newList);
  }

  void _autoGenerateFromTonnage() {
    if (_requiredCisterns <= 0) return;
    
    final start = _startCtrl.text;
    final end = _stopCtrl.text;
    final totalTonnage = _tankTonnage[_selectedTank] ?? 0;
    final avgWeight = totalTonnage > 0 ? (totalTonnage / _requiredCisterns).floor().toString() : '';

    final others = widget.cisternsData.where((c) => c.tank != _selectedTank).toList();
    final generated = List<Cistern>.generate(
      _requiredCisterns,
      (index) => Cistern(
        id: '',
        tank: _selectedTank,
        start: start,
        end: end,
        water: '',
        buyer: '',
        weightIn: '',
        weightOut: '',
        netWeight: avgWeight,
      ),
    );
    widget.onCisternsChange([...others, ...generated]);
  }

  Future<void> _showCisternDialog({Cistern? cistern, int? index}) async {
    final isEditing = cistern != null;
    final tempCistern = cistern ?? Cistern(
      id: '',
      tank: _selectedTank,
      start: '',
      end: '',
      water: '',
      buyer: '',
      weightIn: '',
      weightOut: '',
      netWeight: '',
    );

    // Controllers for the dialog
    final idCtrl = TextEditingController(text: tempCistern.id);
    final startCtrl = TextEditingController(text: tempCistern.start);
    final endCtrl = TextEditingController(text: tempCistern.end);
    final waterCtrl = TextEditingController(text: tempCistern.water);
    final weightInCtrl = TextEditingController(text: tempCistern.weightIn);
    final weightOutCtrl = TextEditingController(text: tempCistern.weightOut);
    final netWeightCtrl = TextEditingController(text: tempCistern.netWeight);
    
    String currentBuyer = tempCistern.buyer;
    String currentTank = tempCistern.tank.isNotEmpty ? tempCistern.tank : _selectedTank;

    await showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        return AlertDialog(
          title: Text(isEditing ? 'Edit Cistern' : 'Add New Cistern', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Container(
              width: isMobile ? width * 0.9 : 500,
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField('Truck / Cistern ID', idCtrl),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: currentTank,
                    items: widget.rswTanks.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => currentTank = v!,
                    decoration: _decoration.copyWith(labelText: 'RSW Tank'),
                  ),
                  const SizedBox(height: 12),
                  if (isMobile) ...[
                    _buildDialogField(
                      'Start Time',
                      startCtrl,
                      isReadOnly: true,
                      onTap: () => _selectDateTime(context, startCtrl),
                      suffixIcon: const Icon(Icons.calendar_today, size: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      'End Time',
                      endCtrl,
                      isReadOnly: true,
                      onTap: () => _selectDateTime(context, endCtrl),
                      suffixIcon: const Icon(Icons.calendar_today, size: 16),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(child: _buildDialogField(
                          'Start Time',
                          startCtrl,
                          isReadOnly: true,
                          onTap: () => _selectDateTime(context, startCtrl),
                          suffixIcon: const Icon(Icons.calendar_today, size: 16),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDialogField(
                          'End Time',
                          endCtrl,
                          isReadOnly: true,
                          onTap: () => _selectDateTime(context, endCtrl),
                          suffixIcon: const Icon(Icons.calendar_today, size: 16),
                        )),
                      ],
                    ),
                  const SizedBox(height: 12),
                  _buildDialogField('Water (m³)', waterCtrl),
                  const SizedBox(height: 12),
                  _BuyerInput(
                    initial: currentBuyer,
                    options: _buyerOptions,
                    decoration: _decoration.copyWith(labelText: 'Buyer'),
                    textStyle: _kInputText,
                    onChanged: (v) => currentBuyer = v,
                  ),
                  const SizedBox(height: 12),
                  if (isMobile) ...[
                    _buildDialogField('Weight IN', weightInCtrl, isNumber: true, onChanged: (v) {
                       _calculateNet(weightInCtrl.text, weightOutCtrl.text, netWeightCtrl);
                    }),
                    const SizedBox(height: 12),
                    _buildDialogField('Weight OUT', weightOutCtrl, isNumber: true, onChanged: (v) {
                       _calculateNet(weightInCtrl.text, weightOutCtrl.text, netWeightCtrl);
                    }),
                  ] else
                    Row(
                      children: [
                        Expanded(child: _buildDialogField('Weight IN', weightInCtrl, isNumber: true, onChanged: (v) {
                           _calculateNet(weightInCtrl.text, weightOutCtrl.text, netWeightCtrl);
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDialogField('Weight OUT', weightOutCtrl, isNumber: true, onChanged: (v) {
                           _calculateNet(weightInCtrl.text, weightOutCtrl.text, netWeightCtrl);
                        })),
                      ],
                    ),
                  const SizedBox(height: 12),
                  _buildDialogField('Net Weight', netWeightCtrl, isReadOnly: true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                // Save
                final newCistern = Cistern(
                  id: idCtrl.text,
                  tank: currentTank,
                  start: startCtrl.text,
                  end: endCtrl.text,
                  water: waterCtrl.text,
                  buyer: currentBuyer,
                  weightIn: weightInCtrl.text,
                  weightOut: weightOutCtrl.text,
                  netWeight: netWeightCtrl.text,
                );

                final list = List<Cistern>.from(widget.cisternsData);
                if (isEditing && index != null) {
                  list[index] = newCistern;
                } else {
                  list.add(newCistern);
                }
                _updateCisternList(list);
                
                if (currentBuyer.isNotEmpty) {
                  setState(() {
                    _buyerOptions.add(currentBuyer);
                  });
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _calculateNet(String wIn, String wOut, TextEditingController netCtrl) {
    final i = double.tryParse(wIn.replaceAll(' ', '').replaceAll(',', '.'));
    final o = double.tryParse(wOut.replaceAll(' ', '').replaceAll(',', '.'));
    if (i != null && o != null) {
      netCtrl.text = (i - o).toStringAsFixed(0);
    }
  }

  Future<void> _selectDateTime(BuildContext context, TextEditingController controller, {VoidCallback? onChanged}) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (controller.text.isNotEmpty) {
      try {
        final format = DateFormat('HH:mm');
        final dt = format.parse(controller.text);
        initialTime = TimeOfDay.fromDateTime(dt);
      } catch (_) {
        // Ignore parse errors, use now
      }
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0EA5E9),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      controller.text = DateFormat('HH:mm').format(dt);
      onChanged?.call();
    }
  }

  Widget _buildDialogField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    bool isReadOnly = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: isReadOnly,
      onTap: onTap,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      decoration: _decoration.copyWith(
        labelText: label,
        suffixIcon: suffixIcon,
      ),
      style: _kInputText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Filter rows based on selected tank, but we need the original index to update correctly
    final cisternCards = <Widget>[];
    for (int i = 0; i < widget.cisternsData.length; i++) {
      final c = widget.cisternsData[i];
      if (c.tank == _selectedTank) {
        cisternCards.add(_buildCisternCard(c, i));
      }
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _LabeledTable(
                      labelStyle: _kLabelText,
                      rows: [
                      LabeledRow(
                        label: 'Start offloading',
                        field: TextField(
                          controller: _startCtrl,
                          readOnly: true,
                          onTap: () => _selectDateTime(context, _startCtrl, onChanged: _updateOffloadingDuration),
                          decoration: _decoration.copyWith(
                            suffixIcon: const Icon(Icons.calendar_today, size: 16),
                          ),
                          style: _kInputText,
                        ),
                      ),
                      LabeledRow(
                        label: 'Stop offloading',
                        field: TextField(
                          controller: _stopCtrl,
                          readOnly: true,
                          onTap: () => _selectDateTime(context, _stopCtrl, onChanged: _updateOffloadingDuration),
                          decoration: _decoration.copyWith(
                            suffixIcon: const Icon(Icons.calendar_today, size: 16),
                          ),
                          style: _kInputText,
                        ),
                      ),
                      LabeledRow(
                        label: 'Hours of offloading (auto)',
                        field: TextField(
                          controller: _durationCtrl,
                          readOnly: true,
                          decoration: _decoration,
                          style: _kInputText,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _LabeledTable(
                          labelStyle: _kLabelText,
                          rows: [
                          LabeledRow(
                            label: 'RSW Tank',
                            field: DropdownButtonFormField<String>(
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
                          LabeledRow(
                            label: 'Tonnage tank (kg)',
                            field: TextField(
                              controller: _tonnageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _decoration,
                              style: _kInputText,
                              onChanged: _onTonnageChanged,
                            ),
                          ),
                          LabeledRow(
                            label: 'Capacity per cistern (kg)',
                            field: TextField(
                              controller: TextEditingController(text: _capacityPerCistern.toStringAsFixed(0)),
                              readOnly: true,
                              decoration: _decoration,
                              style: _kInputText,
                            ),
                          ),
                          LabeledRow(
                            label: 'Cisterns required (auto)',
                            field: TextField(
                              controller: TextEditingController(
                                  text: _requiredCisterns == 0 ? '' : _requiredCisterns.toString()),
                              readOnly: true,
                              decoration: _decoration,
                              style: _kInputText,
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

        // Helper to build the grid
        Widget buildGrid({bool scrollable = true}) {
          if (cisternCards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.blueGrey.shade200),
                  const SizedBox(height: 16),
                  Text('No cisterns added for $_selectedTank', style: GoogleFonts.lato(color: Colors.blueGrey)),
                ],
              ),
            );
          }
          return GridView.builder(
            shrinkWrap: !scrollable,
            physics: scrollable ? null : const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isNarrow ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 420,
            ),
            itemCount: cisternCards.length,
            itemBuilder: (context, index) => cisternCards[index],
          );
        }

        final fab = FloatingActionButton.extended(
          onPressed: () => _showCisternDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Cistern'),
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
        );

        return Container(
          color: const Color(0xFFF5F8FC),
          child: Stack(
            children: [
              Padding(
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
                                  'Manage cistern logistics for $_selectedTank',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isNarrow
                          ? SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  leftPanel,
                                  const SizedBox(height: 12),
                                  buildGrid(scrollable: false),
                                  const SizedBox(height: 80), // Space for FAB
                                ],
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                leftPanel,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 80),
                                        child: buildGrid(scrollable: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: fab,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCisternCard(Cistern c, int index) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: () {
        int filled = 0;
        if (c.start.isNotEmpty) filled++;
        if (c.end.isNotEmpty) filled++;
        if (c.water.isNotEmpty) filled++;
        if (c.buyer.isNotEmpty) filled++;
        if (c.weightIn.isNotEmpty) filled++;
        if (c.weightOut.isNotEmpty) filled++;
        if (c.netWeight.isNotEmpty) filled++;

        if (filled == 0) return Colors.red.shade50;
        if (filled == 7) return Colors.white;
        return Colors.amber.shade50;
      }(),
      child: InkWell(
        onTap: () => _showCisternDialog(cistern: c, index: index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon, ID, Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF0EA5E9).withOpacity(0.15), const Color(0xFF0EA5E9).withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF0EA5E9), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.id.isEmpty ? 'Unknown ID' : c.id,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (c.tripId.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Trip: ${c.tripId}',
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  color: Colors.blueGrey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.copy_rounded,
                        color: Colors.blueGrey.shade400,
                        onPressed: () {
                          final list = List<Cistern>.from(widget.cisternsData);
                          list.insert(index + 1, c.copyWith(id: '${c.id}-copy'));
                          _updateCisternList(list);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent.shade200,
                        onPressed: () {
                          final list = List<Cistern>.from(widget.cisternsData);
                          list.removeAt(index);
                          _updateCisternList(list);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Buyer Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business_rounded, size: 18, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 10),
                    Text(
                      'Buyer: ',
                      style: GoogleFonts.lato(fontSize: 13, color: Colors.blueGrey.shade600),
                    ),
                    Expanded(
                      child: Text(
                        c.buyer.isEmpty ? 'Not specified' : c.buyer,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Data Grid
              Row(
                children: [
                  Expanded(child: _DataCell(label: 'Start Time', value: c.start, icon: Icons.schedule_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _DataCell(label: 'End Time', value: c.end, icon: Icons.update_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _DataCell(label: 'Weight IN', value: '${c.weightIn} kg', icon: Icons.download_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _DataCell(label: 'Weight OUT', value: '${c.weightOut} kg', icon: Icons.upload_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _DataCell(label: 'Water', value: '${c.water} m³', icon: Icons.water_drop_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF0EA5E9).withOpacity(0.1), const Color(0xFF0EA5E9).withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.scale_rounded, size: 14, color: Color(0xFF0EA5E9)),
                              const SizedBox(width: 6),
                              Text(
                                'NET WEIGHT',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0EA5E9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${c.netWeight} kg',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _LabeledTable extends StatelessWidget {
  final List<LabeledRow> rows;
  final TextStyle? labelStyle;
  
  const _LabeledTable({required this.rows, this.labelStyle});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows
          .map((r) => TableRow(children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                  child: Text(r.label, style: labelStyle ?? const TextStyle(fontSize: 12)),
                ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: r.field),
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
  final InputDecoration decoration;
  final TextStyle textStyle;
  final ValueChanged<String> onChanged;

  const _BuyerInput({
    required this.initial,
    required this.options,
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
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.done,
          decoration: widget.decoration,
          style: widget.textStyle,
          onEditingComplete: _commitIfValid,
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
                    title: Text(opt, style: GoogleFonts.lato(fontSize: 13)),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DataCell({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.blueGrey.shade300),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lato(fontSize: 11, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
