import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/game_session.dart';
import '../../../../domain/models/question.dart';
import '../../../../features/game/providers/game_provider.dart';
import '../../../../features/home/providers/home_provider.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';

class GamePlayScreen extends ConsumerStatefulWidget {
  const GamePlayScreen({super.key, this.sessionId});
  final String? sessionId;

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session introuvable', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    if (session.isCompleted || session.status == SessionStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/game/result', extra: {'sessionId': session.id});
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = session.currentQuestion;
    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final category = QuestionCategory.allCategories.firstWhere(
      (c) => c.id == (session.categoryIds.isNotEmpty
          ? session.categoryIds.first
          : question.categoryId),
      orElse: () => QuestionCategory.allCategories.firstWhere(
        (c) => c.id == question.categoryId,
        orElse: () => QuestionCategory.allCategories.first,
      ),
    );
    final questionCategory = QuestionCategory.allCategories.firstWhere(
      (c) => c.id == question.categoryId,
      orElse: () => QuestionCategory.allCategories.first,
    );

    final isFav = ref.watch(favoritesProvider).valueOrNull?.contains(question.id) ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Quitter la session ?'),
                  content: const Text('Votre progression sera perdue.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Continuer'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(gameSessionProvider.notifier).abandonSession();
                        context.go('/');
                      },
                      child: Text(
                        'Quitter',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.close_rounded),
          ),
          title: _SessionProgress(session: session),
          actions: [
            if (session.mode == GameMode.duel)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _DuelScore(session: session),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Mode badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: questionCategory.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${session.mode.emoji} ${session.mode.displayName}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const Spacer(),

                // Question card (swipeable style)
                _GameQuestionCard(
                  question: question,
                  category: questionCategory,
                  isFavorite: isFav,
                  onFavorite: () {
                    HapticHelper.selection();
                    ref.read(favoritesProvider.notifier).toggle(question.id);
                  },
                  onShare: () async {
                    await Share.share(question.text);
                    ref.read(userStatsProvider.notifier).recordShare();
                  },
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                const Spacer(),

                // Action buttons
                _GameActions(
                  session: session,
                  onNext: _handleNext,
                  onSkip: _handleSkip,
                  onComplete: _handleComplete,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNext() {
    HapticHelper.light();
    final session = ref.read(gameSessionProvider);
    if (session == null) return;

    // Auto-load more questions in infinite mode
    if (session.mode == GameMode.infinite &&
        session.remainingQuestions <= 3) {
      ref.read(gameSessionProvider.notifier).addMoreQuestions();
    }

    if (session.remainingQuestions <= 1 &&
        session.mode != GameMode.infinite) {
      ref.read(gameSessionProvider.notifier).completeSession();
    } else {
      ref.read(gameSessionProvider.notifier).nextQuestion();
      ref.read(userStatsProvider.notifier).recordQuestion(
        session.currentQuestion?.categoryId ?? '',
      );
    }
  }

  void _handleSkip() {
    HapticHelper.selection();
    ref.read(gameSessionProvider.notifier).skipQuestion();
  }

  void _handleComplete() {
    HapticHelper.heavy();
    ref.read(gameSessionProvider.notifier).completeSession();
  }
}

class _SessionProgress extends StatelessWidget {
  const _SessionProgress({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    if (session.mode == GameMode.infinite) {
      return Text(
        '${session.answeredQuestionIds.length} répondues',
        style: Theme.of(context).textTheme.titleSmall,
      );
    }
    return Text(
      '${session.currentIndex + 1} / ${session.questions.length}',
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _DuelScore extends StatelessWidget {
  const _DuelScore({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScoreChip(label: 'P1', score: session.duelPlayer1Score, color: AppColors.primary),
        const SizedBox(width: 8),
        _ScoreChip(label: 'P2', score: session.duelPlayer2Score, color: AppColors.accentPurple),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.score, required this.color});
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $score',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _GameQuestionCard extends StatelessWidget {
  const _GameQuestionCard({
    required this.question,
    required this.category,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
  });

  final Question question;
  final QuestionCategory category;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            category.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 24),
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CardAction(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.primary : AppColors.textTertiaryDark,
                onTap: onFavorite,
              ),
              const SizedBox(width: 24),
              _CardAction(
                icon: Icons.share_rounded,
                color: AppColors.textTertiaryDark,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _GameActions extends ConsumerWidget {
  const _GameActions({
    required this.session,
    required this.onNext,
    required this.onSkip,
    required this.onComplete,
  });

  final GameSession session;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastQuestion = session.remainingQuestions <= 1 &&
        session.mode != GameMode.infinite;

    return Column(
      children: [
        if (session.mode == GameMode.duel) ...[
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Joueur 1 ✓',
                  color: AppColors.primary,
                  onTap: () => ref.read(gameSessionProvider.notifier).addDuelScore(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  label: 'Joueur 2 ✓',
                  color: AppColors.accentPurple,
                  onTap: () => ref.read(gameSessionProvider.notifier).addDuelScore(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: 'Passer',
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                onTap: onSkip,
                outlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _ActionBtn(
                label: isLastQuestion ? 'Terminer 🎉' : 'Question suivante →',
                color: AppColors.primary,
                onTap: isLastQuestion ? onComplete : onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.outlined ? Colors.transparent : widget.color,
            borderRadius: BorderRadius.circular(14),
            border: widget.outlined
                ? Border.all(color: widget.color.withOpacity(0.4))
                : null,
            boxShadow: widget.outlined
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.outlined ? widget.color : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
