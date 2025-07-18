import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Utilidades para manejo de fechas y horas con soporte para UTC
class DateTimeUtils {
  static final DateFormat _dateFormatEs = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
  static final DateFormat _dateTimeFormatEs = DateFormat('d/M/y H:mm', 'es_ES');
  static final DateFormat _timeFormatEs = DateFormat('HH:mm', 'es_ES');

  /// Convierte una fecha y hora local a UTC
  static DateTime toUtc(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  /// Convierte una fecha y hora UTC a local
  static DateTime toLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Crea un DateTime combinando fecha y TimeOfDay
  static DateTime combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Crea un DateTime combinando fecha y TimeOfDay en UTC
  static DateTime combineToUtc(DateTime date, TimeOfDay time) {
    final localDateTime = combineDateTime(date, time);
    return toUtc(localDateTime);
  }

  /// Convierte DateTime a TZDateTime usando la zona horaria local
  static tz.TZDateTime toTzDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Obtiene la fecha actual en UTC
  static DateTime nowUtc() {
    return DateTime.now().toUtc();
  }

  /// Obtiene la fecha actual en timezone local
  static tz.TZDateTime nowLocal() {
    return tz.TZDateTime.now(tz.local);
  }

  /// Formatea una fecha en español
  static String formatDate(DateTime date) {
    return _dateFormatEs.format(date);
  }

  /// Formatea una fecha y hora en español
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatEs.format(dateTime);
  }

  /// Formatea una hora en español
  static String formatTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Formatea un DateTime como hora en español
  static String formatTimeFromDateTime(DateTime dateTime) {
    return _timeFormatEs.format(dateTime);
  }

  /// Calcula la diferencia entre dos fechas en días
  static int daysDifference(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays;
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Verifica si una fecha es mañana
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
           date.month == tomorrow.month &&
           date.day == tomorrow.day;
  }

  /// Verifica si una fecha ya pasó
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Verifica si una fecha/hora combinada ya pasó
  static bool isPastWithTime(DateTime date, TimeOfDay time) {
    final dateTime = combineDateTime(date, time);
    return dateTime.isBefore(DateTime.now());
  }

  /// Obtiene el texto descriptivo de una fecha (hoy, mañana, fecha específica)
  static String getDateDescription(DateTime date) {
    if (isToday(date)) {
      return 'Hoy';
    } else if (isTomorrow(date)) {
      return 'Mañana';
    } else {
      final daysDiff = daysDifference(DateTime.now(), date);
      if (daysDiff > 0 && daysDiff <= 7) {
        return DateFormat('EEEE', 'es_ES').format(date);
      } else {
        return formatDate(date);
      }
    }
  }

  /// Obtiene el texto descriptivo de tiempo restante
  static String getTimeRemaining(DateTime targetDate, TimeOfDay targetTime) {
    final targetDateTime = combineDateTime(targetDate, targetTime);
    final now = DateTime.now();
    final difference = targetDateTime.difference(now);

    if (difference.isNegative) {
      final overdue = difference.abs();
      if (overdue.inDays > 0) {
        return 'Vencido por ${overdue.inDays} día${overdue.inDays > 1 ? 's' : ''}';
      } else if (overdue.inHours > 0) {
        return 'Vencido por ${overdue.inHours} hora${overdue.inHours > 1 ? 's' : ''}';
      } else {
        return 'Vencido por ${overdue.inMinutes} minuto${overdue.inMinutes > 1 ? 's' : ''}';
      }
    }

    if (difference.inDays > 0) {
      return 'En ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'En ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora';
    }
  }

  /// Convierte TimeOfDay a minutos desde medianoche
  static int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Convierte minutos desde medianoche a TimeOfDay
  static TimeOfDay minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  /// Obtiene información sobre la zona horaria actual
  static Map<String, dynamic> getTimezoneInfo() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final timezone = now.timeZoneName;
    
    return {
      'name': timezone,
      'offset': offset,
      'offsetString': _formatOffset(offset),
      'isDST': _isDaylightSavingTime(now),
    };
  }

  /// Formatea el offset de zona horaria
  static String _formatOffset(Duration offset) {
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes % 60).abs();
    final sign = offset.isNegative ? '-' : '+';
    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Determina si está en horario de verano (aproximado)
  static bool _isDaylightSavingTime(DateTime dateTime) {
    final now = DateTime.now();
    final january = DateTime(now.year, 1, 1);
    final july = DateTime(now.year, 7, 1);
    
    final januaryOffset = january.timeZoneOffset;
    final julyOffset = july.timeZoneOffset;
    
    // Si los offsets son diferentes, hay horario de verano
    if (januaryOffset != julyOffset) {
      final currentOffset = now.timeZoneOffset;
      // En el hemisferio norte, julio tiene horario de verano
      // En el hemisferio sur, enero tiene horario de verano
      return currentOffset != (januaryOffset.inMinutes > julyOffset.inMinutes ? januaryOffset : julyOffset);
    }
    
    return false;
  }
}
