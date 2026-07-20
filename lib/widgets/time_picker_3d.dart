import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// 1. CONFIGURATION & CONSTANTS (Huawei Pura 80 Ultra Camera Optics)
/// ============================================================================
class HuaweiCameraConfig {
  static const double pixelsPerMinute = 8.0;
  static const double rulerHeight = 130.0;

  // Geniş Sanal Aralık (Sonsuz Kaydırma Hissi İçin)
  static const int totalVirtualMinutes = 365 * 24 * 60 * 100;
  static const int centerMinuteIndex = totalVirtualMinutes ~/ 2;

  const HuaweiCameraConfig._();
}

/// ============================================================================
/// 2. CUSTOM SCROLL PHYSICS (ScrollSpringSimulation ve tolerance kaldirildi)
/// ============================================================================
class HuaweiCameraScrollPhysics extends ScrollPhysics {
  const HuaweiCameraScrollPhysics({super.parent});

  @override
  HuaweiCameraScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HuaweiCameraScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity == 0.0) ||
        (velocity > 0 && position.pixels >= position.maxScrollExtent) ||
        (velocity < 0 && position.pixels <= position.minScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double projectedPixels = position.pixels + (velocity * 0.16);
    final double nearestSnap =
        (projectedPixels / HuaweiCameraConfig.pixelsPerMinute).round() *
        HuaweiCameraConfig.pixelsPerMinute;

    return ScrollSpringSimulation(
      const SpringDescription(mass: 32.0, stiffness: 210.0, damping: 26.0),
      position.pixels,
      nearestSnap,
      velocity,
    );
  }
}

/// ============================================================================
/// 3. TIME UTILITY & FORMATTER
/// ============================================================================
class HuaweiTimeFormatter {
  static String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    if (target == today) return '🟢 Bugün';
    final tomorrow = today.add(const Duration(days: 1));
    if (target == tomorrow) return '🌙 Yarın';

    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '📅 ${dt.day} ${months[dt.month]}';
  }

  static String getTimeContext(int hour) {
    if (hour >= 5 && hour < 12) return '🌅 Sabah';
    if (hour >= 12 && hour < 18) return '☀️ Öğle';
    if (hour >= 18 && hour < 22) return '🌆 Akşam';
    return '🌙 Gece';
  }
}

/// ============================================================================
/// 4. CUSTOM PAINTER: ORGANIC TIERED TICKS, GAUSSIAN SCALE & GHOST TRAIL
/// ============================================================================
class HuaweiRulerPainter extends CustomPainter {
  final double scrollOffset;
  final Color primaryColor;
  final Color textColor;
  final DateTime baseDateTime;
  final double velocity;

  static final Map<String, ui.Paragraph> _textCache = {};
  static const int _maxCacheSize = 180;

  HuaweiRulerPainter({
    required this.scrollOffset,
    required this.primaryColor,
    required this.textColor,
    required this.baseDateTime,
    required this.velocity,
  });

