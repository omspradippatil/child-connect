import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_data.dart';
import '../widgets/child_card.dart';
import 'adoption_form_screen.dart';

class AdoptScreen extends StatefulWidget {
  const AdoptScreen({super.key});

  @override
  State<AdoptScreen> createState() => _AdoptScreenState();
}

class _AdoptScreenState extends State<AdoptScreen> {
  String _filter = 'All';

  final List<String> _filters = ['All', 'Boys', 'Girls', 'Favorites'];

  List<ChildProfile> get _filteredChildren {
    switch (_filter) {
      case 'Boys':
        return AppData.children.where((c) => c.icon == Icons.boy).toList();
      case 'Girls':
        return AppData.children.where((c) => c.icon == Icons.girl).toList();
      case 'Favorites':
        return AppData.children.where((c) => c.isFavorite).toList();
      default:
        return AppData.children;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        title: const Text('Adopt a Child'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.accentBlue),
            tooltip: 'Adoption Guide',
            onPressed: () {
              Navigator.of(context).pushNamed('/adoption-guide');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final bool selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppTheme.primaryOrange,
                      checkmarkColor: Colors.white,
                      backgroundColor: AppTheme.divider,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppTheme.textMedium,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Children list
          Expanded(
            child: _filteredChildren.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 56,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No favorites yet.\nTap the heart on any child!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: _filteredChildren.length,
                    itemBuilder: (ctx, i) {
                      final child = _filteredChildren[i];
                      return ChildCard(
                        child: child,
                        onFavoriteToggle: () {
                          setState(() {
                            child.isFavorite = !child.isFavorite;
                          });
                        },
                        onAdopt: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdoptionFormScreen(child: child),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
