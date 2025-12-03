import '../models/cistern.dart';
import '../services/local_db.dart';
import 'package:sqflite/sqflite.dart';

/// Repository pour la table CISTERNS
/// Sert à insérer, lire et gérer les citernes associées à chaque trip.
class CisternRepository {
  /// Insérer ou mettre à jour une citerne
  Future<void> insertCistern(Cistern c) async {
    final db = await LocalDb.database;
    await db.insert(
      'cisterns',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupérer toutes les citernes d’un trip donné
  Future<List<Cistern>> getCisternsByTrip(String tripId) async {
    final db = await LocalDb.database;
    final maps = await db.query(
      'cisterns',
      where: 'tripId = ?',
      whereArgs: [tripId],
    );
    return maps.map((e) => Cistern.fromMap(e)).toList();
  }

  /// Supprimer une citerne spécifique
  Future<void> deleteCistern(String id) async {
    final db = await LocalDb.database;
    await db.delete('cisterns', where: 'id = ?', whereArgs: [id]);
  }

  /// Supprimer toutes les citernes (utile pour reset)
  Future<void> clearCisterns() async {
    final db = await LocalDb.database;
    await db.delete('cisterns');
  }
}
