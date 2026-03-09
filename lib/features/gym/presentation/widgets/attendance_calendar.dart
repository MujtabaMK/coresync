import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceCalendar extends StatelessWidget {
  final Map<DateTime, bool> attendanceMap;
  final DateTime? membershipStartDate;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  const AttendanceCalendar({
    super.key,
    required this.attendanceMap,
    this.membershipStartDate,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium!,
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        outsideDaysVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final isPresent = attendanceMap[normalizedDate];

          // Explicitly marked in the map
          if (isPresent != null) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPresent ? Colors.green : Colors.red,
                ),
              ),
            );
          }

          // Auto-absent: within membership period, before today, not marked
          if (membershipStartDate != null) {
            final start = DateTime(
              membershipStartDate!.year,
              membershipStartDate!.month,
              membershipStartDate!.day,
            );
            final today = DateTime.now();
            final todayNormalized = DateTime(today.year, today.month, today.day);

            if (!normalizedDate.isBefore(start) &&
                normalizedDate.isBefore(todayNormalized)) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              );
            }
          }

          return null;
        },
      ),
    );
  }
}
