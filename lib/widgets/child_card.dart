import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/app_data.dart';

class ChildCard extends StatefulWidget {
  final ChildProfile child;
  final VoidCallback onAdopt;
  final VoidCallback onFavoriteToggle;

  const ChildCard({
    super.key,
    required this.child,
    required this.onAdopt,
    required this.onFavoriteToggle,
  });

  @override
  State<ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<ChildCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _onHeartTap() {
    HapticFeedback.lightImpact();
    _heartCtrl.forward(from: 0.0);
    widget.onFavoriteToggle();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image fallback to icon avatar if no image URL is available.
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: child.imageUrl.trim().isNotEmpty
                      ? Image.network(
                          child.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, _) => Container(
                            color: child.avatarColor,
                            child: Icon(
                              child.icon,
                              size: 44,
                              color: AppTheme.textDark.withValues(alpha: 0.55),
                            ),
                          ),
                        )
                      : Container(
                          color: child.avatarColor,
                          child: Icon(
                            child.icon,
                            size: 44,
                            color: AppTheme.textDark.withValues(alpha: 0.55),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        // Animated heart
                        GestureDetector(
                          onTap: _onHeartTap,
                          child: AnimatedBuilder(
                            animation: _heartScale,
                            builder: (context, _) => Transform.scale(
                              scale: _heartScale.value,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  child.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  key: ValueKey(child.isFavorite),
                                  color: child.isFavorite
                                      ? AppTheme.heartRed
                                      : AppTheme.textLight,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Age + location row
                    Row(
                      children: [
                        // Age badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${child.age} yrs',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            child.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      child.story,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (child.interests.trim().isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Activities: ${child.interests}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onAdopt,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Adopt'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
