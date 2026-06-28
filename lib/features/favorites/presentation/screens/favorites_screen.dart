import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/question.dart';
import '../../../../domain/repositories/question_repository.dart';
import '../../../../features/home/providers/home_provider.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider).valueOrNull ?? {};
    final repo = ref.read(questionRepositoryProvider);
    final favorites = favIds
        .map((id) => repo.getById(id))
        .whereType<Question>()
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text('Mes Favoris'),
            ],
          ),
          actions: [
            if (favorites.isNotEmpty)
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Effacer les favoris ?'),
                      content: const Text('Cette action est irréversible.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            for (final q in favorites) {
                              ref.read(favoritesProvider.notifier).toggle(q.id);
                            }
                          },
                          child: const Text(
                            'Effacer',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Tout effacer'),
              ),
          ],
        ),
        body: favorites.isEmpty
            ? _EmptyFavorites()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final question = favorites[index];
                  final category = QuestionCategory.allCategories.firstWhere(
                    (c) => c.id == question.categoryId,
                    orElse: () => QuestionCategory.allCategories.first,
                  );
                  return _FavoriteCard(
                    question: question,
                    category: category,
                    onRemove: () {
                      HapticHelper.medium();
                      ref.read(favoritesProvider.notifier).toggle(question.id);
                    },
                    onShare: () async {
                      await Share.share(question.text);
                      ref.read(userStatsProvider.notifier).recordShare();
                    },
                  ).animate().fadeIn(delay: (40 * index).ms, duration: 300.ms);
                },
              ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💝', style: TextStyle(fontSize: 64))
              .animate()
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms),
          const SizedBox(height: 20),
          Text(
            'Aucun favori pour l\'instant',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur ❤️ pendant une session\npour sauvegarder vos questions préférées',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.question,
    required this.category,
    required this.onRemove,
    required this.onShare,
  });

  final Question question;
  final QuestionCategory category;
  final VoidCallback onRemove;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: category.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${category.emoji} ${category.name}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onShare,
                child: Icon(
                  Icons.share_rounded,
                  size: 18,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
