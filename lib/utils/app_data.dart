import 'package:flutter/material.dart';

class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String location;
  final String story;
  final IconData icon;
  final Color avatarColor;
  bool isFavorite;

  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.story,
    required this.icon,
    required this.avatarColor,
    this.isFavorite = false,
  });
}

class AppData {
  static List<ChildProfile> children = [
    ChildProfile(
      id: '1',
      name: 'Arjun',
      age: 5,
      location: 'Mumbai, Maharashtra',
      story: 'Arjun loves painting and dreams of becoming an artist someday.',
      icon: Icons.boy,
      avatarColor: const Color(0xFFFFD8B4),
    ),
    ChildProfile(
      id: '2',
      name: 'Priya',
      age: 7,
      location: 'Pune, Maharashtra',
      story: 'Priya is a cheerful girl who loves books and storytelling.',
      icon: Icons.girl,
      avatarColor: const Color(0xFFFFB3C6),
    ),
    ChildProfile(
      id: '3',
      name: 'Ravi',
      age: 4,
      location: 'Delhi',
      story: 'Ravi enjoys playing football and making new friends.',
      icon: Icons.boy,
      avatarColor: const Color(0xFFB3E5FC),
    ),
    ChildProfile(
      id: '4',
      name: 'Ananya',
      age: 8,
      location: 'Bengaluru, Karnataka',
      story: 'Ananya is curious and loves learning about science and nature.',
      icon: Icons.girl,
      avatarColor: const Color(0xFFC8E6C9),
    ),
    ChildProfile(
      id: '5',
      name: 'Kabir',
      age: 6,
      location: 'Jaipur, Rajasthan',
      story: 'Kabir loves music and plays the tabla at his shelter home.',
      icon: Icons.boy,
      avatarColor: const Color(0xFFE1BEE7),
    ),
    ChildProfile(
      id: '6',
      name: 'Diya',
      age: 9,
      location: 'Chennai, Tamil Nadu',
      story: 'Diya is a bright student who wants to be a doctor one day.',
      icon: Icons.girl,
      avatarColor: const Color(0xFFFFF9C4),
    ),
  ];

  static const List<Map<String, dynamic>> programs = [
    {
      'title': 'Art & Creativity',
      'description':
          'Encouraging children to express themselves through drawing, painting, and craft activities that build confidence and imagination.',
      'icon': Icons.palette,
      'color': Color(0xFFFF8C42),
    },
    {
      'title': 'Sensory & Motor Skills',
      'description':
          'Activities designed to strengthen fine and gross motor skills through play-based learning and sensory exploration.',
      'icon': Icons.sports_handball,
      'color': Color(0xFF4FA8D5),
    },
    {
      'title': 'Social & Emotional Learning',
      'description':
          'Programs focused on building empathy, healthy relationships, and emotional resilience in young minds.',
      'icon': Icons.people,
      'color': Color(0xFFE94F6A),
    },
    {
      'title': 'Literacy & Storytelling',
      'description':
          'Reading circles and storytelling sessions that nurture a love of language and improve communication skills.',
      'icon': Icons.menu_book,
      'color': Color(0xFF4CAF7D),
    },
    {
      'title': 'Physical Activities',
      'description':
          'Structured outdoor play, yoga, and sports activities that promote physical fitness and teamwork.',
      'icon': Icons.directions_run,
      'color': Color(0xFF9C6FDE),
    },
  ];

  static const List<Map<String, dynamic>> missionPoints = [
    {
      'title': 'Safe & Loving Homes',
      'description':
          'We work tirelessly to match every child with caring families who provide a secure and nurturing environment.',
      'icon': Icons.home_rounded,
      'color': Color(0xFFFF8C42),
    },
    {
      'title': 'Education Support',
      'description':
          'Every child deserves quality education. We fund schooling, tutoring, and skill-building programs.',
      'icon': Icons.school_rounded,
      'color': Color(0xFF4FA8D5),
    },
    {
      'title': 'Emotional Wellbeing',
      'description':
          'Providing counseling, therapy, and peer support to help children heal and thrive emotionally.',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFE94F6A),
    },
    {
      'title': 'Community Help',
      'description':
          'Building strong community networks of volunteers, mentors, and donors who stand for every child.',
      'icon': Icons.handshake_rounded,
      'color': Color(0xFF4CAF7D),
    },
  ];

  static const List<Map<String, dynamic>> adoptionSteps = [
    {
      'step': '01',
      'title': 'Initial Enquiry',
      'description':
          'Fill out the adoption enquiry form and our team will contact you within 48 hours.',
    },
    {
      'step': '02',
      'title': 'Eligibility Check',
      'description':
          'We review your application based on age, financial stability, and home environment.',
    },
    {
      'step': '03',
      'title': 'Home Study',
      'description':
          'A social worker visits your home to assess stability and suitability for a child.',
    },
    {
      'step': '04',
      'title': 'Child Matching',
      'description':
          'Based on your profile, we identify a compatible child and arrange a meeting.',
    },
    {
      'step': '05',
      'title': 'Court Approval',
      'description':
          'Legal proceedings are completed under the Juvenile Justice Act for formal adoption.',
    },
    {
      'step': '06',
      'title': 'Welcome Home',
      'description':
          'The child is placed with your family and we provide 12-month post-adoption support.',
    },
  ];
}
