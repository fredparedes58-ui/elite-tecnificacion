// ============================================================
// SystemConfigRepository: system_config (key, value jsonb).
// Paridad con useSystemConfig en React. Solo admins pueden actualizar.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemConfigData {
  SystemConfigData({
    this.sessionStart = 8,
    this.sessionEnd = 21,
    this.maxCapacity = 6,
    this.activeDays = const [1, 2, 3, 4, 5, 6],
    this.creditAlertThreshold = 3,
    this.cancellationHours = 24,
  });
  final int sessionStart;
  final int sessionEnd;
  final int maxCapacity;
  final List<int> activeDays;
  final int creditAlertThreshold;
  final int cancellationHours;

  SystemConfigData copyWith({
    int? sessionStart,
    int? sessionEnd,
    int? maxCapacity,
    List<int>? activeDays,
    int? creditAlertThreshold,
    int? cancellationHours,
  }) {
    return SystemConfigData(
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      activeDays: activeDays ?? this.activeDays,
      creditAlertThreshold: creditAlertThreshold ?? this.creditAlertThreshold,
      cancellationHours: cancellationHours ?? this.cancellationHours,
    );
  }
}

class SystemConfigRepository extends ChangeNotifier {
  SystemConfigData _config = SystemConfigData();
  bool _loading = false;
  String? _error;

  SystemConfigData get config => _config;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.from('system_config').select('key, value');
      final list = List<Map<String, dynamic>>.from(res);

      int sessionStart = 8, sessionEnd = 21;
      int maxCapacity = 6;
      List<int> activeDays = [1, 2, 3, 4, 5, 6];
      int creditAlertThreshold = 3;
      int cancellationHours = 24;

      for (final row in list) {
        final key = row['key']?.toString();
        final value = row['value'];
        if (key == null) continue;
        if (value is! Map) continue;
        final v = value as Map<String, dynamic>;
        switch (key) {
          case 'session_hours':
            sessionStart = (v['start'] is int) ? v['start'] as int : int.tryParse(v['start']?.toString() ?? '8') ?? 8;
            sessionEnd = (v['end'] is int) ? v['end'] as int : int.tryParse(v['end']?.toString() ?? '21') ?? 21;
            break;
          case 'max_capacity':
            maxCapacity = (v['value'] is int) ? v['value'] as int : int.tryParse(v['value']?.toString() ?? '6') ?? 6;
            break;
          case 'active_days':
            if (v['days'] is List) {
              activeDays = (v['days'] as List).map((e) => e is int ? e : int.tryParse(e?.toString() ?? '0') ?? 0).where((e) => e >= 1 && e <= 7).toList();
            }
            break;
          case 'credit_alert_threshold':
            creditAlertThreshold = (v['value'] is int) ? v['value'] as int : int.tryParse(v['value']?.toString() ?? '3') ?? 3;
            break;
          case 'cancellation_window':
            cancellationHours = (v['hours'] is int) ? v['hours'] as int : int.tryParse(v['hours']?.toString() ?? '24') ?? 24;
            break;
        }
      }

      _config = SystemConfigData(
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
        maxCapacity: maxCapacity,
        activeDays: activeDays,
        creditAlertThreshold: creditAlertThreshold,
        cancellationHours: cancellationHours,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSessionHours(int start, int end) async {
    try {
      await Supabase.instance.client
          .from('system_config')
          .update({'value': {'start': start, 'end': end}, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('key', 'session_hours');
      _config = _config.copyWith(sessionStart: start, sessionEnd: end);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SystemConfigRepository updateSessionHours: $e');
      return false;
    }
  }

  Future<bool> updateMaxCapacity(int value) async {
    try {
      await Supabase.instance.client
          .from('system_config')
          .update({'value': {'value': value}, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('key', 'max_capacity');
      _config = _config.copyWith(maxCapacity: value);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SystemConfigRepository updateMaxCapacity: $e');
      return false;
    }
  }

  Future<bool> updateActiveDays(List<int> days) async {
    try {
      await Supabase.instance.client
          .from('system_config')
          .update({'value': {'days': days}, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('key', 'active_days');
      _config = _config.copyWith(activeDays: days);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SystemConfigRepository updateActiveDays: $e');
      return false;
    }
  }

  Future<bool> updateCreditAlertThreshold(int value) async {
    try {
      await Supabase.instance.client
          .from('system_config')
          .update({'value': {'value': value}, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('key', 'credit_alert_threshold');
      _config = _config.copyWith(creditAlertThreshold: value);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SystemConfigRepository updateCreditAlertThreshold: $e');
      return false;
    }
  }

  Future<bool> updateCancellationHours(int hours) async {
    try {
      await Supabase.instance.client
          .from('system_config')
          .update({'value': {'hours': hours}, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('key', 'cancellation_window');
      _config = _config.copyWith(cancellationHours: hours);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SystemConfigRepository updateCancellationHours: $e');
      return false;
    }
  }
}
