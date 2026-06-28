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
import '../../../../domain/models/history_entry.dart';
import '../../../../domain/repositories/question_repository.dart';
import '../../../../domain/repositories/user_repository.dart';
import '../../../../features/home/providers/home_provider.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({
    super.key,
    required this.categoryId,
    this.mode = GameMode.classic,
  });

  final String categoryId;
  final GameMode mode;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with TickerProviderStateMixin {
  late List<Question> _questions;
  int _currentIndex = 0;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    final repo = ref.read(questionRepositoryProvider);
    _questions = repo.getShuffled(
      categoryId: widget.categoryId,
      limit: widget.mode == GameMode.infinite ? null : 20,
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex >= _questions.length - 1 &&
        widget.mode != GameMode.infinite) {
      if (mounted) context.pop();
      return;
    }

    await _recordHistory(_questions[_currentIndex]);

    await _cardController.reverse();
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      } else if (widget.mode == GameMode.infinite) {
        // Re-shuffle and reset
        _questions.shuffle();
        _currentIndex = 0;
      }
    });
    await _cardController.forward();
    ref.read(userStatsProvider.notifier).recordQuestion(widget.categoryId);
    HapticHelper.light();
  }

  Future<void> _recordHistory(Question question) async {
    final entry = HistoryEntry(
      id: _uuid.v4(),
      questionId: question.id,
      questionText: question.text,
      categoryId: question.categoryId,
      viewedAt: DateTime.now(),
      wasFavorited:
          ref.read(favoritesProvider).valueOrNull?.contains(question.id) ?? false,
    );
    await ref.read(userRepositoryProvider).addToHistory(entry);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('Aucune question')));
    }

    final question = _questions[_currentIndex];
    final category = QuestionCategory.allCategories.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => QuestionCategory.allCategories.first,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFavorite = ref.watch(favoritesProvider).valueOrNull?.contains(question.id) ?? false;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
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
                Icons.close_rounded,
                size: 16,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          title: Text(
            '${_currentIndex + 1} / ${widget.mode == GameMode.infinite ? '∞' : _questions.length}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          actions: [
            IconButton(
              onPressed: () async {
                HapticHelper.selection();
                ref.read(favoritesProvider.notifier).toggle(question.id);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(isFavorite),
                  color: isFavorite ? AppColors.primary : null,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                HapticHelper.light();
                await Share.share(question.text);
                ref.read(userStatsProvider.notifier).recordShare();
              },
              icon: const Icon(Icons.share_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress
                if (widget.mode != GameMode.infinite)
                  _ProgressIndicator(
                    current: _currentIndex,
                    total: _questions.length,
                    color: category.color,
                  ),
                const Spacer(),

                // Question card
                AnimatedBuilder(
                  animation: _cardAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.85 + 0.15 * _cardAnimation.value,
                      child: Opacity(
                        opacity: _cardAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: _QuestionCard(
                    question: question,
                    category: category,
                  ),
                ),

                const Spacer(),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.skip_next_rounded,
                      label: 'Passer',
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      onTap: _nextQuestion,
                      size: 56,
                    ),
                    const SizedBox(width: 20),
                    _ActionButton(
                      icon: Icons.check_circle_rounded,
                      label: 'Suivante',
                      color: category.color,
                      onTap: _nextQuestion,
                      size: 72,
                      isPrimary: true,
                    ),
                    const SizedBox(width: 20),
                    _ActionButton(
                      icon: Icons.shuffle_rounded,
                      label: 'Mélanger',
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      onTap: () {
                        HapticHelper.medium();
                        setState(() {
                          _questions.shuffle();
                          _currentIndex = 0;
                        });
                      },
                      size: 56,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.current,
    required this.total,
    required this.color,
  });

  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(total.clamp(0, 20), (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: index <= current
                      ? color
                      : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.category});

  final Question question;
  final QuestionCategory category;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: category.gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
            textAlign: TextAlign.center,
          ),
          if (question.difficulty == DifficultyLevel.hard ||
              question.difficulty == DifficultyLevel.spicy) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: question.difficulty == DifficultyLevel.spicy
                        ? AppColors.secondary.withOpacity(0.15)
                        : AppColors.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.difficulty == DifficultyLevel.spicy
                        ? '🔥 Épicé'
                        : '🧠 Profond',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: question.difficulty == DifficultyLevel.spicy
                          ? AppColors.secondary
                          : AppColors.accentPurple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.size,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final bool isPrimary;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Column(
        children: [
          AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isPrimary
                    ? widget.color
                    : (isDark ? AppColors.surface2Dark : AppColors.surface2Light),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                color: widget.isPrimary
                    ? Colors.white
                    : widget.color,
                size: widget.size * 0.42,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
