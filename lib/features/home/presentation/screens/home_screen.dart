import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/game_session.dart';
import '../../../../domain/models/user_stats.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/home_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/mode_card.dart';
import '../widgets/level_progress_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBackground(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: GestureDetector(
                onTap: () {
                  HapticHelper.selection();
                  context.push('/search');
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.glassDark : AppColors.glassLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.glassDarkBorder
                          : AppColors.glassLightBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    size: 20,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () {
                    HapticHelper.selection();
                    context.push('/badges');
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.glassDark : AppColors.glassLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.glassDarkBorder
                            : AppColors.glassLightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        statsAsync.when(
                          data: (stats) => Text(
                            'Niv. ${stats.level}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 30,
                            height: 12,
                            child: LinearProgressIndicator(),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Header
                _HeroHeader(statsAsync: statsAsync),
                const SizedBox(height: 28),

                // Quick random button
                _QuickRandomSection(),
                const SizedBox(height: 28),

                // Game modes
                _SectionTitle(title: 'Modes de jeu', emoji: '🎮'),
                const SizedBox(height: 16),
                _GameModesGrid(),
                const SizedBox(height: 28),

                // Categories
                _SectionTitle(title: 'Catégories', emoji: '✨'),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Categories grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => CategoryCard(
                  category: categories[index],
                  onTap: () {
                    HapticHelper.light();
                    context.push('/category/${categories[index].id}');
                  },
                ).animate().fadeIn(
                      delay: (50 * index).ms,
                      duration: 400.ms,
                    ),
                childCount: categories.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.statsAsync});
  final AsyncValue<UserStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 4),
          Text(
            AppConstants.appTagline,
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => LevelProgressBar(stats: stats),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QuickRandomSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticHelper.medium();
          ref.read(gameSessionProvider.notifier).startSession(
            mode: GameMode.random,
            categoryIds: [],
            questionCount: 1,
          );
          context.push('/game/play', extra: {'sessionId': null});
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question Surprise',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Une question au hasard pour démarrer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shuffle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.emoji});
  final String title;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _GameModesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modes = [
      _ModeData(GameMode.classic, 'Classique', '🃏', AppColors.romanticGradient),
      _ModeData(GameMode.infinite, 'Infini', '♾️', AppColors.deepGradient),
      _ModeData(GameMode.duel, 'Duel', '⚔️', AppColors.hotGradient),
      _ModeData(GameMode.date, 'Date Night', '🥂', AppColors.dateNightGradient),
      _ModeData(GameMode.challenge, 'Défis', '🏆', AppColors.funnyGradient),
      _ModeData(GameMode.custom, 'Personnalisé', '✨', AppColors.communicationGradient),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => ModeCard(
          mode: modes[index].mode,
          label: modes[index].label,
          emoji: modes[index].emoji,
          gradient: modes[index].gradient,
        )
            .animate()
            .fadeIn(delay: (60 * index).ms, duration: 400.ms)
            .slideX(begin: 0.1, end: 0),
      ),
    );
  }
}

class _ModeData {
  const _ModeData(this.mode, this.label, this.emoji, this.gradient);
  final GameMode mode;
  final String label;
  final String emoji;
  final LinearGradient gradient;
}
