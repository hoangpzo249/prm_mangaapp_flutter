import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/comment_repository.dart';
import '../../../../data/repositories/rating_repository.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/comment_item.dart';
import '../../../../domain/entities/rating_summary.dart';

class StoryInteractionSection extends StatefulWidget {
  final String storyId;

  /// Cho phép ẩn phần Rating (khi widget này chỉ dùng để hiển thị comment)
  final bool showRating;

  /// Cho phép ẩn phần Comment (khi widget này chỉ dùng để hiển thị rating)
  final bool showComments;

  const StoryInteractionSection({
    super.key,
    required this.storyId,
    this.showRating = true,
    this.showComments = true,
  });

  @override
  State<StoryInteractionSection> createState() => _StoryInteractionSectionState();
}

class _StoryInteractionSectionState extends State<StoryInteractionSection> {
  final _commentsRepo = CommentRepository.instance;
  final _ratingsRepo = RatingRepository.instance;
  final _authRepo = AuthRepository.instance;
  final _commentController = TextEditingController();

  List<CommentItem> _comments = [];
  RatingSummary _rating = const RatingSummary();
  AppUser? _user;
  bool _loading = true;
  bool _submitting = false;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final futures = <Future<dynamic>>[_authRepo.getUserData()];
      if (widget.showRating) {
        futures.add(_ratingsRepo.getByStory(widget.storyId));
      }
      if (widget.showComments) {
        futures.add(_commentsRepo.getByStory(widget.storyId));
      }

      final results = await Future.wait<dynamic>(futures);
      if (!mounted) return;

      setState(() {
        var index = 0;
        _user = results[index++] as AppUser?;
        if (widget.showRating) {
          _rating = results[index++] as RatingSummary;
        }
        if (widget.showComments) {
          _comments = results[index++] as List<CommentItem>;
        }
      });
    } catch (error) {
      _show('Failed to load ratings or comments: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _ensureLoggedIn() async {
    final user = await _authRepo.getUserData();
    if (user != null) {
      _user = user;
      return true;
    }
    if (!mounted) return false;
    final login = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Login required', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You need to login to rate or comment.',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Login')),
        ],
      ),
    );
    if (login == true && mounted) {
      await Navigator.pushNamed(context, AppRoutes.login);
      _user = await _authRepo.getUserData();
      return _user != null;
    }
    return false;
  }

  Future<void> _rate(int score) async {
    if (!await _ensureLoggedIn()) return;
    try {
      final result = await _ratingsRepo.rateStory(widget.storyId, score);
      if (!mounted) return;
      setState(() => _rating = result);
      _show('Rated $score star${score > 1 ? 's' : ''}');
    } catch (error) {
      _show('Failed to rate: $error');
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _submitting) return;
    if (!await _ensureLoggedIn()) return;

    setState(() => _submitting = true);
    try {
      await _commentsRepo.create(
        storyId: widget.storyId,
        content: content,
        parentId: _replyToId,
      );
      _commentController.clear();
      _replyToId = null;
      _replyToName = null;
      final comments = await _commentsRepo.getByStory(widget.storyId);
      if (!mounted) return;
      setState(() => _comments = comments);
      _show('Comment posted');
    } catch (error) {
      _show('Failed to post comment: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(CommentItem comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete comment?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _commentsRepo.deleteComment(comment.id);
      await _load();
      _show('Comment deleted');
    } catch (error) {
      _show('Failed to delete comment: $error');
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showRating) _ratingSection(),
          if (widget.showRating && widget.showComments)
            const SizedBox(height: 24),
          if (widget.showComments) ...[
            _commentComposer(),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No comments yet', style: TextStyle(color: AppColors.textDim)),
                ),
              )
            else
              ..._comments.map(_commentCard),
          ],
        ],
      ),
    );
  }

  Widget _ratingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ratings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${_rating.averageRating.toStringAsFixed(1)}/5 • ${_rating.ratingCount} rating${_rating.ratingCount == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final score = index + 1;
              final selected = (_rating.yourScore ?? 0) >= score;
              return IconButton(
                tooltip: '$score star${score > 1 ? 's' : ''}',
                onPressed: () => _rate(score),
                icon: Icon(
                  selected ? Ionicons.star : Ionicons.star_outline,
                  color: AppColors.star,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _commentComposer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Comments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_replyToId != null)
                TextButton(
                  onPressed: () => setState(() {
                    _replyToId = null;
                    _replyToName = null;
                  }),
                  child: const Text('Cancel reply'),
                ),
            ],
          ),
          if (_replyToName != null)
            Text('Replying to $_replyToName', style: const TextStyle(color: AppColors.primary)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              hintStyle: const TextStyle(color: AppColors.textDim),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitComment,
              icon: const Icon(Ionicons.send_outline),
              label: Text(_submitting ? 'Sending...' : 'Post'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentCard(CommentItem comment) {
    final canDelete = _user?.role == 'admin' || (_user?.id != null && _user!.id == comment.userId);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(comment.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (comment.createdAt != null)
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt!.toLocal()),
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content, style: const TextStyle(color: AppColors.textLight)),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _replyToId = comment.id;
                  _replyToName = comment.displayName;
                }),
                child: const Text('Reply'),
              ),
              if (canDelete)
                TextButton(
                  onPressed: () => _deleteComment(comment),
                  child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                children: comment.replies.map((reply) {
                  final canDeleteReply = _user?.role == 'admin' || (_user?.id != null && _user!.id == reply.userId);
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reply.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(reply.content, style: const TextStyle(color: AppColors.textLight)),
                        if (canDeleteReply)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _deleteComment(reply),
                              child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
