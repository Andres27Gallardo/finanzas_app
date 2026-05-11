import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _initialized = true;
  }

  static const _channel = AndroidNotificationDetails(
    'finanzas_ia_channel', 'Finanzas IA',
    channelDescription: 'Recordatorios y consejos financieros',
    importance: Importance.high, priority: Priority.high, icon: '@mipmap/ic_launcher',
  );

  Future<void> showNow({required int id, required String title, required String body}) async {
    await init();
    await _plugin.show(id, title, body, const NotificationDetails(android: _channel));
  }

  Future<void> scheduleDailyAt({required int id, required String title, required String body, required int hour, required int minute}) async {
    await init();
    try {
      await _plugin.zonedSchedule(
        id, title, body, _nextTime(hour, minute),
        const NotificationDetails(android: _channel),
        // ✅ Fix: inexactAllowWhileIdle no requiere permiso especial de Android 12+
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Si falla programada, mostrar inmediata como fallback
      await showNow(id: id, title: title, body: body);
    }
  }

  Future<void> scheduleOnDate({required int id, required String title, required String body, required DateTime dateTime}) async {
    await init();
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id, title, body, scheduled,
        const NotificationDetails(android: _channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Ignorar si no se puede programar
    }
  }

  Future<void> scheduleInDays({required int id, required String title, required String body, required int days}) async {
    await init();
    final scheduled = tz.TZDateTime.now(tz.local).add(Duration(days: days));
    try {
      await _plugin.zonedSchedule(
        id, title, body, scheduled,
        const NotificationDetails(android: _channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Ignorar
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  Future<void> scheduleDailySummary({required String income, required String expense, required String balance, required String tip}) async {
    await cancel(1001);
    await scheduleDailyAt(id: 1001, title: '💰 Tu resumen del día', body: '📈 $income | 📉 $expense | Balance: $balance', hour: 8, minute: 0);
    await cancel(1002);
    await scheduleDailyAt(id: 1002, title: '💡 Consejo financiero', body: tip, hour: 19, minute: 0);
  }

  Future<void> scheduleDebtReminder({required int notifId, required String personName, required String amount, required DateTime dueDate, int? frequencyDays}) async {
    await scheduleOnDate(id: notifId, title: '⚠️ Recordatorio: $personName', body: 'Mañana vence: $amount', dateTime: dueDate.subtract(const Duration(days: 1)));
    await scheduleOnDate(id: notifId + 1, title: '🔔 Vence HOY: $personName', body: 'Debe devolverse: $amount', dateTime: dueDate);
    if (frequencyDays != null && frequencyDays > 0) {
      await scheduleInDays(id: notifId + 2, title: '🔄 Abono pendiente: $personName', body: 'Recuerda registrar el abono de $amount', days: frequencyDays);
    }
  }
}
