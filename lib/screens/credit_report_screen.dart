// ============================================================
// Historial de consumo de créditos - Descarga PDF (Semanal/Mensual)
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreditReportScreen extends StatefulWidget {
  const CreditReportScreen({super.key});

  @override
  State<CreditReportScreen> createState() => _CreditReportScreenState();
}

class _CreditReportScreenState extends State<CreditReportScreen> {
  String _period = 'monthly'; // 'weekly' | 'monthly'
  DateTime _rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _rangeEnd = DateTime.now();
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = false;

  Future<void> _loadTransactions() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);

    final start = _rangeStart.toUtc().toIso8601String();
    final end = _rangeEnd.add(const Duration(days: 1)).toUtc().toIso8601String();

    try {
      final res = await Supabase.instance.client
          .from('credit_transactions')
          .select('id, amount, transaction_type, description, created_at, reservation_id')
          .eq('user_id', userId)
          .gte('created_at', start)
          .lte('created_at', end)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      final ids = list
          .where((r) => r['reservation_id'] != null)
          .map((r) => r['reservation_id'] as String)
          .toSet()
          .toList();

      Map<String, String> sessionTitles = {};
      if (ids.isNotEmpty) {
        final sessions = await Supabase.instance.client
            .from('reservations')
            .select('id, title, start_time')
            .inFilter('id', ids);
        for (final s in sessions) {
          sessionTitles[s['id'] as String] = (s['title'] as String? ?? 'Sesión') +
              (s['start_time'] != null
                  ? ' (${DateFormat('d/M', 'es').format(DateTime.parse(s['start_time'] as String))})'
                  : '');
        }
      }

      for (final t in list) {
        final rid = t['reservation_id'] as String?;
        if (rid != null && sessionTitles.containsKey(rid)) {
          t['session_title'] = sessionTitles[rid];
        } else {
          t['session_title'] = t['description'] ?? '—';
        }
      }

      if (mounted) {
        setState(() {
          _transactions = list;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('CreditReportScreen error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _setPeriod(String p) {
    setState(() {
      _period = p;
      final now = DateTime.now();
      if (p == 'weekly') {
        final weekday = now.weekday;
        _rangeStart = now.subtract(Duration(days: weekday - 1));
        _rangeStart = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
        _rangeEnd = _rangeStart.add(const Duration(days: 6));
      } else {
        _rangeStart = DateTime(now.year, now.month, 1);
        _rangeEnd = now;
      }
    });
    _loadTransactions();
  }

  @override
  void initState() {
    super.initState();
    _setPeriod(_period);
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    final dateRangeStr =
        '${DateFormat('d/MM/yyyy', 'es').format(_rangeStart)} - ${DateFormat('d/MM/yyyy', 'es').format(_rangeEnd)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Historial de consumo de créditos',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Período: $dateRangeStr', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Créditos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Sesión / Concepto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ..._transactions.map((t) {
                final createdAt = t['created_at'] != null
                    ? DateFormat('d/MM/yyyy HH:mm', 'es')
                        .format(DateTime.parse(t['created_at'] as String).toLocal())
                    : '—';
                final amount = t['amount'] as int? ?? 0;
                final sessionTitle = t['session_title'] as String? ?? (t['description'] as String? ?? '—');
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(createdAt, style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('$amount', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(sessionTitle, style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/historial_creditos_$dateRangeStr.pdf'.replaceAll('/', '-'));
    await file.writeAsBytes(bytes);

    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Historial de consumo de créditos',
        text: 'Historial de consumo de créditos - $dateRangeStr',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generado. Puedes compartirlo o guardarlo.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de Créditos',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'weekly', label: Text('Semanal'), icon: Icon(Icons.date_range)),
                      ButtonSegment(value: 'monthly', label: Text('Mensual'), icon: Icon(Icons.calendar_month)),
                    ],
                    selected: {_period},
                    onSelectionChanged: (Set<String> s) {
                      if (s.isNotEmpty) _setPeriod(s.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${DateFormat('d/MM/yyyy', 'es').format(_rangeStart)} - ${DateFormat('d/MM/yyyy', 'es').format(_rangeEnd)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: _transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No hay movimientos en este período',
                        style: GoogleFonts.roboto(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final t = _transactions[index];
                        final createdAt = t['created_at'] != null
                            ? DateTime.parse(t['created_at'] as String).toLocal()
                            : null;
                        final amount = t['amount'] as int? ?? 0;
                        final sessionTitle = t['session_title'] as String? ?? t['description'] ?? '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: amount < 0
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              child: Icon(
                                amount < 0 ? Icons.remove : Icons.add,
                                color: amount < 0 ? Colors.red : Colors.green,
                              ),
                            ),
                            title: Text(sessionTitle, style: GoogleFonts.roboto(fontSize: 14)),
                            subtitle: createdAt != null
                                ? Text(DateFormat('d/MM/yyyy HH:mm', 'es').format(createdAt))
                                : null,
                            trailing: Text(
                              '$amount',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                color: amount < 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: _transactions.isEmpty ? null : _generateAndSharePdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Descargar PDF (compartir / guardar)'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
