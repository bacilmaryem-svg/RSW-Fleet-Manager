import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../repositories/trip_repository.dart';
import 'package:uuid/uuid.dart';

/// Provider principal pour gérer les voyages (Trips)
class TripProvider extends ChangeNotifier {
  final TripRepository _repo = TripRepository();
  List<Trip> trips = [];

  /// Charger tous les trips depuis la base locale
  Future<void> loadTrips() async {
    trips = await _repo.getAllTrips();
    notifyListeners();
  }

  /// Ajouter un nouveau voyage
  Future<void> addTrip(String vessel) async {
    final id = const Uuid().v4();
    final trip = Trip(
      id: id,
      tripCode: DateTime.now().toIso8601String(),
      tripDate: DateTime.now().toString().split(' ').first,
      vessel: vessel,
    );
    await _repo.insertTrip(trip);
    trips.add(trip);
    notifyListeners();
  }

  /// Supprimer un trip
  Future<void> deleteTrip(String id) async {
    await _repo.deleteTrip(id);
    trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
