import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../domain/models/game_session.dart';
import '../../../../features/game/providers/game_provider.dart';

class ModeCard extends ConsumerStatefulWidget {
  const ModeCard({
    super.key,
    required this.mode,
    required this.label,
    required this.emoji,
    required this.gradient,
  });

  final GameMode mode;
  final String label;
  final String emoji;
  final LinearGradient gradient;

  @override
  ConsumerState<ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends ConsumerState<ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _onTap(context, ref);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: widget.gradient,
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    HapticHelper.light();
    if (widget.mode == GameMode.custom) {
      context.push('/game/setup');
      return;
    }
    ref.read(gameSessionProvider.notifier).startSession(
      mode: widget.mode,
      categoryIds: [],
    );
    context.push('/game/play', extra: {'sessionId': null});
  }
}
