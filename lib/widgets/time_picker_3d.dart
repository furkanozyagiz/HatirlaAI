import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- HELPER: GÜVENLİ TARİH KARŞILAŞTIRMASI ---
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// --- THEME EXTENSION ---
class HatirlaPickerTheme extends ThemeExtension<HatirlaPickerTheme> {
  final Color primaryColor,
      textColor,
      subtitleColor,
      capsuleColor,
      centerLineColor;
  const HatirlaPickerTheme({
    required this.primaryColor,
    required this.textColor,
    required this.subtitleColor,
    required this.capsuleColor,
    required this.centerLineColor,
  });

  static const defaultTheme = HatirlaPickerTheme(
    primaryColor: Color(0xFF6200EE),
    textColor: Colors.black,
    subtitleColor: Colors.grey,
    capsuleColor: Color(0x10000000),
    centerLineColor: Color(0xFF6200EE),
  );

  @override
  HatirlaPickerTheme copyWith({
    Color? primaryColor,
    Color? textColor,
    Color? subtitleColor,
    Color? capsuleColor,
    Color? centerLineColor,
  }) => HatirlaPickerTheme(
    primaryColor: primaryColor ?? this.primaryColor,
    textColor: textColor ?? this.textColor,
    subtitleColor: subtitleColor ?? this.subtitleColor,
    capsuleColor: capsuleColor ?? this.capsuleColor,
    centerLineColor: centerLineColor ?? this.centerLineColor,
  );

  @override
  HatirlaPickerTheme lerp(ThemeExtension<HatirlaPickerTheme>? other, double t) {
    if (other is! HatirlaPickerTheme) return this;
    return HatirlaPickerTheme(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      capsuleColor: Color.lerp(capsuleColor, other.capsuleColor, t)!,
      centerLineColor: Color.lerp(centerLineColor, other.centerLineColor, t)!,
    );
  }
}

class TimePicker3D extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onDateTimeChanged;
  final int minuteStep;

  const TimePicker3D({
    super.key,
    required this.initialDateTime,
    required this.onDateTimeChanged,
    this.minuteStep = 1,
  });

  @override
  State<TimePicker3D> createState() => _TimePicker3DState();
}

class _TimePicker3DState extends State<TimePicker3D> {
  static const int _baseIndex = 100000;
  late final DateTime _referenceDate;
  late final FixedExtentScrollController _dateController,
      _hourController,
      _minuteController;
  late DateTime _currentDateTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _referenceDate = DateTime(now.year, now.month, now.day);
    _currentDateTime = widget.initialDateTime;

    _dateController = FixedExtentScrollController(
      initialItem:
          _baseIndex + _currentDateTime.difference(_referenceDate).inDays,
    );
    _hourController = FixedExtentScrollController(
      initialItem: _baseIndex + _currentDateTime.hour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _baseIndex + (_currentDateTime.minute ~/ widget.minuteStep),
    );
  }

  @override
  void dispose() {
    //
    _dateController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    final targetDate = _referenceDate.add(
      Duration(days: _dateController.selectedItem - _baseIndex),
    );
    setState(() {
      _currentDateTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        _hourController.selectedItem % 24,
        (_minuteController.selectedItem % (60 ~/ widget.minuteStep)) *
            widget.minuteStep,
      );
    });
  }

  // Güvenli karşılaştırma ile etiketleme
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (isSameDay(date, today)) return "🟢 Bugün";
    if (isSameDay(date, tomorrow)) return "🌙 Yarın";
    return "📅 ${DateFormat('d MMMM', 'tr_TR').format(date)}";
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<HatirlaPickerTheme>() ??
        HatirlaPickerTheme.defaultTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Text(
              _currentDateTime.hour < 12 ? "🌅 Sabah" : "🌆 Akşam",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            Text(
              "${_currentDateTime.hour.toString().padLeft(2, '0')}:${_currentDateTime.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: theme.textColor,
              ),
            ),
            Text(
              _getDateLabel(_currentDateTime),
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildCapsule(theme),
              Row(
                children: [
                  _buildWheel(
                    _dateController,
                    (i) => DateFormat('d MMM', 'tr_TR').format(
                      _referenceDate.add(Duration(days: i - _baseIndex)),
                    ),
                    theme,
                    "Tarih",
                  ),
                  _buildWheel(
                    _hourController,
                    (i) => (i % 24).toString().padLeft(2, '0'),
                    theme,
                    "Saat",
                  ),
                  _buildWheel(
                    _minuteController,
                    (i) => ((i % (60 ~/ widget.minuteStep)) * widget.minuteStep)
                        .toString()
                        .padLeft(2, '0'),
                    theme,
                    "Dakika",
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            widget.onDateTimeChanged(_currentDateTime);
            Navigator.pop(context);
          },
          child: const Text("Onayla"),
        ),
      ],
    );
  }

  Widget _buildWheel(
    FixedExtentScrollController controller,
    String Function(int) format,
    HatirlaPickerTheme theme,
    String label,
  ) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 60,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (_) {
          _update();
          // Özelleştirilmiş Haptic Feedback
          if (label == "Tarih")
            HapticFeedback.mediumImpact();
          else if (label == "Saat")
            HapticFeedback.selectionClick();
          else if (label == "Dakika")
            HapticFeedback.lightImpact();
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 200000,
          builder: (context, i) {
            final distanceFromCenter = controller.hasClients
                ? (controller.selectedItem - i).abs()
                : 10;
            return Semantics(
              label: "$label: ${format(i)}",
              child: Center(
                child: Text(
                  format(i),
                  style: TextStyle(
                    fontSize: (distanceFromCenter == 0) ? 24 : 18,
                    fontWeight: (distanceFromCenter == 0)
                        ? FontWeight.w900
                        : FontWeight.w400,
                    color: (distanceFromCenter == 0)
                        ? theme.primaryColor
                        : theme.textColor.withOpacity(0.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCapsule(HatirlaPickerTheme theme) => Container(
    height: 60,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: theme.capsuleColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
    ),
    child: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(),
      ),
    ),
  );
}
