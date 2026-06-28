import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/game_session.dart';
import '../../../../domain/models/question.dart';
import '../../../../domain/repositories/question_repository.dart';
import '../../../../features/game/providers/game_provider.dart';
import '../../../../features/home/providers/home_provider.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = QuestionCategory.allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => QuestionCategory.allCategories.first,
    );
    final questions = ref.read(questionRepositoryProvider).getByCategory(categoryId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBackground(
      gradient: category.gradient.scale(0.15),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.glassDark : AppColors.glassLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    size: 16,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(gradient: category.gradient),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 64),
                        )
                            .animate()
                            .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 400.ms),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${questions.length} questions',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    // Play buttons
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            gradient: category.gradient,
                            onPressed: () {
                              HapticHelper.medium();
                              ref.read(gameSessionProvider.notifier).startSession(
                                mode: GameMode.classic,
                                categoryIds: [categoryId],
                              );
                              context.push('/game/play', extra: {'sessionId': null});
                            },
                            child: const Text('Jouer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlineGradientButton(
                          gradient: category.gradient,
                          onPressed: () {
                            HapticHelper.light();
                            context.push('/questions/$categoryId?mode=infinite');
                          },
                          child: const Text('Explorer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aperçu des questions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final q = questions[index];
                    return _QuestionPreviewTile(
                      question: q,
                      category: category,
                      index: index,
                    );
                  },
                  childCount: questions.length.clamp(0, 20),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _QuestionPreviewTile extends StatelessWidget {
  const _QuestionPreviewTile({
    required this.question,
    required this.category,
    required this.index,
  });

  final Question question;
  final QuestionCategory category;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: category.gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (30 * index).ms, duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

extension _GradientScale on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((c) => c.withOpacity(opacity)).toList(),
    );
  }
}
