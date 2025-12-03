import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Service de base de données locale SQLite
/// Il gère la création et la connexion à la base.
/// Les tables créées :
///   - trips : informations sur chaque voyage
///   - cisterns : citernes associées à un voyage
class LocalDb {
  static Database? _db;

  /// Getter principal : retourne une instance ouverte de la BDD
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  /// Initialisation : ouverture ou création du fichier .db
  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rsw_fleet.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Création des tables lors du premier lancement
  static Future _onCreate(Database db, int version) async {
    // Table des voyages
    await db.execute('''
      CREATE TABLE trips(
        id TEXT PRIMARY KEY,
        tripCode TEXT,
        tripDate TEXT,
        vessel TEXT
      )
    ''');

    // Table des citernes
    await db.execute('''
      CREATE TABLE cisterns(
        id TEXT PRIMARY KEY,
        tank TEXT,
        start TEXT,
        end TEXT,
        water TEXT,
        buyer TEXT,
        weightIn TEXT,
        weightOut TEXT,
        netWeight TEXT,
        tripId TEXT
      )
    ''');
  }

  /// Supprimer complètement la base (utile pour tests)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('trips');
    await db.delete('cisterns');
  }

  /// Fermer proprement la base (facultatif)
  static Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