  @override
  bool shouldRepaint(covariant HuaweiRulerPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.velocity != velocity;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final Paint paint = Paint()..strokeCap = StrokeCap.round;

    final double startX = scrollOffset;
    final double endX = scrollOffset + size.width;

    final int startMinute = (startX / HuaweiCameraConfig.pixelsPerMinute)
        .floor();
    final int endMinute = (endX / HuaweiCameraConfig.pixelsPerMinute).ceil();

    final double blurIntensity = (velocity.abs() / 3000.0).clamp(0.0, 1.0);

    for (int i = startMinute; i <= endMinute; i++) {
      final double x = (i * HuaweiCameraConfig.pixelsPerMinute) - scrollOffset;
      final double distanceFromCenter = (x - centerX).abs();

      // Gaussian Bell Curve Lens Magnification (Zoom ve Scale)
      final double lensFactor = math.exp(
        -math.pow(distanceFromCenter / (size.width * 0.32), 2.0),
      );
      final double scale = 0.5 + (lensFactor * 0.5);
      final double opacity = 0.2 + (lensFactor * 0.8);

      final int minuteAbsolute = i - HuaweiCameraConfig.centerMinuteIndex;
      final DateTime tickTime = baseDateTime.add(
        Duration(minutes: minuteAbsolute),
      );

      final int minuteOfHour = tickTime.minute;
      final bool isHour = minuteOfHour == 0;
      final bool isHalfHour = minuteOfHour == 30;
      final bool isFifteenMin = minuteOfHour % 15 == 0;
      final bool isFiveMin = minuteOfHour % 5 == 0;

      double heightMultiplier;
      if (isHour) {
        heightMultiplier = 1.0;
      } else if (isHalfHour) {
        heightMultiplier = 0.82;
      } else if (isFifteenMin) {
        heightMultiplier = 0.68;
      } else if (isFiveMin) {
        heightMultiplier = 0.52;
      } else {
        heightMultiplier = 0.32;
      }

      final double height = 56.0 * heightMultiplier * scale;
      final double strokeWidth =
          (isHour ? 2.2 : (isFiveMin ? 1.4 : 0.8)) * scale;

      Color color;
      if (isHour) {
        color = primaryColor.withValues(alpha: (opacity * 1.0).clamp(0.0, 1.0));
      } else if (isFiveMin) {
        color = textColor.withValues(alpha: (opacity * 0.85).clamp(0.0, 1.0));
      } else {
        color = textColor.withValues(alpha: (opacity * 0.38).clamp(0.0, 1.0));
      }

      paint.color = color;
      paint.strokeWidth = strokeWidth;

      final double centerY = size.height / 2;

      // Motion Blur / Ghost Trail
      if (blurIntensity > 0.04) {
        const int blurSteps = 3;
        final double blurStepSize = (velocity * 0.0018).clamp(-6.0, 6.0);
        for (int b = 1; b <= blurSteps; b++) {
          final double ghostX = x - (blurStepSize * b / blurSteps);
          final double ghostAlpha =
              (opacity * (1.0 - (b / 4.0)) * blurIntensity * 0.4).clamp(
                0.0,
                1.0,
              );
          final Paint ghostPaint = Paint()
            ..color = color.withValues(alpha: ghostAlpha)
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(ghostX, centerY - height / 2),
            Offset(ghostX, centerY + height / 2),
            ghostPaint,
          );
        }
      }

      // Ana Cetvel Çizgisi
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );

      // Paragraph Cache ile Saat Etiketleri
      if (isHour && scale > 0.72) {
        final String hourText =
            '${tickTime.hour.toString().padLeft(2, '0')}:00';
        final String cacheKey = '$hourText-${scale.toStringAsFixed(2)}';

        if (!_textCache.containsKey(cacheKey)) {
          if (_textCache.length >= _maxCacheSize) {
            _textCache.clear();
          }
          final double textAlpha = (opacity * 0.95).clamp(0.0, 1.0);
          final builder =
              ui.ParagraphBuilder(
                  ui.ParagraphStyle(
                    textAlign: TextAlign.center,
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w700,
                    textDirection: ui.TextDirection.ltr,
                  ),
                )
                ..pushStyle(
                  ui.TextStyle(color: textColor.withValues(alpha: textAlpha)),
                )
                ..addText(hourText);
          final paragraph = builder.build()
            ..layout(const ui.ParagraphConstraints(width: 80));
          _textCache[cacheKey] = paragraph;
        }

        final paragraph = _textCache[cacheKey]!;
        canvas.drawParagraph(
          paragraph,
          Offset(x - 40, centerY - height / 2 - 22),
        );
      }
    }
  }
}

