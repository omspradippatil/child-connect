import 'package:flutter/material.dart';
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

class _ChildCardState extends State<ChildCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.child.avatarColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.child.icon,
                size: 44,
                color: AppTheme.textDark.withValues(alpha: 0.6),
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
                        widget.child.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onFavoriteToggle();
                        },
                        child: Icon(
                          widget.child.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.child.isFavorite
                              ? AppTheme.heartRed
                              : AppTheme.textLight,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        size: 13,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.child.age} years old',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.child.location,
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
                    widget.child.story,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
    );
  }
}
