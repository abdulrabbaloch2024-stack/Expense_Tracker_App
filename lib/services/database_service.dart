import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense_transaction.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;

    final dir = await getDatabasesPath();
    final dbPath = join(dir, 'expense_tracker.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  // Add transaction
  Future<int> add(ExpenseTransaction transaction) async {
    final database = await db;

    return await database.insert(
      'transactions',
      transaction.toMap()..remove('id'),
    );
  }

  // Get all transactions
  Future<List<ExpenseTransaction>> all() async {
    final database = await db;

    final rows = await database.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );

    return rows.map((row) => ExpenseTransaction.fromMap(row)).toList();
  }

  // Update transaction
  Future<int> edit(ExpenseTransaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction ID is required for update.');
    }

    final database = await db;
    final data = transaction.toMap()..remove('id');

    return await database.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete transaction
  Future<int> remove(int id) async {
    final database = await db;

    return await database.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
