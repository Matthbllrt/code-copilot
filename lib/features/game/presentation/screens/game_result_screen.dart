import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../domain/models/game_session.dart';
import '../../../../features/game/providers/game_provider.dart';
import '../../../../features/home/providers/home_provider.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';

class GameResultScreen extends ConsumerStatefulWidget {
  const GameResultScreen({super.key, this.sessionId});
  final String? sessionId;

  @override
  ConsumerState<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends ConsumerState<GameResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      HapticHelper.success();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final stats = ref.watch(userStatsProvider).valueOrNull;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accentPurple,
                  AppColors.accent,
                  AppColors.accentBlue,
                ],
                numberOfParticles: 40,
                emissionFrequency: 0.1,
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),

                    // Trophy emoji
                    const Text('🏆', style: TextStyle(fontSize: 80))
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: 24),

                    Text(
                      'Session terminée !',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 8),

                    if (session != null)
                      Text(
                        '${session.answeredQuestionIds.length} questions répondues • ${_formatDuration(session.duration)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 40),

                    // Stats cards
                    _ResultStats(session: session, stats: stats)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    const Spacer(),

                    // XP earned
                    if (session != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '+${session.answeredQuestionIds.length * 10 + 50} XP gagnés !',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Action buttons
                    GradientButton(
                      width: double.infinity,
                      onPressed: () {
                        HapticHelper.medium();
                        if (session != null) {
                          ref.read(gameSessionProvider.notifier).startSession(
                            mode: session.mode,
                            categoryIds: session.categoryIds,
                          );
                          context.pushReplacement(
                            '/game/play',
                            extra: {'sessionId': null},
                          );
                        }
                      },
                      child: const Text('Rejouer'),
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                    const SizedBox(height: 12),

                    OutlineGradientButton(
                      onPressed: () {
                        ref.read(gameSessionProvider.notifier).resetSession();
                        context.go('/');
                      },
                      child: const Text('Retour à l\'accueil'),
                    ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    if (min == 0) return '${sec}s';
    return '${min}min ${sec}s';
  }
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.session, required this.stats});
  final GameSession? session;
  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            emoji: '✅',
            value: '${session?.answeredQuestionIds.length ?? 0}',
            label: 'Répondues',
          ),
          _StatDivider(),
          _StatItem(
            emoji: '⏭️',
            value: '${session?.skippedQuestionIds.length ?? 0}',
            label: 'Passées',
          ),
          _StatDivider(),
          _StatItem(
            emoji: '🔥',
            value: '${stats?.currentStreak ?? 0}',
            label: 'Série',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 50,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
