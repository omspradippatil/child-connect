import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_data.dart';
import '../widgets/feature_card.dart';
import 'adopt_screen.dart';
import 'mission_screen.dart';
import 'programs_screen.dart';
import 'mentor_screen.dart';
import 'contact_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: CustomScrollView(
        slivers: [
          // Header Banner
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
              decoration: const BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.child_care,
                          color: AppTheme.primaryOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Child Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Together We Give\nChildren a Future',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Every child deserves a loving home.\nBe the change.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _statBadge('${AppData.children.length}+', 'Children'),
                      const SizedBox(width: 12),
                      _statBadge('120+', 'Families'),
                      const SizedBox(width: 12),
                      _statBadge('${AppData.programs.length}', 'Programs'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Section title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'What We Offer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Main cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FeatureCard(
                  title: 'Adopt a Child',
                  subtitle: 'Browse profiles and start your adoption journey',
                  icon: Icons.favorite_rounded,
                  color: AppTheme.primaryOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdoptScreen()),
                  ),
                ),
                FeatureCard(
                  title: 'Our Mission',
                  subtitle: 'Safe homes, education & emotional wellbeing',
                  icon: Icons.flag_rounded,
                  color: AppTheme.accentBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MissionScreen()),
                  ),
                ),
                FeatureCard(
                  title: 'Child Development Programs',
                  subtitle: 'Art, literacy, motor skills and more',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF9C6FDE),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgramsScreen()),
                  ),
                ),
                FeatureCard(
                  title: 'Become a Mentor',
                  subtitle: 'Share your skills and guide a child',
                  icon: Icons.handshake_rounded,
                  color: AppTheme.successGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MentorScreen()),
                  ),
                ),
                FeatureCard(
                  title: 'Contact Us',
                  subtitle: 'Have questions? We\'re here to help.',
                  icon: Icons.mail_rounded,
                  color: const Color(0xFFE94F6A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactScreen()),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
