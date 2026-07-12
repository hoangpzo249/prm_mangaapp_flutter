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

  const StoryInteractionSection({super.key, required this.storyId});

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
      final results = await Future.wait<dynamic>([
        _commentsRepo.getByStory(widget.storyId),
        _ratingsRepo.getByStory(widget.storyId),
        _authRepo.getUserData(),
      ]);
      if (!mounted) return;
      setState(() {
        _comments = results[0] as List<CommentItem>;
        _rating = results[1] as RatingSummary;
        _user = results[2] as AppUser?;
      });
    } catch (error) {
      _show('Không thể tải đánh giá hoặc bình luận: $error');
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
        title: const Text('Cần đăng nhập', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn cần đăng nhập để đánh giá hoặc bình luận.',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng nhập')),
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
      _show('Đã đánh giá $score sao');
    } catch (error) {
      _show('Không thể đánh giá: $error');
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
      _show('Đã gửi bình luận');
    } catch (error) {
      _show('Không thể gửi bình luận: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(CommentItem comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xóa bình luận?', style: TextStyle(color: Colors.white)),
        content: const Text('Thao tác này không thể hoàn tác.', style: TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _commentsRepo.deleteComment(comment.id);
      await _load();
      _show('Đã xóa bình luận');
    } catch (error) {
      _show('Không thể xóa bình luận: $error');
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
          _ratingSection(),
          const SizedBox(height: 24),
          _commentComposer(),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Chưa có bình luận', style: TextStyle(color: AppColors.textDim)),
              ),
            )
          else
            ..._comments.map(_commentCard),
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
          const Text('Đánh giá truyện', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${_rating.averageRating.toStringAsFixed(1)}/5 • ${_rating.ratingCount} lượt đánh giá',
            style: const TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final score = index + 1;
              final selected = (_rating.yourScore ?? 0) >= score;
              return IconButton(
                tooltip: '$score sao',
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
                child: Text('Bình luận', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_replyToId != null)
                TextButton(
                  onPressed: () => setState(() {
                    _replyToId = null;
                    _replyToName = null;
                  }),
                  child: const Text('Hủy trả lời'),
                ),
            ],
          ),
          if (_replyToName != null)
            Text('Đang trả lời $_replyToName', style: const TextStyle(color: AppColors.primary)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập nội dung bình luận...',
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
              label: Text(_submitting ? 'Đang gửi...' : 'Gửi'),
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
                child: const Text('Trả lời'),
              ),
              if (canDelete)
                TextButton(
                  onPressed: () => _deleteComment(comment),
                  child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
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
                              child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
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
