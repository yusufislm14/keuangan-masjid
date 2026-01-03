import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _transactionsKey = 'masjid_transactions';

  // Simpan transaksi
  static Future<void> saveTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getTransactions();
    transactions.add(transaction);
    
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(transactionsJson));
  }

  // Ambil semua transaksi
  static Future<List<Transaction>> getTransactions() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = prefs.getString(_transactionsKey);
    
    if (transactionsString == null) {
      return [];
    }
    
    final List<dynamic> transactionsJson = jsonDecode(transactionsString);
    return transactionsJson
        .map((json) => Transaction.fromJson(json))
        .toList();
    } catch (e) {
      // Return empty list if there's an error parsing
      return [];
    }
  }

  // Hapus transaksi
  static Future<void> deleteTransaction(String transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == transactionId);
    
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(transactionsJson));
  }

  // Update transaksi
  static Future<void> updateTransaction(Transaction updatedTransaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getTransactions();
    
    final index = transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      transactions[index] = updatedTransaction;
      
      final transactionsJson = transactions.map((t) => t.toJson()).toList();
      await prefs.setString(_transactionsKey, jsonEncode(transactionsJson));
    }
  }

  // Hitung saldo total
  static Future<double> getTotalBalance() async {
    final transactions = await getTransactions();
    double balance = 0.0;
    
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }
    
    return balance;
  }

  // Hitung total uang masuk
  static Future<double> getTotalIncome() async {
    final transactions = await getTransactions();
    double total = 0.0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        total += transaction.amount;
      }
    }
    return total;
  }

  // Hitung total uang keluar
  static Future<double> getTotalExpense() async {
    final transactions = await getTransactions();
    double total = 0.0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        total += transaction.amount;
      }
    }
    return total;
  }

  // Ambil transaksi berdasarkan bulan
  static Future<List<Transaction>> getTransactionsByMonth(DateTime month) async {
    final transactions = await getTransactions();
    return transactions.where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  // Hitung saldo sebelum bulan tertentu
  static Future<double> getBalanceBeforeMonth(DateTime month) async {
    final transactions = await getTransactions();
    double balance = 0.0;
    
    for (final transaction in transactions) {
      // Hitung transaksi sebelum bulan yang dipilih
      if (transaction.date.isBefore(DateTime(month.year, month.month, 1))) {
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else {
          balance -= transaction.amount;
        }
      }
    }
    
    return balance;
  }

  // Ambil transaksi berdasarkan rentang tanggal
  static Future<List<Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    final transactions = await getTransactions();
    // Normalisasi tanggal (hilangkan jam, menit, detik)
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    return transactions.where((t) {
      final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
      // Transaksi harus >= startDate dan <= endDate (inklusif)
      return transactionDate.isAfter(start.subtract(const Duration(days: 1))) && 
             transactionDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Hitung saldo sebelum tanggal tertentu
  static Future<double> getBalanceBeforeDate(DateTime date) async {
    final transactions = await getTransactions();
    double balance = 0.0;
    
    final targetDate = DateTime(date.year, date.month, date.day);
    
    for (final transaction in transactions) {
      final transactionDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      // Hitung transaksi sebelum tanggal yang dipilih
      if (transactionDate.isBefore(targetDate)) {
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else {
          balance -= transaction.amount;
        }
      }
    }
    
    return balance;
  }

  // Ambil transaksi berdasarkan rentang bulan
  static Future<List<Transaction>> getTransactionsByMonthRange(DateTime startMonth, DateTime endMonth) async {
    final transactions = await getTransactions();
    final start = DateTime(startMonth.year, startMonth.month, 1);
    final end = DateTime(endMonth.year, endMonth.month + 1, 0); // Hari terakhir dari bulan akhir
    
    return transactions.where((t) {
      final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
      // Transaksi harus >= start dan <= end (inklusif)
      return transactionDate.isAfter(start.subtract(const Duration(days: 1))) && 
             transactionDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Hitung saldo sebelum bulan tertentu
  static Future<double> getBalanceBeforeMonthRange(DateTime startMonth) async {
    final transactions = await getTransactions();
    double balance = 0.0;
    
    final start = DateTime(startMonth.year, startMonth.month, 1);
    
    for (final transaction in transactions) {
      final transactionDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      // Hitung transaksi sebelum bulan yang dipilih
      if (transactionDate.isBefore(start)) {
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else {
          balance -= transaction.amount;
        }
      }
    }
    
    return balance;
  }

  // Ambil transaksi berdasarkan kategori
  static Future<List<Transaction>> getTransactionsByCategory(String category) async {
    final transactions = await getTransactions();
    return transactions.where((t) => t.category == category).toList();
  }

  // Hapus semua data (untuk reset)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
  }

  // Ganti seluruh transaksi (digunakan saat impor data)
  static Future<void> replaceTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(transactionsJson));
  }
}