/// ============================================================================
/// 5. CENTER INDICATOR (KIRMIZI GÖSTERGE VE ui.ImageFilter)
/// ============================================================================
class HuaweiCenterIndicator extends StatelessWidget {
  const HuaweiCenterIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    const Color indicatorColor = Colors.red;

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 44,
                height: HuaweiCameraConfig.rulerHeight,
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: indicatorColor.withValues(alpha: 0.45),
                    width: 1.25,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 3.2,
            height: 64,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(1.6),
              boxShadow: [
                BoxShadow(
                  color: indicatorColor.withValues(alpha: 0.75),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 6. HEADER WIDGET
/// ============================================================================
class HuaweiTimeHeader extends StatelessWidget {
  final DateTime currentDateTime;
  final Color primaryColor;
  final Color textColor;

  const HuaweiTimeHeader({
    super.key,
    required this.currentDateTime,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = HuaweiTimeFormatter.formatTime(currentDateTime);
    final dateString = HuaweiTimeFormatter.formatDate(currentDateTime);
    final contextString = HuaweiTimeFormatter.getTimeContext(
      currentDateTime.hour,
    );

    return Semantics(
      label: 'Seçilen zaman: $contextString, Saat $timeString, $dateString',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              contextString,
              key: ValueKey(contextString),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              timeString,
              key: ValueKey(timeString),
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              dateString,
              key: ValueKey(dateString),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 7. MAIN TIME PICKER 3D WIDGET
/// ============================================================================
class TimePicker3D extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onDateTimeChanged;

  const TimePicker3D({
    super.key,
    required this.initialDateTime,
    required this.onDateTimeChanged,
  });

  @override
  State<TimePicker3D> createState() => _TimePicker3DState();
}

class _TimePicker3DState extends State<TimePicker3D> {
  late final ScrollController _scrollController;
  late final DateTime _baseDateTime;

  double _currentVelocity = 0.0;
  int _lastHapticMinute = -1;
  double _lastOffset = 0.0;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;

    final now = DateTime.now();
    _baseDateTime = DateTime(now.year, now.month, now.day);

    final initialMinuteDiff = _selectedDateTime
        .difference(_baseDateTime)
        .inMinutes;
    final initialOffset =
        (HuaweiCameraConfig.centerMinuteIndex + initialMinuteDiff) *
        HuaweiCameraConfig.pixelsPerMinute;

    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _lastOffset = initialOffset;
    _scrollController.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollNotification);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollNotification() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastOffset;

    _currentVelocity = delta * 60.0;
    _lastOffset = currentOffset;

    final pixelIndex = (currentOffset / HuaweiCameraConfig.pixelsPerMinute)
        .round();
    final minuteAbsolute = pixelIndex - HuaweiCameraConfig.centerMinuteIndex;
    final updatedTime = _baseDateTime.add(Duration(minutes: minuteAbsolute));

    if (updatedTime != _selectedDateTime) {
      setState(() {
        _selectedDateTime = updatedTime;
      });
      widget.onDateTimeChanged(_selectedDateTime);

      if (updatedTime.minute != _lastHapticMinute) {
        _lastHapticMinute = updatedTime.minute;
        if (updatedTime.minute == 0) {
          HapticFeedback.mediumImpact();
        } else if (updatedTime.minute % 5 == 0) {
          HapticFeedback.selectionClick();
        } else {
          HapticFeedback.lightImpact();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.45 : 0.08,
            ),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HuaweiTimeHeader(
            currentDateTime: _selectedDateTime,
            primaryColor: primaryColor,
            textColor: textColor,
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final rulerWidth = constraints.maxWidth;
              return SizedBox(
                height: HuaweiCameraConfig.rulerHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Scrollable(
                      controller: _scrollController,
                      physics: const HuaweiCameraScrollPhysics(),
                      axisDirection: AxisDirection.right,
                      viewportBuilder: (context, position) {
                        return Viewport(
                          offset: position,
                          axisDirection: AxisDirection.right,
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(
                                width:
                                    HuaweiCameraConfig.totalVirtualMinutes *
                                    HuaweiCameraConfig.pixelsPerMinute,
                                height: HuaweiCameraConfig.rulerHeight,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.12, 0.5, 0.88, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          return RepaintBoundary(
                            child: CustomPaint(
                              size: Size(
                                rulerWidth,
                                HuaweiCameraConfig.rulerHeight,
                              ),
                              painter: HuaweiRulerPainter(
                                scrollOffset: _scrollController.hasClients
                                    ? _scrollController.offset -
                                          (rulerWidth / 2)
                                    : 0.0,
                                primaryColor: primaryColor,
                                textColor: textColor,
                                baseDateTime: _baseDateTime,
                                velocity: _currentVelocity,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const HuaweiCenterIndicator(),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                widget.onDateTimeChanged(_selectedDateTime);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Onayla',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 8. EXAMPLE USAGE WIDGET
/// ============================================================================
class TimePickerExample extends StatelessWidget {
  const TimePickerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HatırlaAI - Huawei TimePicker3D Örneği'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TimePicker3D(
                    initialDateTime: DateTime.now(),
                    onDateTimeChanged: (selectedTime) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Seçilen Zaman: ${HuaweiTimeFormatter.formatTime(selectedTime)}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          child: const Text('Zaman Seçicisini Aç'),
        ),
      ),
    );
  }
}
