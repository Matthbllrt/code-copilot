class AppConstants {
  AppConstants._();

  static const String appName = 'Nous Deux';
  static const String appTagline = 'Un voyage au cœur de votre relation';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyFavorites = 'favorites';
  static const String keyHistory = 'history';
  static const String keyStats = 'user_stats';
  static const String keyBadges = 'badges';
  static const String keyOnboarding = 'onboarding_complete';
  static const String keySessionCount = 'session_count';
  static const String keyCustomQuestions = 'custom_questions';
  static const String keyGameSettings = 'game_settings';
  static const String keyLevel = 'user_level';
  static const String keyXp = 'user_xp';

  // Limits
  static const int maxFavorites = 500;
  static const int maxHistory = 1000;
  static const int maxCustomQuestions = 100;
  static const int cardsPerSession = 20;
  static const int questionsPerPage = 10;

  // XP & Levels
  static const int xpPerQuestion = 10;
  static const int xpPerSession = 50;
  static const int xpPerFavorite = 5;
  static const int xpPerShare = 15;
  static const int xpPerStreak = 25;
  static const List<int> levelThresholds = [
    0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000,
    17000, 24000, 33000, 45000, 60000,
  ];

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // Card swipe threshold
  static const double swipeThreshold = 0.4;

  // Categories IDs
  static const String catRomantic = 'romantic';
  static const String catHot = 'hot';
  static const String catFunny = 'funny';
  static const String catDeep = 'deep';
  static const String catFuture = 'future';
  static const String catRandom = 'random';
  static const String catDateNight = 'date_night';
  static const String catCommunication = 'communication';
  static const String catTruthOrDare = 'truth_or_dare';

  // Game modes
  static const String modeClassic = 'classic';
  static const String modeInfinite = 'infinite';
  static const String modeDuel = 'duel';
  static const String modeChallenge = 'challenge';
  static const String modeRandom = 'random';
  static const String modeDate = 'date';
  static const String modeEvening = 'evening';
  static const String modeCustom = 'custom';
}
