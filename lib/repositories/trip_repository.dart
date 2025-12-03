import '../models/trip.dart';
import '../services/local_db.dart';
import 'package:sqflite/sqflite.dart';

/// Repository pour la table TRIPS
/// Sert à insérer, lire et gérer les voyages dans la base locale.
class TripRepository {
  /// Insérer ou mettre à jour un trip
  Future<void> insertTrip(Trip trip) async {
    final db = await LocalDb.database;
    await db.insert(
      'trips',
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupérer tous les trips stockés
  Future<List<Trip>> getAllTrips() async {
    final db = await LocalDb.database;
    final maps = await db.query('trips', orderBy: 'tripDate DESC');
    return maps.map((e) => Trip.fromMap(e)).toList();
  }

  /// Supprimer un trip par ID
  Future<void> deleteTrip(String id) async {
    final db = await LocalDb.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  /// Vider complètement la table
  Future<void> clearTrips() async {
    final db = await LocalDb.database;
    await db.delete('trips');
  }
}
