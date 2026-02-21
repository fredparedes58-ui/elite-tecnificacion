// ============================================================
// Mis créditos: balance + historial. Usa CreditsRepository.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/credits_repository.dart';

class MyCreditsScreen extends StatefulWidget {
  const MyCreditsScreen({super.key});

  @override
  State<MyCreditsScreen> createState() => _MyCreditsScreenState();
}

class _MyCreditsScreenState extends State<MyCreditsScreen> {
  List<CreditTransactionItem> _transactions = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<CreditsRepository>();
      repo.getBalance();
      repo.subscribeRealtime();
      _loadHistory();
    });
  }

  @override
  void dispose() {
    context.read<CreditsRepository>().unsubscribeRealtime();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final repo = context.read<CreditsRepository>();
    final list = await repo.getTransactionHistory(limit: 50);
    if (mounted) {
      setState(() {
        _transactions = list;
        _loadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<CreditsRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis créditos', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await repo.getBalance(forceRefresh: true);
          await _loadHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Saldo actual', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (repo.loading && repo.balance == 0)
                        const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Text(
                          '${repo.balance}',
                          style: GoogleFonts.oswald(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      Text('créditos', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Historial', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_loadingHistory)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Sin movimientos', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                )
              else
                ..._transactions.map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(t.description),
                    subtitle: Text(DateFormat('d/M/yyyy HH:mm').format(t.createdAt)),
                    trailing: Text(
                      '${t.amount > 0 ? "+" : ""}${t.amount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: t.amount >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}
