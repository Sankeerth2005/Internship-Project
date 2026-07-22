import 'package:flutter/material.dart';
import '../data/models/business_models.dart';

class BusinessOperatingHours extends StatelessWidget {
  final List<DayHoursDto> hours;

  const BusinessOperatingHours({
    super.key,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) {
      return const Text(
        'Hours not registered',
        style: TextStyle(color: Color(0xFF9F9B96), fontSize: 13),
      );
    }

    return Column(
      children: hours.map((h) {
        final slotsStr = h.slots.map((s) => '${s.open} - ${s.close}').join(', ');
        final isClosed = h.mode.toLowerCase() == 'closed';
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAE8E3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _formatDays(h.day),
                  style: const TextStyle(
                    color: Color(0xFF1A1918),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                isClosed ? 'Closed' : (slotsStr.isNotEmpty ? _formatSlots(h.slots) : 'Open'),
                style: TextStyle(
                  color: isClosed ? const Color(0xFFE1251B) : const Color(0xFF1E824C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDays(String dayStr) {
    if (dayStr.contains(',')) {
      final days = dayStr.split(',');
      if (days.length == 7) return 'Everyday';
      if (days.length == 5 && days.contains('Monday') && days.contains('Friday')) {
        return 'Weekdays (Mon - Fri)';
      }
      if (days.length == 2 && days.contains('Saturday') && days.contains('Sunday')) {
        return 'Weekends (Sat - Sun)';
      }
      return days.map((d) => d.trim().substring(0, 3)).join(', ');
    }
    return dayStr;
  }

  String _formatSlots(List<SlotDto> slots) {
    return slots.map((s) {
      final open = _formatTime(s.open);
      final close = _formatTime(s.close);
      return '$open - $close';
    }).join(', ');
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMinute $period';
      }
    } catch (_) {}
    return timeStr;
  }
}
