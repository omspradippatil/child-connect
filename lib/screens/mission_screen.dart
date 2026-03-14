import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_data.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  Future<void> _refreshScreen() async {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        title: const Text('Our Mission'),
        actions: [
          IconButton(
            onPressed: _refreshScreen,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh mission',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              color: AppTheme.lightBlue,
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppTheme.accentBlue,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Child Connect is dedicated to ensuring every child receives the love, care, and opportunity they deserve. We connect children in need with compassionate families and communities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMedium,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What We Stand For',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...AppData.missionPoints.map(
                    (point) => _MissionCard(
                      title: point['title'] as String,
                      description: point['description'] as String,
                      icon: point['icon'] as IconData,
                      color: point['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Quote
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.lightOrange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: AppTheme.primaryOrange,
                          size: 36,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '"A child is not a distraction from more important work. They are the most important work."',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textDark,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _MissionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _expanded
              ? widget.color.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? widget.color.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: widget.color,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        widget.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.5,
                        ),
                      ),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 280),
                    firstCurve: Curves.easeOut,
                    secondCurve: Curves.easeInOutCubic,
                    sizeCurve: Curves.easeInOutCubic,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
