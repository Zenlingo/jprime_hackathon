import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/qa_service.dart';

class SessionQASection extends StatefulWidget {
  final String sessionId;
  final String? displayName;

  const SessionQASection({
    super.key,
    required this.sessionId,
    this.displayName,
  });

  @override
  State<SessionQASection> createState() => _SessionQASectionState();
}

class _SessionQASectionState extends State<SessionQASection> {
  final _controller = TextEditingController();
  String? _deviceId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await QAService.getDeviceId();
    if (mounted) setState(() => _deviceId = id);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _deviceId == null) return;
    setState(() => _sending = true);
    try {
      await QAService.postQuestion(
        widget.sessionId,
        text,
        widget.displayName ?? 'Anonymous',
        _deviceId!,
      );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleUpvote(String questionId) async {
    if (_deviceId == null) return;
    await QAService.toggleUpvote(questionId, _deviceId!);
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;

    return Column(
      children: [
        // Questions list
        Expanded(
          child: StreamBuilder<List<Question>>(
            stream: QAService.questionsStream(widget.sessionId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: jp.accent),
                );
              }
              final questions = snap.data ?? [];
              if (questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.chatCircleDots,
                        size: 48,
                        color: jp.fgMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No questions yet',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: jp.fgMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to ask!',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          color: jp.fgMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                itemCount: questions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final q = questions[i];
                  final voted = _deviceId != null &&
                      q.upvotedBy.contains(_deviceId);
                  return _QuestionCard(
                    question: q,
                    voted: voted,
                    onUpvote: () => _toggleUpvote(q.id),
                    relativeTime: _relativeTime(q.timestamp),
                  );
                },
              );
            },
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
          decoration: BoxDecoration(
            color: jp.surface,
            border: Border(top: BorderSide(color: jp.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      color: jp.fg,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        color: jp.fgMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(JPSpacing.rMd),
                        borderSide: BorderSide(color: jp.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(JPSpacing.rMd),
                        borderSide: BorderSide(color: jp.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(JPSpacing.rMd),
                        borderSide: BorderSide(color: jp.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: jp.bg,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: jp.accent,
                      borderRadius: BorderRadius.circular(JPSpacing.rMd),
                    ),
                    child: Center(
                      child: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: jp.onAccent,
                              ),
                            )
                          : PhosphorIcon(
                              PhosphorIconsFill.paperPlaneTilt,
                              size: 20,
                              color: jp.onAccent,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final bool voted;
  final VoidCallback onUpvote;
  final String relativeTime;

  const _QuestionCard({
    required this.question,
    required this.voted,
    required this.onUpvote,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: jp.surface,
        border: Border.all(color: jp.border),
        borderRadius: BorderRadius.circular(JPSpacing.rMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upvote button
          GestureDetector(
            onTap: onUpvote,
            child: Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: voted ? jp.accentSoft : jp.bg,
                borderRadius: BorderRadius.circular(JPSpacing.rSm),
                border: Border.all(
                  color: voted ? jp.accent : jp.border,
                ),
              ),
              child: Column(
                children: [
                  PhosphorIcon(
                    voted
                        ? PhosphorIconsFill.arrowFatUp
                        : PhosphorIconsRegular.arrowFatUp,
                    size: 18,
                    color: voted ? jp.accent : jp.fgMuted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${question.upvotes}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: voted ? jp.accent : jp.fgSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Question content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 1.4,
                    color: jp.fg,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      question.authorName,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: jp.fgSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      relativeTime,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: jp.fgMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
