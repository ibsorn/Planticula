import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones locales para los recordatorios de riego.
///
/// Programa una notificación por planta en su próxima fecha de riego
/// (a una hora razonable del día). Se reprograma cada vez que cambian las
/// plantas (carga, riego, edición, borrado).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'watering_reminders';
  static const _channelName = 'Recordatorios de riego';
  static const _channelDesc = 'Avisos para regar tus plantas a tiempo';

  /// Hora del día (24h) a la que se dispara el recordatorio.
  static const _reminderHour = 9;

  Future<void> init() async {
    if (_initialized) return;

    // Zona horaria local (necesaria para zonedSchedule).
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[Notifications] No se pudo resolver la zona horaria: $e');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Pide permiso de notificaciones (Android 13+ e iOS).
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  int _idFor(String plantId) => plantId.hashCode & 0x7fffffff;

  /// Reprograma los recordatorios de TODAS las plantas: cancela todo y vuelve
  /// a programar las que tienen recordatorio y próxima fecha de riego futura.
  Future<void> syncForPlants(List<Plant> plants) async {
    if (!_initialized) await init();
    await _plugin.cancelAll();
    for (final plant in plants) {
      await schedulePlant(plant);
    }
  }

  /// Programa (o reprograma) el recordatorio de una única planta.
  Future<void> schedulePlant(Plant plant) async {
    if (!_initialized) await init();
    // Reprogramar: cancelar el anterior por si la frecuencia cambió.
    await cancelForPlant(plant.id);
    if (!plant.hasWateringReminder) return;
    final next = plant.nextWatering;
    if (next == null) return;

    // Dispara a las _reminderHour del día de riego (hora local).
    var scheduled = tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      _reminderHour,
    );
    final now = tz.TZDateTime.now(tz.local);
    // Si ya pasó (planta atrasada o la hora de hoy ya pasó), avisa "pronto".
    if (scheduled.isBefore(now)) {
      scheduled = now.add(const Duration(minutes: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: _idFor(plant.id),
        title: '💧 Hora de regar',
        body: '${plant.displayName} necesita agua hoy.',
        scheduledDate: scheduled,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: plant.id,
      );
    } catch (e) {
      debugPrint('[Notifications] Error programando ${plant.id}: $e');
    }
  }

  Future<void> cancelForPlant(String plantId) async {
    await _plugin.cancel(id: _idFor(plantId));
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
