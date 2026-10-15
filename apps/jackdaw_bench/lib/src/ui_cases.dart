const List<String> _kinds = [
  'a login form',
  'a sign-up form',
  'a contact form',
  'a settings screen with toggles',
  'a profile card',
  'a product card with a buy button',
  'a weather card',
  'an order summary',
  'a checkout form',
  'a search screen with filters',
  'a to-do list',
  'an event invitation with a reply button',
  'a survey question with choices',
  'a rating form with a slider',
  'a booking form with a date',
  'a flight details card',
  'a recipe card',
  'a playlist',
  'a news article card',
  'a dashboard with three numbers',
];

const List<String> _places = [
  'a coffee shop',
  'a gym',
  'a library',
  'a travel app',
  'a bank',
  'a school',
  'a clinic',
  'a pet store',
  'a cinema',
  'a bakery',
];

/// The 200 UI requests of claim C13: twenty kinds of screen for ten
/// places.
List<String> uiCases({int places = 10}) => [
  for (final place in _places.take(places))
    for (final kind in _kinds) 'Show $kind for $place.',
];
