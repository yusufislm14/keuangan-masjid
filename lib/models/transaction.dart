import 'package:uuid/uuid.dart';

enum TransactionType {
  income, // Uang masuk
  expense, // Uang keluar
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String? notes;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.notes,
  });

  // Factory constructor untuk membuat transaksi baru
  factory Transaction.create({
    required TransactionType type,
    required double amount,
    required String description,
    required String category,
    DateTime? date,
    String? notes,
  }) {
    return Transaction(
      id: const Uuid().v4(),
      type: type,
      amount: amount,
      description: description,
      category: category,
      date: date ?? DateTime.now(),
      notes: notes,
    );
  }

  // Convert to JSON untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  // Factory constructor dari JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
    return Transaction(
        id: json['id'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.income,
      ),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] ?? '',
        category: json['category'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
    );
    } catch (e) {
      // Return a default transaction if parsing fails
      return Transaction(
        id: '',
        type: TransactionType.income,
        amount: 0.0,
        description: 'Error loading transaction',
        category: 'Error',
        date: DateTime.now(),
        notes: 'Failed to parse transaction data',
      );
    }
  }

  // Copy with method untuk update
  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}

// Kategori untuk uang masuk
class IncomeCategory {
  static const List<String> categories = [
    'Infaq',
    'Sedekah',
    'Zakat',
    'Wakaf',
    'Donasi Umum',
    'Kotak Amal',
    'Kegiatan Masjid',
    'Lainnya',
  ];
}

// Kategori untuk uang keluar
class ExpenseCategory {
  static const List<String> categories = [
    'Listrik',
    'Air',
    'Pemeliharaan',
    'Renovasi',
    'Kegiatan',
    'Operasional',
    'Gaji/Upah',
    'Bahan Makanan',
    'Transportasi',
    'Lainnya',
  ];
}
