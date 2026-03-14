import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class ParentFeedbackScreen extends StatefulWidget {
  const ParentFeedbackScreen({super.key});

  @override
  State<ParentFeedbackScreen> createState() => _ParentFeedbackScreenState();
}

class _ParentFeedbackScreenState extends State<ParentFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentNamesCtrl = TextEditingController();
  final _storyTitleCtrl = TextEditingController();
  final _storyBodyCtrl = TextEditingController();
  final _childNameCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _confirmAdopted = false;
  bool _acceptTerms = false;
  bool _showShareForm = false;
  Set<String> _likingIds = <String>{};
  List<_ParentFeedback> _stories = [];

  String get _sessionToken => AuthService.currentUser?.sessionToken ?? '';

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _parentNamesCtrl.dispose();
    _storyTitleCtrl.dispose();
    _storyBodyCtrl.dispose();
    _childNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'app_get_parent_feedback',
        params: {
          'p_session_token': _sessionToken.isEmpty ? null : _sessionToken,
        },
      );

      final rows = (response as List? ?? const [])
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .map(_ParentFeedback.fromMap)
          .toList();

      rows.sort((a, b) {
        final likesDiff = b.likeCount.compareTo(a.likeCount);
        if (likesDiff != 0) {
          return likesDiff;
        }
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

      if (!mounted) {
        return;
      }
      setState(() {
        _stories = rows;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to load parent feedback. $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _submitStory() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (!_confirmAdopted) {
      _showSnack('Please confirm this is from a completed adoption journey.');
      return;
    }

    if (!_acceptTerms) {
      _showSnack('Please accept the terms and conditions to continue.');
      return;
    }

    if (_sessionToken.isEmpty) {
      _showSnack('Please sign in again to submit your story.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await Supabase.instance.client.rpc(
        'app_submit_parent_feedback',
        params: {
          'p_session_token': _sessionToken,
          'p_parent_names': _parentNamesCtrl.text.trim(),
          'p_story_title': _storyTitleCtrl.text.trim(),
          'p_story_body': _storyBodyCtrl.text.trim(),
          'p_child_name': _childNameCtrl.text.trim(),
          'p_confirm_adopted': _confirmAdopted,
          'p_accept_terms': _acceptTerms,
        },
      );

      _parentNamesCtrl.clear();
      _storyTitleCtrl.clear();
      _storyBodyCtrl.clear();
      _childNameCtrl.clear();

      setState(() {
        _confirmAdopted = false;
        _acceptTerms = false;
        _showShareForm = false;
      });

      _showSnack('Thank you. Your story has been shared.');
      await _loadStories();
    } on PostgrestException catch (error) {
      _showSnack(error.message);
    } catch (error) {
      _showSnack('Failed to submit your story. $error');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _toggleLike(_ParentFeedback story) async {
    if (_sessionToken.isEmpty) {
      _showSnack('Please sign in to like stories.');
      return;
    }

    if (_likingIds.contains(story.id)) {
      return;
    }

    setState(() {
      _likingIds = {..._likingIds, story.id};
    });

    try {
      final response = await Supabase.instance.client.rpc(
        'app_toggle_parent_feedback_like',
        params: {'p_session_token': _sessionToken, 'p_feedback_id': story.id},
      );

      final payload = Map<String, dynamic>.from(response as Map);
      final updated = story.copyWith(
        likeCount: (payload['like_count'] as num?)?.toInt() ?? story.likeCount,
        likedByMe: payload['liked'] == true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stories =
            _stories
                .map((item) => item.id == story.id ? updated : item)
                .toList()
              ..sort((a, b) {
                final likesDiff = b.likeCount.compareTo(a.likeCount);
                if (likesDiff != 0) {
                  return likesDiff;
                }
                final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
                final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
                return bTime.compareTo(aTime);
              });
      });
    } on PostgrestException catch (error) {
      _showSnack(error.message);
    } catch (error) {
      _showSnack('Failed to update like. $error');
    } finally {
      if (mounted) {
        setState(() {
          _likingIds = _likingIds.where((id) => id != story.id).toSet();
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title: const Text('Parents Stories'),
        actions: [
          IconButton(
            onPressed: _loadStories,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh stories',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStories,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD8C2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Child Connect is only a digital medium and interface between NGOs and parents who want to adopt. Placement, legal verification, and final approvals are performed only by authorized agencies and legal authorities.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMedium,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Share your adoption story',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showShareForm = !_showShareForm;
                          });
                        },
                        icon: Icon(
                          _showShareForm
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.edit_note_rounded,
                        ),
                        label: Text(_showShareForm ? 'Hide' : 'Write Story'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Only families with completed adoptions should submit stories.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
                  ),
                  if (_showShareForm) ...[
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _parentNamesCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Parent names',
                              hintText: 'Example: Rajesh and Meena',
                            ),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.length < 3) {
                                return 'Please enter parent names';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _storyTitleCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Story title',
                              hintText: 'A short title for your journey',
                            ),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.length < 5) {
                                return 'Please add a title (min 5 chars)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _childNameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Child name (optional)',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _storyBodyCtrl,
                            minLines: 5,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Your story',
                              hintText:
                                  'Share your experience to help other parents.',
                            ),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.length < 50) {
                                return 'Please write at least 50 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _confirmAdopted,
                            onChanged: (value) {
                              setState(() {
                                _confirmAdopted = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'I confirm this story is from a completed adoption journey.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                          CheckboxListTile(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'I accept that Child Connect is only a medium/interface between NGOs and parents.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submitStory,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(
                                _submitting ? 'Submitting...' : 'Submit Story',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Adoptive Parents Feedback',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Most liked first',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _loadStories)
            else if (_stories.isEmpty)
              const _EmptyState()
            else
              ..._stories.map(
                (story) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StoryCard(
                    story: story,
                    liking: _likingIds.contains(story.id),
                    onLike: () => _toggleLike(story),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.onLike,
    required this.liking,
  });

  final _ParentFeedback story;
  final VoidCallback onLike;
  final bool liking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFF0E7),
                child: Text(
                  story.initials,
                  style: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.parentNames,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (story.childName.isNotEmpty)
                      Text(
                        'Child: ${story.childName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                story.timeLabel,
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            story.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            story.story,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: liking ? null : onLike,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: story.likedByMe
                        ? const Color(0xFFFFE9E9)
                        : const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: story.likedByMe
                          ? const Color(0xFFFFCACA)
                          : AppTheme.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (liking)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          story.likedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: story.likedByMe
                              ? AppTheme.heartRed
                              : AppTheme.textMedium,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        '${story.likeCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: story.likedByMe
                              ? AppTheme.heartRed
                              : AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Helpful to other parents',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.forum_outlined, size: 42, color: AppTheme.textLight),
          SizedBox(height: 10),
          Text(
            'No parent stories yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Be the first adoptive parent to share your journey.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: AppTheme.textMedium)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ParentFeedback {
  const _ParentFeedback({
    required this.id,
    required this.parentNames,
    required this.title,
    required this.story,
    required this.childName,
    required this.likeCount,
    required this.likedByMe,
    required this.createdAt,
  });

  final String id;
  final String parentNames;
  final String title;
  final String story;
  final String childName;
  final int likeCount;
  final bool likedByMe;
  final DateTime? createdAt;

  String get initials {
    final parts = parentNames.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'P';
    }
    final first = parts.first.characters.first;
    final second = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1].characters.first
        : '';
    return '$first$second'.toUpperCase();
  }

  String get timeLabel {
    if (createdAt == null) {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays}d ago';
    }
    final months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }

  _ParentFeedback copyWith({int? likeCount, bool? likedByMe}) {
    return _ParentFeedback(
      id: id,
      parentNames: parentNames,
      title: title,
      story: story,
      childName: childName,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      createdAt: createdAt,
    );
  }

  factory _ParentFeedback.fromMap(Map<String, dynamic> map) {
    return _ParentFeedback(
      id: (map['id'] ?? '').toString(),
      parentNames: (map['parent_names'] ?? '').toString(),
      title: (map['story_title'] ?? '').toString(),
      story: (map['story_body'] ?? '').toString(),
      childName: (map['child_name'] ?? '').toString(),
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: map['liked_by_me'] == true,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }
}
