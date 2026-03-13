import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_theme.dart';
import '../utils/app_data.dart';
import '../widgets/child_card.dart';
import 'adoption_guide_screen.dart';
import 'adoption_form_screen.dart';

class AdoptScreen extends StatefulWidget {
  const AdoptScreen({super.key});

  @override
  State<AdoptScreen> createState() => _AdoptScreenState();
}

class _AdoptScreenState extends State<AdoptScreen> {
  String _filter = 'All';
  bool _loading = true;
  String? _error;
  List<ChildProfile> _children = [];
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<String> _filters = ['All', 'Boys', 'Girls', 'Favorites'];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.rpc(
        'app_get_public_children',
      );
      final raw = response as List? ?? const [];

      final loaded = raw.map((entry) {
        final row = Map<String, dynamic>.from(entry as Map);
        final gender = (row['gender'] ?? 'other').toString().toLowerCase();

        return ChildProfile(
          id: row['id'].toString(),
          name: (row['name'] ?? '').toString(),
          age: (row['age'] as num?)?.toInt() ?? 1,
          location: (row['location'] ?? '').toString(),
          story: (row['story'] ?? '').toString(),
          icon: gender == 'boy'
              ? Icons.boy
              : gender == 'girl'
              ? Icons.girl
              : Icons.child_care,
          avatarColor: _parseColor(
            (row['avatar_color_hex'] ?? '#FFD8B4').toString(),
          ),
        );
      }).toList();

      setState(() => _children = loaded);
    } on PostgrestException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'Failed to load children. $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _parseColor(String hex) {
    var value = hex.trim().replaceFirst('#', '');
    if (value.length == 6) {
      value = 'FF$value';
    }
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? const Color(0xFFFFD8B4) : Color(parsed);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ChildProfile> get _filteredChildren {
    List<ChildProfile> base;
    switch (_filter) {
      case 'Boys':
        base = _children.where((c) => c.icon == Icons.boy).toList();
        break;
      case 'Girls':
        base = _children.where((c) => c.icon == Icons.girl).toList();
        break;
      case 'Favorites':
        base = _children.where((c) => c.isFavorite).toList();
        break;
      default:
        base = _children;
    }
    if (_query.isEmpty) return base;
    final q = _query.toLowerCase();
    return base
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q),
        )
        .toList();
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdoptionGuideScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name or city...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filter chips + count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
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
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textMedium,
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
                if (!_loading && _error == null)
                  Text(
                    '${_filteredChildren.length} found',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
          // Children list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textMedium),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadChildren,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filteredChildren.isEmpty
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
