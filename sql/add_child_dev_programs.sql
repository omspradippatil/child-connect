-- Adds/updates the six Child Development Programs shown in the design.
-- Run this in Supabase SQL editor.

begin;

alter table if exists public.program_catalog
add column if not exists image_url text;

delete from public.program_catalog
where title in (
  'Art & Creativity',
  'Sensory & Motor Skills',
  'Social & Emotional Learning',
  'Physical Wellness & Play',
  'Literacy & Storytelling',
  'Life Skills & Independence'
);

insert into public.program_catalog (
  title,
  description,
  icon_key,
  image_url,
  color_hex,
  is_active,
  display_order
)
values
  (
    'Art & Creativity',
    'Encouraging self-expression through drawing, painting, and crafts, helping children develop confidence and imagination.',
    'palette',
    'https://images.pexels.com/photos/8613089/pexels-photo-8613089.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#FF8C42',
    true,
    1
  ),
  (
    'Sensory & Motor Skills',
    'Hands-on activities like building blocks and puzzles to enhance cognitive development and fine motor skills.',
    'sports',
    'https://images.pexels.com/photos/3662667/pexels-photo-3662667.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#4FA8D5',
    true,
    2
  ),
  (
    'Social & Emotional Learning',
    'Group activities and role-playing games to help children express emotions, build friendships, and develop empathy.',
    'people',
    'https://images.pexels.com/photos/8613318/pexels-photo-8613318.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#6D83F2',
    true,
    3
  ),
  (
    'Physical Wellness & Play',
    'Engaging in fun sports, dance, and movement-based activities to improve fitness and teamwork.',
    'run',
    'https://images.pexels.com/photos/296301/pexels-photo-296301.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#4CAF50',
    true,
    4
  ),
  (
    'Literacy & Storytelling',
    'Interactive reading sessions, storytelling, and basic literacy skills to boost communication and comprehension.',
    'book',
    'https://images.pexels.com/photos/8613183/pexels-photo-8613183.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#A55EEA',
    true,
    5
  ),
  (
    'Life Skills & Independence',
    'Teaching daily life skills like hygiene, organization, and responsibility to help children adapt to new environments.',
    'school',
    'https://images.pexels.com/photos/7713321/pexels-photo-7713321.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#F4A261',
    true,
    6
  );

commit;
