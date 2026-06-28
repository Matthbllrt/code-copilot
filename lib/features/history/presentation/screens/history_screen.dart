import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/history_entry.dart';
import '../../../../domain/models/question.dart';
import '../../../../domain/repositories/question_repository.dart';
import '../../../../features/home/providers/home_provider.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('📜', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text('Historique'),
            ],
          ),
          actions: [
            historyAsync.when(
              data: (history) => history.isNotEmpty
                  ? TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Effacer l\'historique ?'),
                            content: const Text('Cette action est irréversible.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ref.read(historyProvider.notifier).clear();
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
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        body: historyAsync.when(
          data: (history) => history.isEmpty
              ? _EmptyHistory()
              : _HistoryList(history: history),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📜', style: TextStyle(fontSize: 64))
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 500.ms,
              ),
          const SizedBox(height: 20),
          Text(
            'Aucun historique',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les questions que vous parcourez\napparaîtront ici',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.history});
  final List<HistoryEntry> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(questionRepositoryProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final question = repo.getById(entry.questionId);
        if (question == null) return const SizedBox.shrink();

        final category = QuestionCategory.allCategories.firstWhere(
          (c) => c.id == question.categoryId,
          orElse: () => QuestionCategory.allCategories.first,
        );
        final isFav = ref
                .watch(favoritesProvider)
                .valueOrNull
                ?.contains(question.id) ??
            false;

        return _HistoryCard(
          question: question,
          category: category,
          entry: entry,
          isFavorite: isFav,
          onFavorite: () {
            HapticHelper.selection();
            ref.read(favoritesProvider.notifier).toggle(question.id);
          },
          onShare: () async {
            await Share.share(question.text);
            ref.read(userStatsProvider.notifier).recordShare();
          },
        ).animate().fadeIn(delay: (30 * index).ms, duration: 300.ms);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.question,
    required this.category,
    required this.entry,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
  });

  final Question question;
  final QuestionCategory category;
  final HistoryEntry entry;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: category.gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${category.emoji} ${category.name}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(entry.viewedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onShare,
                child: Icon(
                  Icons.share_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onFavorite,
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 16,
                  color: isFavorite
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
