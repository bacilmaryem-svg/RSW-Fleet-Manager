import 'package:flutter/foundation.dart';
import '../models/cistern.dart';
import '../repositories/cistern_repository.dart';
import 'package:uuid/uuid.dart';

/// Provider pour la gestion des citernes (Cisterns)
class CisternProvider extends ChangeNotifier {
  final CisternRepository _repo = CisternRepository();
  List<Cistern> cisterns = [];

  /// Charger toutes les citernes pour un trip
  Future<void> loadForTrip(String tripId) async {
    cisterns = await _repo.getCisternsByTrip(tripId);
    notifyListeners();
  }

  /// Ajouter une nouvelle citerne liée à un trip
  Future<void> addCistern(String tripId, String tank) async {
    final id = const Uuid().v4();
    final c = Cistern(
      id: id,
      tank: tank,
      start: '',
      end: '',
      water: '',
      buyer: '',
      weightIn: '',
      weightOut: '',
      netWeight: '',
      tripId: tripId,
    );
    await _repo.insertCistern(c);
    cisterns.add(c);
    notifyListeners();
  }

  /// Calcul du tonnage total net
  double totalNetWeight() {
    return cisterns.fold(0.0, (sum, c) {
      final inVal = double.tryParse(c.weightIn) ?? 0;
      final outVal = double.tryParse(c.weightOut) ?? 0;
      return sum + (inVal - outVal);
    });
  }

  /// Suppression d'une citerne spécifique
  Future<void> deleteCistern(String id) async {
    await _repo.deleteCistern(id);
    cisterns.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
