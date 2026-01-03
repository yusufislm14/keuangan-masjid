import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/storage_service.dart';
import '../services/masjid_service.dart';
import '../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  TabController? _tabController;
  
  // Tanggal state - laporan bulanan
  DateTime _selectedMonth = DateTime.now();
  List<Transaction> _monthlyTransactions = [];
  
  // Mutasi state - filter berdasarkan rentang tanggal
  DateTime? _startDate;
  DateTime? _endDate;
  List<Transaction> _mutasiTransactions = [];
  
  // Nama masjid
  String _masjidName = 'KAS MASJID';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      setState(() {}); // Update UI when tab changes
    });
    // Load monthly data saja, mutasi tidak langsung dimuat
    _loadMasjidName();
    _loadMonthlyData();
  }
  
  Future<void> _loadMasjidName() async {
    final name = await MasjidService.getMasjidName();
    if (mounted) {
      setState(() {
        _masjidName = name;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh nama masjid ketika screen muncul kembali
    _loadMasjidName();
  }

  List<pw.TableRow> _buildLedgerRows(List<Transaction> transactions, double initialBalance) {
    final List<pw.TableRow> rows = [];
    double runningBalance = initialBalance;
    int rowNumber = 1;

    // Add initial balance row (Saldo buku awal)
    rows.add(
      pw.TableRow(
        children: [
          // NO - empty for initial balance
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Center(
              child: pw.Text(
                '',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
          // TGL - empty
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Center(
              child: pw.Text(
                '',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
          // URAIAN
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              'Saldo buku awal',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          // MASUK - empty
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Center(
              child: pw.Text(
                '',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
          // KELUAR - empty
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Center(
              child: pw.Text(
                '',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
          // SALDO - initial balance
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                NumberFormat('#,###').format(runningBalance).replaceAll(',', '.'),
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ),
          // KETERANGAN - empty
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              '',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );

    // Sort transactions by date (oldest first - kronologis)
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final transaction in sortedTransactions) {
      // Calculate running balance
      if (transaction.type == TransactionType.income) {
        runningBalance += transaction.amount;
      } else {
        runningBalance -= transaction.amount;
      }


      rows.add(
        pw.TableRow(
          children: [
            // NO
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Center(
                child: pw.Text(
                  rowNumber.toString(),
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            // TGL
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Center(
                child: pw.Text(
                  DateFormat('dd/MM/yy').format(transaction.date),
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            // URAIAN
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                transaction.description,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            // MASUK
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  transaction.type == TransactionType.income 
                    ? NumberFormat('#,###').format(transaction.amount).replaceAll(',', '.')
                    : '',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ),
            // KELUAR
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  transaction.type == TransactionType.expense 
                    ? NumberFormat('#,###').format(transaction.amount).replaceAll(',', '.')
                    : '',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ),
            // SALDO
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  NumberFormat('#,###').format(runningBalance).replaceAll(',', '.'),
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ),
            // KETERANGAN
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                transaction.notes ?? transaction.category,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
        ),
      );
      
      rowNumber++;
    }

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (final transaction in sortedTransactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    // Add TOTAL row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Center(
              child: pw.Text(
                '',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Center(
            child: pw.Text(
              '',
              style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
              'TOTAL',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                NumberFormat('#,###').format(totalIncome).replaceAll(',', '.'),
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                NumberFormat('#,###').format(totalExpense).replaceAll(',', '.'),
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                NumberFormat('#,###').format(runningBalance).replaceAll(',', '.'),
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              '',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );

    return rows;
  }


  Future<void> _selectDateRange() async {
    if (!mounted) return;
    
    final DateTime? start = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Mulai',
    );
    
    if (start != null && mounted) {
      final DateTime? end = await showDatePicker(
        context: context,
        initialDate: _endDate ?? start,
        firstDate: start,
        lastDate: DateTime.now(),
        helpText: 'Pilih Tanggal Akhir',
      );
      
      if (end != null) {
        if (end.isBefore(start)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tanggal akhir harus setelah tanggal mulai'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        if (mounted) {
          setState(() {
            _isLoading = true;
            _startDate = start;
            _endDate = end;
          });
          
          await _loadMutasiData();
        }
      }
    }
  }

  Future<void> _loadMonthlyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await StorageService.getTransactionsByMonth(_selectedMonth);

      setState(() {
        _monthlyTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _selectMonth() async {
    if (!mounted) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _isLoading = true;
      });
      await _loadMonthlyData();
    }
  }

  Future<void> _loadMutasiData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_startDate == null || _endDate == null) {
        setState(() {
          _mutasiTransactions = [];
          _isLoading = false;
        });
        return;
      }
      
      // Pastikan tanggal mulai <= tanggal akhir
      final start = _startDate!;
      final end = _endDate!;
      
      if (end.isBefore(start)) {
        setState(() {
          _mutasiTransactions = [];
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tanggal akhir harus setelah tanggal mulai'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final transactions = await StorageService.getTransactionsByDateRange(start, end);
      
      // Sort transactions by date (oldest first)
      transactions.sort((a, b) => a.date.compareTo(b.date));
      
      if (mounted) {
        setState(() {
          _mutasiTransactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mutasiTransactions = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFilterDialog(Function(List<Transaction> transactions, double initialBalance, String periodName) onFilterSelected) async {
    if (!mounted) return;
    
    String? filterType; // 'date' or 'month'
    DateTime? startDate;
    DateTime? endDate;
    DateTime? startMonth;
    DateTime? endMonth;
    
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Laporan'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih jenis filter:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text('Rentang Tanggal'),
                  subtitle: const Text('Tgl berapa - Tgl berapa'),
                  value: 'date',
                  groupValue: filterType,
                  onChanged: (value) {
                    setDialogState(() {
                      filterType = value;
                      startDate = null;
                      endDate = null;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Rentang Bulan'),
                  subtitle: const Text('Bulan berapa - Bulan berapa'),
                  value: 'month',
                  groupValue: filterType,
                  onChanged: (value) {
                    setDialogState(() {
                      filterType = value;
                      startMonth = null;
                      endMonth = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Rentang Tanggal
                if (filterType == 'date') ...[
                  const Text(
                    'Pilih Tanggal Mulai:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      startDate != null
                          ? DateFormat('dd MMM yyyy').format(startDate!)
                          : 'Pilih Tanggal Mulai',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Tanggal Akhir:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      endDate != null
                          ? DateFormat('dd MMM yyyy').format(endDate!)
                          : 'Pilih Tanggal Akhir',
                    ),
                  ),
                ],
                
                // Rentang Bulan
                if (filterType == 'month') ...[
                  const Text(
                    'Pilih Bulan Mulai:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startMonth ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        helpText: 'Pilih Bulan Mulai',
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startMonth = DateTime(picked.year, picked.month);
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      startMonth != null
                          ? DateFormat('MMMM yyyy').format(startMonth!)
                          : 'Pilih Bulan Mulai',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Bulan Akhir:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endMonth ?? startMonth ?? DateTime.now(),
                        firstDate: startMonth ?? DateTime(2020),
                        lastDate: DateTime.now(),
                        helpText: 'Pilih Bulan Akhir',
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endMonth = DateTime(picked.year, picked.month);
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      endMonth != null
                          ? DateFormat('MMMM yyyy').format(endMonth!)
                          : 'Pilih Bulan Akhir',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final dialogContext = context;
                if (filterType == 'date' && startDate != null && endDate != null) {
                  if (endDate!.isBefore(startDate!)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Tanggal akhir harus setelah tanggal mulai'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop({
                    'type': 'date',
                    'startDate': startDate,
                    'endDate': endDate,
                  });
                } else if (filterType == 'month' && startMonth != null && endMonth != null) {
                  if (endMonth!.isBefore(startMonth!)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Bulan akhir harus setelah bulan mulai'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop({
                    'type': 'month',
                    'startMonth': startMonth,
                    'endMonth': endMonth,
                  });
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan lengkapi filter terlebih dahulu'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
    
    if (result == null || !mounted) return;
    
    List<Transaction> transactionsToReport;
    double initialBalance;
    String periodName;
    
    if (result['type'] == 'date') {
      final start = result['startDate'] as DateTime;
      final end = result['endDate'] as DateTime;
      transactionsToReport = await StorageService.getTransactionsByDateRange(start, end);
      transactionsToReport.sort((a, b) => a.date.compareTo(b.date));
      initialBalance = await StorageService.getBalanceBeforeDate(start);
      periodName = '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    } else if (result['type'] == 'month') {
      final start = result['startMonth'] as DateTime;
      final end = result['endMonth'] as DateTime;
      transactionsToReport = await StorageService.getTransactionsByMonthRange(start, end);
      transactionsToReport.sort((a, b) => a.date.compareTo(b.date));
      initialBalance = await StorageService.getBalanceBeforeMonthRange(start);
      periodName = '${DateFormat('MMMM yyyy').format(start)} - ${DateFormat('MMMM yyyy').format(end)}';
    } else {
      return;
    }
    
    onFilterSelected(transactionsToReport, initialBalance, periodName);
  }

  Future<DateTime?> _pickLetterDate() async {
    if (!mounted) return null;

    final DateTime initialDate = DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tgl Surat',
      confirmText: 'Simpan',
      cancelText: 'Batal',
    );

    if (!mounted) return null;
    return selectedDate;
  }

  Future<void> _downloadMonthlyReport() async {
    await _showFilterDialog((transactionsToReport, initialBalance, periodName) async {
      final DateTime? letterDate = await _pickLetterDate();
      if (!mounted || letterDate == null) {
        return;
      }

      try {
      
      // Generate PDF
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LAPORAN KEUANGAN',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _masjidName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'PERIODE: ${periodName.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // "Dalam mata uang Rupiah (Rp)" di atas tabel (rata kanan)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Dalam mata uang Rupiah (Rp)',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(height: 10),

            // Ledger Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),  // NO
                1: const pw.FixedColumnWidth(50),  // TGL
                2: const pw.FlexColumnWidth(3),     // URAIAN
                3: const pw.FixedColumnWidth(55),   // MASUK
                4: const pw.FixedColumnWidth(55),   // KELUAR
                5: const pw.FixedColumnWidth(55),   // SALDO
                6: const pw.FlexColumnWidth(2),     // KETERANGAN
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'NO',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'TGL',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'URAIAN',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'MASUK',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'KELUAR',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'SALDO',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'KETERANGAN',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Data Rows
                ..._buildLedgerRows(transactionsToReport, initialBalance),
              ],
            ),

            pw.SizedBox(height: 10),
            // Tanggal Cetak di bawah tabel
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Tanggal Cetak: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Mataram, ${DateFormat('dd MMMM yyyy').format(letterDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Ketua Pengurus Masjid',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                '( H Tukiran )',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );
      
      // Show PDF preview and allow share/print
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Masjid_Al-Anwar_$periodName.pdf',
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    });
  }

  Future<void> _printMonthlyReport() async {
    await _showFilterDialog((transactionsToReport, initialBalance, periodName) async {
    final DateTime? letterDate = await _pickLetterDate();
    if (!mounted || letterDate == null) {
      return;
    }

    try {
      
      // Generate PDF (same as download method)
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LAPORAN KEUANGAN',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _masjidName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'PERIODE: ${periodName.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // "Dalam mata uang Rupiah (Rp)" di atas tabel (rata kanan)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Dalam mata uang Rupiah (Rp)',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(height: 10),

            // Ledger Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),  // NO
                1: const pw.FixedColumnWidth(50),  // TGL
                2: const pw.FlexColumnWidth(3),     // URAIAN
                3: const pw.FixedColumnWidth(55),   // MASUK
                4: const pw.FixedColumnWidth(55),   // KELUAR
                5: const pw.FixedColumnWidth(55),   // SALDO
                6: const pw.FlexColumnWidth(2),     // KETERANGAN
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'NO',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'TGL',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'URAIAN',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                              'MASUK',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                              'KELUAR',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'SALDO',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Center(
                        child: pw.Text(
                          'KETERANGAN',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Data Rows
                ..._buildLedgerRows(transactionsToReport, initialBalance),
              ],
            ),

            pw.SizedBox(height: 10),
            // Tanggal Cetak di bawah tabel
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Tanggal Cetak: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Mataram, ${DateFormat('dd MMMM yyyy').format(letterDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Ketua Pengurus Masjid',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                '( H Tukiran )',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );
      
      // Print directly to printer
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Masjid_Al-Anwar_$periodName.pdf',
        usePrinterSettings: true, // Use printer settings
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat mencetak: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    });
  }

  Future<void> _exportToExcel() async {
    await _showFilterDialog((transactionsToReport, initialBalance, periodName) async {
    // Show loading dialog
      if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Mengexport ke Excel...'),
          ],
        ),
      ),
    );

    try {
      
      // PASTIKAN 1: Create Excel file dalam format .xlsx (Excel 2007+)
      // Excel.createExcel() secara default menghasilkan format Office Open XML (.xlsx)
      // Format ini kompatibel dengan Excel 2007, 2010, 2013, 2016, 2019, 365, dan aplikasi Excel lainnya
      var excel = Excel.createExcel();
      
      // Delete default sheet and create new one
      excel.delete('Sheet1');
      Sheet sheetObject = excel['Laporan Keuangan'];
      
      // Set column widths
      sheetObject.setColumnWidth(0, 8);   // NO
      sheetObject.setColumnWidth(1, 12);  // TGL
      sheetObject.setColumnWidth(2, 30);  // URAIAN
      sheetObject.setColumnWidth(3, 15);  // MASUK
      sheetObject.setColumnWidth(4, 15);  // KELUAR
      sheetObject.setColumnWidth(5, 15);  // SALDO
      sheetObject.setColumnWidth(6, 20);  // KETERANGAN
      
      // Header informasi (baris 1-4)
      sheetObject.cell(CellIndex.indexByString('A1')).value = TextCellValue('LAPORAN KEUANGAN');
      sheetObject.cell(CellIndex.indexByString('A2')).value = TextCellValue(_masjidName);
      sheetObject.cell(CellIndex.indexByString('A3')).value = TextCellValue('PERIODE: ${periodName.toUpperCase()}');
      sheetObject.cell(CellIndex.indexByString('A4')).value = TextCellValue('Tanggal Export: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}');
      
      // "Dalam mata uang Rupiah (Rp)" di atas kolom KETERANGAN (rata kanan)
      final currencyCell = sheetObject.cell(CellIndex.indexByString('G5'));
      currencyCell.value = TextCellValue('Dalam mata uang Rupiah (Rp)');
      currencyCell.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
      );
      
      // PASTIKAN 3: Table headers - Header "NO" dan "TGL" di baris pertama data (baris 6)
      // Struktur file Excel:
      // - Baris 1-4: Header informasi (LAPORAN KEUANGAN, KAS MASJID, dll)
      // - Baris 5: "Dalam mata uang Rupiah (Rp)"
      // - Baris 6: Header tabel data (NO, TGL, URAIAN, MASUK, KELUAR, SALDO, KETERANGAN) <- BARIS PERTAMA DATA
      // - Baris 7+: Data transaksi
      // Header "NO" dan "TGL" HARUS ada di baris 6 agar file dapat diimport kembali
      // PASTIKAN: Gunakan TextCellValue untuk memastikan nilai tersimpan sebagai teks yang dapat dibaca
      final noCell = sheetObject.cell(CellIndex.indexByString('A6'));
      noCell.value = TextCellValue('NO');
      
      final tglCell = sheetObject.cell(CellIndex.indexByString('B6'));
      tglCell.value = TextCellValue('TGL');
      
      sheetObject.cell(CellIndex.indexByString('C6')).value = TextCellValue('URAIAN');
      sheetObject.cell(CellIndex.indexByString('D6')).value = TextCellValue('MASUK');
      sheetObject.cell(CellIndex.indexByString('E6')).value = TextCellValue('KELUAR');
      sheetObject.cell(CellIndex.indexByString('F6')).value = TextCellValue('SALDO');
      sheetObject.cell(CellIndex.indexByString('G6')).value = TextCellValue('KETERANGAN');
      
      // Style headers
      for (int i = 0; i < 7; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5)).cellStyle = CellStyle(
          bold: true,
        );
      }
      
      // Data rows
      double runningBalance = initialBalance;
      int rowNumber = 7; // Start from row 7
      
      // Add initial balance row
      sheetObject.cell(CellIndex.indexByString('C$rowNumber')).value = TextCellValue('Saldo buku awal');
      final initialBalanceCell = sheetObject.cell(CellIndex.indexByString('F$rowNumber'));
      initialBalanceCell.value = DoubleCellValue(runningBalance);
      initialBalanceCell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
      rowNumber++;
      
      // Sort transactions by date (oldest first - kronologis)
      final sortedTransactions = List<Transaction>.from(transactionsToReport)
        ..sort((a, b) => a.date.compareTo(b.date));
      
      // Check if there are transactions
      if (sortedTransactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada transaksi untuk diexport'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      int transactionNumber = 1;
      for (final transaction in sortedTransactions) {
        // Calculate running balance
        if (transaction.type == TransactionType.income) {
          runningBalance += transaction.amount;
        } else {
          runningBalance -= transaction.amount;
        }
        
        sheetObject.cell(CellIndex.indexByString('A$rowNumber')).value = IntCellValue(transactionNumber);
        sheetObject.cell(CellIndex.indexByString('B$rowNumber')).value = TextCellValue(DateFormat('dd/MM/yy').format(transaction.date));
        sheetObject.cell(CellIndex.indexByString('C$rowNumber')).value = TextCellValue(transaction.description);
        
        if (transaction.type == TransactionType.income) {
          final cell = sheetObject.cell(CellIndex.indexByString('D$rowNumber'));
          cell.value = DoubleCellValue(transaction.amount);
          cell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
        } else {
          final cell = sheetObject.cell(CellIndex.indexByString('E$rowNumber'));
          cell.value = DoubleCellValue(transaction.amount);
          cell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
        }
        
        final saldoCell = sheetObject.cell(CellIndex.indexByString('F$rowNumber'));
        saldoCell.value = DoubleCellValue(runningBalance);
        saldoCell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
        sheetObject.cell(CellIndex.indexByString('G$rowNumber')).value = TextCellValue(transaction.notes ?? transaction.category);
        
        transactionNumber++;
        rowNumber++;
      }
      
      // Add TOTAL row
      double totalIncome = 0;
      double totalExpense = 0;
      for (final transaction in sortedTransactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }
      
      // TOTAL di kolom URAIAN (C), bukan di kolom NO (A)
      sheetObject.cell(CellIndex.indexByString('C$rowNumber')).value = TextCellValue('TOTAL');
      final totalIncomeCell = sheetObject.cell(CellIndex.indexByString('D$rowNumber'));
      totalIncomeCell.value = DoubleCellValue(totalIncome);
      totalIncomeCell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      final totalExpenseCell = sheetObject.cell(CellIndex.indexByString('E$rowNumber'));
      totalExpenseCell.value = DoubleCellValue(totalExpense);
      totalExpenseCell.cellStyle = CellStyle(
          bold: true,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      final totalBalanceCell = sheetObject.cell(CellIndex.indexByString('F$rowNumber'));
      totalBalanceCell.value = DoubleCellValue(runningBalance);
      totalBalanceCell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      // Style TOTAL row (kolom lainnya)
      final totalRowCell1 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowNumber - 1));
      totalRowCell1.cellStyle = CellStyle(bold: true);
      final totalRowCell2 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowNumber - 1));
      totalRowCell2.cellStyle = CellStyle(bold: true);
      final totalRowCell3 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowNumber - 1));
      totalRowCell3.cellStyle = CellStyle(bold: true);
      final totalRowCell7 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowNumber - 1));
      totalRowCell7.cellStyle = CellStyle(bold: true);
      
      // Footer
      rowNumber += 2;
      sheetObject.cell(CellIndex.indexByString('A$rowNumber')).value = TextCellValue('Mataram,');
      rowNumber += 2;
      sheetObject.cell(CellIndex.indexByString('A$rowNumber')).value = TextCellValue('Ketua Pengurus Masjid');
      rowNumber += 3;
      sheetObject.cell(CellIndex.indexByString('A$rowNumber')).value = TextCellValue('(___________________)');
      
      // Save file menggunakan FilePicker untuk memilih lokasi penyimpanan
      // Pastikan format selalu .xlsx (Excel 2007+)
      String baseFileName = 'Laporan_Kas_Masjid_$periodName';
      // Hapus ekstensi jika ada, lalu tambahkan .xlsx
      final lowerBaseName = baseFileName.toLowerCase();
      if (lowerBaseName.endsWith('.xlsx')) {
        baseFileName = baseFileName.substring(0, baseFileName.length - 5);
      } else if (lowerBaseName.endsWith('.xls')) {
        baseFileName = baseFileName.substring(0, baseFileName.length - 4);
      }
      final String fileName = '$baseFileName.xlsx';
      
      // Encode Excel ke format .xlsx (Excel 2007+)
      // PASTIKAN: Excel.createExcel() menghasilkan format .xlsx yang kompatibel dengan Excel
      final List<int>? encodedBytes = excel.encode();

      if (encodedBytes == null || encodedBytes.isEmpty) {
        throw Exception('Gagal mengencode file Excel ke format .xlsx');
      }

      // Validasi bahwa encoded bytes tidak kosong dan valid
      if (encodedBytes.length < 100) {
        throw Exception('File Excel yang dihasilkan terlalu kecil atau tidak valid');
      }

      // Validasi signature ZIP (file .xlsx adalah ZIP archive)
      // Bytes pertama harus 0x50 0x4B (PK - ZIP signature)
      if (encodedBytes.length < 4 || encodedBytes[0] != 0x50 || encodedBytes[1] != 0x4B) {
        throw Exception('File Excel yang dihasilkan tidak valid. Format file tidak sesuai standar .xlsx');
      }

      final Uint8List excelBytes = Uint8List.fromList(encodedBytes);
      
      // PASTIKAN: File yang dihasilkan adalah format .xlsx yang dapat dibuka di Excel
      // Excel.encode() sudah menghasilkan format Office Open XML (.xlsx) yang standar

      // Gunakan FilePicker untuk memilih lokasi penyimpanan (sama seperti PDF)
      final bool isMobile = Platform.isAndroid || Platform.isIOS;

      String? outputFile;
      try {
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Laporan Excel',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: excelBytes,
        );
      } on UnsupportedError {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format file tidak didukung. Hanya file .xlsx yang didukung.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka dialog simpan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (outputFile != null) {
        String finalPath = outputFile;
        // Pastikan path selalu berakhiran .xlsx
        // Hapus ekstensi lain jika ada, lalu tambahkan .xlsx
        final lowerPath = finalPath.toLowerCase();
        if (lowerPath.endsWith('.xls')) {
          finalPath = finalPath.substring(0, finalPath.length - 4) + '.xlsx';
        } else if (!lowerPath.endsWith('.xlsx')) {
          finalPath = '$finalPath.xlsx';
        }

        // PASTIKAN 2: File dapat dibuka di aplikasi Excel
        // File .xlsx yang dihasilkan menggunakan format Office Open XML standar
        // yang didukung oleh Microsoft Excel, LibreOffice, Google Sheets, dan aplikasi spreadsheet lainnya
        if (isMobile) {
          // Di mobile, FilePicker sudah menyimpan file dengan benar
          // Verifikasi bahwa outputFile path valid
          if (outputFile.isNotEmpty) {
            // Pastikan path memiliki ekstensi .xlsx
            String verifiedPath = outputFile;
            if (!verifiedPath.toLowerCase().endsWith('.xlsx')) {
              verifiedPath = '$outputFile.xlsx';
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Laporan Excel (.xlsx) berhasil disimpan: $fileName\n\nFile dapat dibuka di aplikasi Excel.\n\nLokasi: $verifiedPath'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File Excel berhasil dibuat. Pastikan file disimpan dengan ekstensi .xlsx'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          try {
            final file = File(finalPath);
            // Pastikan file disimpan dengan benar sebagai .xlsx
            await file.writeAsBytes(excelBytes, flush: true);
            
            // Verifikasi file setelah disimpan
            if (!await file.exists()) {
              throw Exception('File tidak berhasil dibuat');
            }
            
            final fileSize = await file.length();
            if (fileSize < 100) {
              throw Exception('File terlalu kecil, kemungkinan tidak valid');
            }
            
            // Verifikasi signature ZIP
            final fileBytes = await file.readAsBytes();
            if (fileBytes.length < 4 || fileBytes[0] != 0x50 || fileBytes[1] != 0x4B) {
              throw Exception('File tidak memiliki format .xlsx yang valid');
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Laporan Excel (.xlsx) berhasil disimpan: $fileName\n\nFile dapat dibuka di aplikasi Excel.'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saat menyimpan file: $e\n\nPastikan file disimpan dengan ekstensi .xlsx'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }

        try {
          await OpenFilex.open(finalPath);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File tersimpan tetapi tidak dapat dibuka otomatis: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat export Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
    });
  }


  Future<void> _importFromExcel() async {
    if (!mounted) return;

    final pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
      withData: true,
    );

    if (pickedFile == null || pickedFile.files.isEmpty) {
      return;
    }

    if (!mounted) return;

    final overwrite = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Import'),
        content: const Text(
          'Data pada file Excel akan diimport dan menggantikan transaksi yang ada saat ini. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (overwrite != true || !mounted) {
      return;
    }

    final platformFile = pickedFile.files.first;
    Uint8List? bytes = platformFile.bytes;
    
    // Jika bytes tidak ada, coba baca dari path
    if (bytes == null || bytes.isEmpty) {
      final path = platformFile.path;
      if (path != null) {
        try {
          bytes = await File(path).readAsBytes();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tidak dapat membaca file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    }

    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File Excel kosong atau tidak dapat dibaca. Pastikan file berisi data.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validasi bahwa file adalah xlsx (minimal 4 bytes untuk signature)
    if (bytes.length < 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File terlalu kecil atau tidak valid. Pastikan file adalah file Excel .xlsx yang valid.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Coba decode file Excel
      Excel excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (decodeError) {
        final fileName = platformFile.name.toLowerCase();
        String errorMsg = 'Gagal membaca file Excel.\n\n';
        errorMsg += 'Pastikan:\n';
        if (fileName.endsWith('.xls')) {
          errorMsg += '1. File .xls (Excel 97-2003) tidak didukung. Silakan simpan file sebagai .xlsx (Excel 2007+) terlebih dahulu.\n';
        } else {
          errorMsg += '1. File berformat .xlsx (Excel 2007+)\n';
        }
        errorMsg += '2. File dapat dibuka di aplikasi Excel\n';
        errorMsg += '3. File memiliki header "NO" dan "TGL" di baris pertama data';
        throw Exception(errorMsg);
      }
      if (excel.tables.isEmpty) {
        String errorMsg = 'Sheet pada file Excel kosong.\n\n';
        errorMsg += 'Pastikan:\n';
        errorMsg += '1. File berformat .xlsx (Excel 2007+)\n';
        errorMsg += '2. File dapat dibuka di aplikasi Excel\n';
        errorMsg += '3. File memiliki header "NO" dan "TGL" di baris pertama data';
        throw Exception(errorMsg);
      }

      Sheet? sheet;
      for (final entry in excel.tables.entries) {
        if (entry.value.maxRows > 0) {
          sheet = entry.value;
          break;
        }
      }

      if (sheet == null) {
        String errorMsg = 'Tidak menemukan data pada sheet Excel.\n\n';
        errorMsg += 'Pastikan:\n';
        errorMsg += '1. File berformat .xlsx (Excel 2007+)\n';
        errorMsg += '2. File dapat dibuka di aplikasi Excel\n';
        errorMsg += '3. File memiliki header "NO" dan "TGL" di baris pertama data';
        throw Exception(errorMsg);
      }

      int headerRowIndex = -1;
      // Cari header "NO" dan "TGL" dimulai dari baris pertama (A1, baris 1, index 0)
      
      // Kumpulkan informasi debug
      List<String> debugRows = [];
      
      // Cek baris pertama (A1, index 0) - ini adalah prioritas utama
      try {
        if (sheet.rows.isNotEmpty) {
          final row1 = sheet.rows[0]; // Index 0 = baris 1 (A1)
          if (row1.isNotEmpty && row1.length >= 2) {
            final valA = _cellString(row1, 0).trim().toUpperCase(); // Cell A1
            final valB = _cellString(row1, 1).trim().toUpperCase(); // Cell B1
            
            // Simpan untuk debug
            debugRows.add('Baris 1: A="$valA", B="$valB"');
            
            // Cek eksak match untuk "NO" dan "TGL"
            if (valA == 'NO' && valB == 'TGL') {
              headerRowIndex = 0; // Index 0 = baris 1 (A1)
            } else {
              // Cek variasi lain
              if ((valA == 'NO' || valA == 'NOMOR' || valA == 'NO.') && 
                  (valB == 'TGL' || valB == 'TANGGAL' || valB == 'DATE')) {
                headerRowIndex = 0; // Index 0 = baris 1 (A1)
              }
            }
          }
        }
      } catch (_) {
        // Jika tidak bisa akses langsung, lanjutkan dengan loop
      }
      
      // Jika belum ditemukan di baris pertama, cari di baris-baris berikutnya (maksimal 30 baris)
      if (headerRowIndex == -1) {
        for (int i = 0; i < sheet.rows.length && i < 30; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row.length < 2) {
            continue;
          }
          
          try {
            final firstCell = _cellString(row, 0).trim().toUpperCase();
            final secondCell = _cellString(row, 1).trim().toUpperCase();
            
            // Simpan untuk debug
            if (i < 10) {
              debugRows.add('Baris ${i + 1}: A="$firstCell", B="$secondCell"');
            }
            
            // Cek eksak match untuk "NO" dan "TGL" (case-insensitive)
            if (firstCell == 'NO' && secondCell == 'TGL') {
              headerRowIndex = i;
              break;
            }
            
            // Cek variasi lain jika eksak match tidak ditemukan
            if ((firstCell == 'NO' || firstCell == 'NOMOR' || firstCell == 'NO.') && 
                (secondCell == 'TGL' || secondCell == 'TANGGAL' || secondCell == 'DATE')) {
              headerRowIndex = i;
              break;
            }
          } catch (e) {
            // Jika error membaca cell, skip baris ini
            continue;
          }
        }
      }

      if (headerRowIndex == -1) {
        // Tampilkan informasi debug
        String debugInfo = debugRows.isNotEmpty 
            ? debugRows.join('\n')
            : 'Tidak ada data yang ditemukan di 10 baris pertama.';
        
        String errorMsg = 'Format file tidak sesuai. Header "NO" dan "TGL" tidak ditemukan.\n\n';
        errorMsg += 'Baris yang diperiksa:\n$debugInfo\n\n';
        errorMsg += 'Pastikan:\n';
        errorMsg += '1. File berformat .xlsx (Excel 2007+)\n';
        errorMsg += '2. File dapat dibuka di aplikasi Excel\n';
        errorMsg += '3. File memiliki header "NO" dan "TGL" di baris pertama (A1 dan B1)\n\n';
        errorMsg += 'Format file Excel yang diharapkan:\n';
        errorMsg += '- Kolom A: NO\n';
        errorMsg += '- Kolom B: TGL\n';
        errorMsg += '- Kolom C: URAIAN\n';
        errorMsg += '- Kolom D: MASUK\n';
        errorMsg += '- Kolom E: KELUAR\n';
        errorMsg += '- Kolom F: SALDO\n';
        errorMsg += '- Kolom G: KETERANGAN\n\n';
        errorMsg += 'File harus diexport dari aplikasi ini atau memiliki format yang sama.';
        
        throw Exception(errorMsg);
      }

      final List<Transaction> importedTransactions = [];
      int skippedRows = 0;
      List<String> skipReasons = [];

      for (int i = headerRowIndex + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (_isRowEmpty(row)) {
          skippedRows++;
          continue;
        }

        final description = _cellString(row, 2);
        if (description.isEmpty) {
          skippedRows++;
          continue;
        }

        final normalizedDescription = description.toLowerCase();
        if (normalizedDescription.contains('saldo buku awal') || normalizedDescription == 'total') {
          skippedRows++;
          continue;
        }

        final date = _parseExcelDate(_cellRawValue(row, 1));
        if (date == null) {
          skippedRows++;
          final dateRaw = _cellRawValue(row, 1);
          if (dateRaw != null) {
            skipReasons.add('Baris ${i + 1}: Tanggal tidak valid ("${dateRaw}")');
          }
          continue;
        }

        final incomeAmount = _cellDouble(row, 3);
        final expenseAmount = _cellDouble(row, 4);

        TransactionType? type;
        double amount = 0;

        if (incomeAmount > 0 && expenseAmount <= 0) {
          type = TransactionType.income;
          amount = incomeAmount;
        } else if (expenseAmount > 0 && incomeAmount <= 0) {
          type = TransactionType.expense;
          amount = expenseAmount;
        } else if (incomeAmount > 0 && expenseAmount > 0) {
          // Jika kedua kolom terisi, abaikan untuk menghindari data ambigu
          skippedRows++;
          continue;
        } else {
          skippedRows++;
          if (incomeAmount == 0 && expenseAmount == 0) {
            skipReasons.add('Baris ${i + 1}: Kolom MASUK dan KELUAR keduanya kosong atau 0');
          }
          continue;
        }

        final rawNotes = _cellString(row, 6);
        String category;
        String? notes;

        if (type == TransactionType.income) {
          category = IncomeCategory.categories.first;
        } else {
          category = ExpenseCategory.categories.first;
        }

        if (rawNotes.isNotEmpty) {
          final incomeCategory = IncomeCategory.categories.firstWhere(
            (c) => c.toLowerCase() == rawNotes.toLowerCase(),
            orElse: () => '',
          );

          final expenseCategory = ExpenseCategory.categories.firstWhere(
            (c) => c.toLowerCase() == rawNotes.toLowerCase(),
            orElse: () => '',
          );

          if (type == TransactionType.income && incomeCategory.isNotEmpty) {
            category = incomeCategory;
          } else if (type == TransactionType.expense && expenseCategory.isNotEmpty) {
            category = expenseCategory;
          } else {
            notes = rawNotes;
          }
        }

        importedTransactions.add(
          Transaction.create(
            type: type,
            amount: amount,
            description: description,
            category: category,
            date: DateTime(date.year, date.month, date.day),
            notes: notes,
          ),
        );
      }

      if (importedTransactions.isEmpty) {
        String errorMsg = 'Tidak ada transaksi valid yang ditemukan di file Excel.\n';
        errorMsg += 'Total baris diperiksa: ${sheet.rows.length - headerRowIndex - 1}, ';
        errorMsg += 'baris dilewati: $skippedRows\n\n';
        
        if (skipReasons.isNotEmpty && skipReasons.length <= 10) {
          errorMsg += 'Alasan baris dilewati:\n';
          errorMsg += skipReasons.take(10).join('\n');
          if (skipReasons.length > 10) {
            errorMsg += '\n... dan ${skipReasons.length - 10} baris lainnya';
          }
          errorMsg += '\n\n';
        }
        
        errorMsg += 'Pastikan:\n';
        errorMsg += '1. File berformat .xlsx (Excel 2007+)\n';
        errorMsg += '2. File dapat dibuka di aplikasi Excel\n';
        errorMsg += '3. File memiliki header "NO" dan "TGL" di baris pertama data\n';
        errorMsg += '4. File memiliki data transaksi setelah header\n';
        errorMsg += '5. Kolom TGL berisi tanggal yang valid (format: dd/MM/yy atau dd/MM/yyyy)\n';
        errorMsg += '6. Kolom MASUK atau KELUAR harus terisi dengan angka (salah satu atau keduanya)';
        throw Exception(errorMsg);
      }

      await StorageService.replaceTransactions(importedTransactions);

      if (!mounted) return;

      await _loadMonthlyData();

      if (!mounted) return;

      if (_startDate != null && _endDate != null) {
        await _loadMutasiData();
      } else {
        setState(() {
          _mutasiTransactions = [];
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengimport ${importedTransactions.length} transaksi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        final errorStr = e.toString().toLowerCase();
        final errorMsg = e.toString();
        
        // Jika error sudah berisi pesan yang jelas, gunakan itu
        if (errorMsg.contains('File .xls') || errorMsg.contains('File Excel tidak valid') || 
            errorMsg.contains('Gagal membaca file Excel') || errorMsg.contains('Format file tidak sesuai') ||
            errorMsg.contains('Sheet pada file Excel') || errorMsg.contains('Tidak menemukan data') ||
            errorMsg.contains('Tidak ada transaksi valid')) {
          errorMessage = errorMsg;
        } else if (errorStr.contains('decode') || errorStr.contains('format') || 
                   errorStr.contains('unsupported') || errorStr.contains('invalid')) {
          final fileName = platformFile.name.toLowerCase();
          String errorMsg = 'File Excel tidak valid atau rusak.\n\n';
          errorMsg += 'Pastikan:\n';
          if (fileName.endsWith('.xls')) {
            errorMsg += '1. File .xls (Excel 97-2003) tidak didukung. Silakan simpan file sebagai .xlsx (Excel 2007+) terlebih dahulu.\n';
          } else {
            errorMsg += '1. File berformat .xlsx (Excel 2007+)\n';
          }
          errorMsg += '2. File dapat dibuka di aplikasi Excel\n';
          errorMsg += '3. File memiliki header "NO" dan "TGL" di baris pertama data';
          errorMessage = errorMsg;
        } else {
          // Error lainnya, tampilkan pesan yang lebih informatif
          errorMessage = 'Gagal mengimport data dari file Excel: $e\n\nPastikan:\n1. File berformat .xlsx (Excel 2007+)\n2. File dapat dibuka di aplikasi Excel\n3. File memiliki header "NO" dan "TGL" di baris pertama data';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Fungsi sederhana untuk membaca cell value
  dynamic _cellRawValue(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) {
      return null;
    }
    
    final Data cellData = row[index]!;
    final dynamic cellValue = cellData.value;
    
    if (cellValue == null) {
      return null;
    }
    
    // Handle TextCellValue
    if (cellValue is TextCellValue) {
      return cellValue.value;
    }
    // Handle IntCellValue
    if (cellValue is IntCellValue) {
      return cellValue.value;
    }
    // Handle DoubleCellValue
    if (cellValue is DoubleCellValue) {
      return cellValue.value;
    }
    // Handle String langsung
    if (cellValue is String) {
      return cellValue;
    }
    // Handle Number
    if (cellValue is num) {
      return cellValue;
    }
    
    // Fallback: convert ke string
    return cellValue.toString();
  }

  String _cellString(List<Data?> row, int index) {
    try {
      if (index >= row.length || row[index] == null) {
        return '';
      }
      
      final Data cellData = row[index]!;
      final dynamic cellValue = cellData.value;
      
      if (cellValue == null) {
        return '';
      }
      
      String result = '';
      
      // Handle TextCellValue
      if (cellValue is TextCellValue) {
        final textValue = cellValue.value;
        result = textValue.toString();
      }
      // Handle IntCellValue
      else if (cellValue is IntCellValue) {
        result = cellValue.value.toString();
      }
      // Handle DoubleCellValue
      else if (cellValue is DoubleCellValue) {
        result = cellValue.value.toString();
      }
      // Handle String langsung
      else if (cellValue is String) {
        result = cellValue;
      }
      // Handle Number
      else if (cellValue is num) {
        result = cellValue.toString();
      }
      // Fallback
      else {
        result = cellValue.toString();
      }
      
      // Clean up result
      result = result.trim();
      result = result.replaceAll('\x00', '').replaceAll('\u0000', '').trim();
      return result;
    } catch (e) {
      return '';
    }
  }

  double _cellDouble(List<Data?> row, int index) {
    final rawValue = _cellRawValue(row, index);
    if (rawValue == null) {
      return 0;
    }
    
    // Jika sudah angka, langsung return
    if (rawValue is num) {
      return rawValue.toDouble();
    }
    
    // Parse dari string
    String strValue = rawValue.toString().trim();
    if (strValue.isEmpty) {
      return 0;
    }
    
    // Hapus karakter non-numeric kecuali titik, koma, dan minus
    strValue = strValue.replaceAll(RegExp(r'[^\d.,-]'), '');
    
    // Coba berbagai format
    // Format Indonesia: 1.234.567,89 (titik ribuan, koma desimal)
    // Format US: 1,234,567.89 (koma ribuan, titik desimal)
    
    // Cek apakah ada koma dan titik
    final hasComma = strValue.contains(',');
    final hasDot = strValue.contains('.');
    
    if (hasComma && hasDot) {
      // Ada keduanya, cek mana yang terakhir (itu desimal)
      final lastComma = strValue.lastIndexOf(',');
      final lastDot = strValue.lastIndexOf('.');
      
      if (lastComma > lastDot) {
        // Koma terakhir = format Indonesia (1.234.567,89)
        strValue = strValue.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Titik terakhir = format US (1,234,567.89)
        strValue = strValue.replaceAll(',', '');
      }
    } else if (hasComma && !hasDot) {
      // Hanya koma - bisa format Indonesia atau ribuan
      // Jika koma di posisi terakhir atau dekat akhir, kemungkinan desimal
      final commaPos = strValue.lastIndexOf(',');
      if (commaPos > strValue.length - 4) {
        // Koma dekat akhir, kemungkinan desimal
        strValue = strValue.replaceAll(',', '.');
      } else {
        // Koma sebagai pemisah ribuan
        strValue = strValue.replaceAll(',', '');
      }
    } else if (hasDot && !hasComma) {
      // Hanya titik - bisa format US atau ribuan Indonesia
      // Jika titik di posisi terakhir atau dekat akhir, kemungkinan desimal
      final dotPos = strValue.lastIndexOf('.');
      if (dotPos > strValue.length - 4) {
        // Titik dekat akhir, kemungkinan desimal (format US)
        // Biarkan seperti itu
      } else {
        // Titik sebagai pemisah ribuan (format Indonesia)
        strValue = strValue.replaceAll('.', '');
      }
    }
    
    final parsed = double.tryParse(strValue);
    return parsed ?? 0;
  }

  bool _isRowEmpty(List<Data?> row) {
    for (int i = 0; i < row.length; i++) {
      final rawValue = _cellRawValue(row, i);
      if (rawValue != null && rawValue.toString().trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  DateTime? _parseExcelDate(dynamic value) {
    if (value == null) {
      return null;
    }
    
    // Handle DateTime langsung
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    
    // Konversi ke string terlebih dahulu untuk memastikan format konsisten
    String dateStr = '';
    if (value is String) {
      dateStr = value;
    } else if (value is num) {
      // Handle Excel date serial number (angka)
      try {
        // Excel date epoch: January 1, 1900 = 1
        // Unix epoch: January 1, 1970
        // Excel epoch offset: 25569 days
        final excelEpoch = 25569;
        final daysSinceExcelEpoch = value.toDouble() - excelEpoch;
        final milliseconds = (daysSinceExcelEpoch * 86400000).round();
        final date = DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true).toLocal();
        return DateTime(date.year, date.month, date.day);
      } catch (e) {
        // Jika gagal, coba sebagai string
        dateStr = value.toString();
      }
    } else {
      dateStr = value.toString();
    }
    
    // Bersihkan string dari karakter tersembunyi
    String trimmed = dateStr.trim();
    trimmed = trimmed.replaceAll('\x00', '').replaceAll('\u0000', '').trim();
    
    if (trimmed.isEmpty) {
      return null;
    }

    // PRIORITAS 1: Manual parsing untuk format dd/MM/yy atau d/M/yy (contoh: 20/11/25 = 20 November 2025)
    // Ini perlu dilakukan manual karena parseStrict terlalu ketat
    try {
      // Hapus karakter non-digit dan slash
      final cleanStr = trimmed.replaceAll(RegExp(r'[^\d/]'), '');
      final parts = cleanStr.split('/');
      
      if (parts.length == 3) {
        final dayStr = parts[0].trim();
        final monthStr = parts[1].trim();
        final yearStr = parts[2].trim();
        
        if (dayStr.isNotEmpty && monthStr.isNotEmpty && yearStr.isNotEmpty) {
          final day = int.tryParse(dayStr);
          final month = int.tryParse(monthStr);
          
          if (day != null && month != null && day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            int year;
            if (yearStr.length == 2) {
              // Format yy - asumsikan 20xx untuk tahun 00-99
              final yy = int.tryParse(yearStr);
              if (yy != null) {
                // Tahun 00-99 dianggap sebagai 2000-2099
                year = 2000 + yy;
              } else {
                return null;
              }
            } else if (yearStr.length == 4) {
              // Format yyyy
              final yyyy = int.tryParse(yearStr);
              if (yyyy != null && yyyy >= 1900 && yyyy <= 2100) {
                year = yyyy;
              } else {
                return null;
              }
            } else {
              return null;
            }
            
            // Validasi tanggal
            try {
              final date = DateTime(year, month, day);
              // Pastikan tanggal valid (misalnya 31 Februari tidak valid)
              if (date.year == year && date.month == month && date.day == day) {
                return DateTime(date.year, date.month, date.day);
              }
            } catch (_) {
              return null;
            }
          }
        }
      }
    } catch (e) {
      // Lanjutkan ke parsing dengan DateFormat
    }

    // PRIORITAS 2: Coba parse sebagai angka (Excel date serial)
    final numValue = double.tryParse(trimmed.replaceAll(',', '.').replaceAll(' ', ''));
    if (numValue != null && numValue > 0 && numValue < 100000) {
      // Kemungkinan Excel date serial number
      try {
        final excelEpoch = 25569;
        final daysSinceExcelEpoch = numValue - excelEpoch;
        final milliseconds = (daysSinceExcelEpoch * 86400000).round();
        final date = DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true).toLocal();
        return DateTime(date.year, date.month, date.day);
      } catch (_) {
        // Lanjutkan ke parsing format string
      }
    }

    // PRIORITAS 3: Coba berbagai format tanggal dengan DateFormat
    final possibleFormats = [
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('d/M/yyyy'),
      DateFormat('dd.MM.yyyy'),
      DateFormat('d.MM.yyyy'),
    ];

    for (final format in possibleFormats) {
      try {
        final parsed = format.parseStrict(trimmed);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        // Try next format
      }
    }
    
    // PRIORITAS 4: Coba parse dengan parse (bukan parseStrict) sebagai fallback untuk format dd/MM/yyyy
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(trimmed);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      // Gagal parse
    }

    return null;
  }


  Future<void> _resetAllTransactions() async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reset Semua Transaksi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERINGATAN!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tindakan ini akan menghapus SEMUA transaksi yang tersimpan. Tindakan ini TIDAK DAPAT DIBATALKAN.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Apakah Anda yakin ingin mereset semua transaksi?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Sekarang'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await StorageService.clearAllData();
        if (mounted) {
        setState(() {
            _mutasiTransactions.clear();
          _monthlyTransactions.clear();
        });
          await _loadMonthlyData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semua transaksi berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: _tabController != null ? TabBar(
          controller: _tabController!,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tanggal'),
            Tab(text: 'Mutasi'),
          ],
        ) : null,
        actions: [
          Builder(
            builder: (context) {
              final currentIndex = _tabController?.index ?? 0;
              if (currentIndex == 0) {
                return IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _selectMonth,
                  tooltip: 'Pilih Bulan',
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  onPressed: _selectDateRange,
                  tooltip: 'Pilih Rentang Tanggal',
                );
              }
            },
          ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              tooltip: 'Opsi Laporan',
              onSelected: (value) {
                if (value == 'download') {
                  _downloadMonthlyReport();
                } else if (value == 'print') {
                  _printMonthlyReport();
                } else if (value == 'excel') {
                  _exportToExcel();
                } else if (value == 'import') {
                  _importFromExcel();
                } else if (value == 'reset') {
                  _resetAllTransactions();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Download PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Print Langsung'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Export Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Import dari Excel'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset Semua Transaksi'),
                  ],
                ),
              ),
          ],
        ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tabController != null ? TabBarView(
              controller: _tabController!,
              children: [
                _buildTanggalTab(),
                _buildMutasiTab(),
              ],
            ) : const Center(child: CircularProgressIndicator()),
    );
  }



  Widget _buildTanggalTab() {
    // Group transactions by date
    final Map<String, List<Transaction>> transactionsByDate = {};
    for (final transaction in _monthlyTransactions) {
      final dateKey = DateFormat('dd MMM yyyy').format(transaction.date);
      transactionsByDate[dateKey] ??= [];
      transactionsByDate[dateKey]!.add(transaction);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Laporan Keuangan - ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                  style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_monthlyTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                    'Tidak ada transaksi pada bulan ini',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Tampilkan tanggal dari terkecil ke terbesar (kronologis)
            ...(() {
              final sortedDates = transactionsByDate.keys.toList()
                ..sort((a, b) {
                  final da = DateFormat('dd MMM yyyy').parse(a);
                  final db = DateFormat('dd MMM yyyy').parse(b);
                  return da.compareTo(db);
                });

              return sortedDates.map((date) {
                final transactions = transactionsByDate[date]!;
              
              final dailyIncome = transactions
                  .where((t) => t.type == TransactionType.income)
                  .fold(0.0, (sum, t) => sum + t.amount);
              
              final dailyExpense = transactions
                  .where((t) => t.type == TransactionType.expense)
                  .fold(0.0, (sum, t) => sum + t.amount);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                            Expanded(
                              child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                            'Saldo: ${NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(dailyIncome - dailyExpense)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: (dailyIncome - dailyExpense) >= 0 
                                  ? Colors.green 
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  textAlign: TextAlign.right,
                                ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Masuk: ${NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(dailyIncome)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Keluar: ${NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(dailyExpense)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${transactions.length} transaksi',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              }).toList();
            })(),
        ],
      ),
    );
  }

  Widget _buildMutasiTab() {
    // Jika belum ada tanggal yang dipilih, tampilkan form untuk memilih rentang tanggal
    if (_startDate == null || _endDate == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mutasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Rentang Tanggal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan pilih tanggal mulai dan tanggal akhir untuk menampilkan mutasi transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Pilih Rentang Tanggal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dateRangeStr = '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}';

    // Group transactions by date
    final Map<String, List<Transaction>> transactionsByDate = {};
    for (final transaction in _mutasiTransactions) {
      final dateKey = DateFormat('dd MMM yyyy').format(transaction.date);
      transactionsByDate[dateKey] ??= [];
      transactionsByDate[dateKey]!.add(transaction);
    }

    // Sort transactions by date (oldest first)
    final sortedTransactions = List<Transaction>.from(_mutasiTransactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalIncome = sortedTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = sortedTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Header dengan rentang tanggal
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mutasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 4),
                Text(
                      dateRangeStr,
                  style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Saldo: ${NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(totalIncome - totalExpense)}',
                  style: TextStyle(
                    fontSize: 14,
                      color: (totalIncome - totalExpense) >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.right,
                  ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // Tombol untuk mengubah rentang tanggal
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Ubah Rentang Tanggal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _mutasiTransactions = [];
                  });
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Hapus Filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_mutasiTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak ada transaksi pada rentang tanggal ini',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...(() {
              // Tampilkan tanggal dari terkecil ke terbesar (kronologis)
              final sortedDates = transactionsByDate.keys.toList()
                ..sort((a, b) {
                  final da = DateFormat('dd MMM yyyy').parse(a);
                  final db = DateFormat('dd MMM yyyy').parse(b);
                  return da.compareTo(db);
                });

              return sortedDates.map((date) {
                final transactions = transactionsByDate[date]!;

                final dailyIncome = transactions
                    .where((t) => t.type == TransactionType.income)
                    .fold(0.0, (sum, t) => sum + t.amount);

                final dailyExpense = transactions
                    .where((t) => t.type == TransactionType.expense)
                    .fold(0.0, (sum, t) => sum + t.amount);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Saldo: ${NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(dailyIncome - dailyExpense)}',
                      style: TextStyle(
                                    fontSize: 14,
                                    color: (dailyIncome - dailyExpense) >= 0
                            ? Colors.green 
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Masuk: ${NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(dailyIncome)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Keluar: ${NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(dailyExpense)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${transactions.length} transaksi',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            );
              }).toList();
            }()),
        ],
      ),
    );
  }



}
