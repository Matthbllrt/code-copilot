import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/game_session.dart';
import '../../../../domain/models/question.dart';
import '../../../../features/game/providers/game_provider.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  GameMode _selectedMode = GameMode.classic;
  final Set<String> _selectedCategories = {};
  DifficultyLevel? _selectedDifficulty;
  int _questionCount = 20;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = QuestionCategory.allCategories;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Mode Personnalisé'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode selection
              _SectionHeader(title: 'Mode de jeu', emoji: '🎮'),
              const SizedBox(height: 12),
              _ModeSelector(
                selected: _selectedMode,
                onSelect: (mode) => setState(() => _selectedMode = mode),
              ),
              const SizedBox(height: 28),

              // Categories
              _SectionHeader(title: 'Catégories', emoji: '✨'),
              const SizedBox(height: 4),
              Text(
                'Laissez vide pour inclure toutes les catégories',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final selected = _selectedCategories.contains(cat.id);
                  return FilterChip(
                    label: Text('${cat.emoji} ${cat.name}'),
                    selected: selected,
                    onSelected: (val) {
                      HapticHelper.selection();
                      setState(() {
                        if (val) {
                          _selectedCategories.add(cat.id);
                        } else {
                          _selectedCategories.remove(cat.id);
                        }
                      });
                    },
                    selectedColor: cat.color.withOpacity(0.2),
                    checkmarkColor: cat.color,
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? cat.color
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    side: BorderSide(
                      color: selected ? cat.color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    backgroundColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Difficulty
              _SectionHeader(title: 'Difficulté', emoji: '⚡'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _DifficultyChip(
                    label: 'Toutes',
                    selected: _selectedDifficulty == null,
                    onTap: () => setState(() => _selectedDifficulty = null),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyChip(
                    label: '😊 Facile',
                    selected: _selectedDifficulty == DifficultyLevel.easy,
                    onTap: () => setState(() => _selectedDifficulty = DifficultyLevel.easy),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyChip(
                    label: '🧠 Moyen',
                    selected: _selectedDifficulty == DifficultyLevel.medium,
                    onTap: () => setState(() => _selectedDifficulty = DifficultyLevel.medium),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyChip(
                    label: '🔥 Épicé',
                    selected: _selectedDifficulty == DifficultyLevel.spicy,
                    onTap: () => setState(() => _selectedDifficulty = DifficultyLevel.spicy),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Question count
              if (_selectedMode != GameMode.infinite) ...[
                _SectionHeader(title: 'Nombre de questions', emoji: '🔢'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_questionCount questions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        _CountButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (_questionCount > 5) {
                              setState(() => _questionCount -= 5);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _CountButton(
                          icon: Icons.add,
                          onTap: () {
                            if (_questionCount < 50) {
                              setState(() => _questionCount += 5);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: _questionCount.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _questionCount = v.round()),
                ),
                const SizedBox(height: 28),
              ],

              // Start button
              GradientButton(
                width: double.infinity,
                onPressed: _startGame,
                child: const Text('Commencer la session'),
              ),
              const SizedBox(height: 40),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        ),
      ),
    );
  }

  void _startGame() {
    HapticHelper.heavy();
    ref.read(gameSessionProvider.notifier).startSession(
      mode: _selectedMode,
      categoryIds: _selectedCategories.toList(),
      questionCount: _selectedMode == GameMode.infinite ? null : _questionCount,
      difficulty: _selectedDifficulty,
    );
    context.push('/game/play', extra: {'sessionId': null});
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.emoji});
  final String title;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onSelect});
  final GameMode selected;
  final ValueChanged<GameMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final modes = [
      GameMode.classic,
      GameMode.infinite,
      GameMode.duel,
      GameMode.challenge,
      GameMode.date,
      GameMode.evening,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.map((mode) {
        final isSelected = selected == mode;
        return GestureDetector(
          onTap: () {
            HapticHelper.selection();
            onSelect(mode);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected
                  ? null
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surface2Dark
                      : AppColors.surface2Light,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
            ),
            child: Text(
              '${mode.emoji} ${mode.displayName}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticHelper.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : (isDark ? AppColors.surface2Dark : AppColors.surface2Light),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticHelper.selection();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
