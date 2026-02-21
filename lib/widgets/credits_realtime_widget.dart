// ============================================================
// Widget: Créditos en tiempo real (Supabase Realtime)
// Para el Home del padre. Muestra saldo y escucha cambios.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreditsRealtimeWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const CreditsRealtimeWidget({super.key, this.onTap});

  @override
  State<CreditsRealtimeWidget> createState() => _CreditsRealtimeWidgetState();
}

class _CreditsRealtimeWidgetState extends State<CreditsRealtimeWidget> {
  int _balance = 0;
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _balance = 0;
        _loading = false;
      });
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('user_credits')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _balance = (res?['balance'] as int?) ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('CreditsRealtimeWidget fetch error: $e');
      if (mounted) {
        setState(() {
          _balance = 0;
          _loading = false;
        });
      }
    }
  }

  void _subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = Supabase.instance.client
        .channel('user-credits-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_credits',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.containsKey('balance')) {
              final balance = newRow['balance'] as int?;
              if (mounted) {
                setState(() => _balance = balance ?? 0);
              }
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.25),
                colorScheme.secondary.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TUS CRÉDITOS',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_loading)
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    else
                      Text(
                        '$_balance',
                        style: GoogleFonts.oswald(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.live_tv,
                size: 18,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'En vivo',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
