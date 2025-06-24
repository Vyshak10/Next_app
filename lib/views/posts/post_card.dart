import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:like_button/like_button.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post.dart';
import '../../services/api_service.dart';
import '../../common_widget/post.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final Function(String)? onTagTap;
  final void Function(String postId)? onCommentTap;

  const PostCard({
    Key? key,
    required this.post,
    this.onTap,
    this.onTagTap,
    this.onCommentTap,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ApiService _apiService = ApiService();
  late Post _post;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  Future<bool> _onLikeButtonTapped(bool isLiked) async {
    if (_isLiking) return isLiked;
    _isLiking = true;

    try {
      await _apiService.likePost(_post.id);
      setState(() {
        _post = _post.copyWith(
          isLiked: !isLiked,
          likeCount: isLiked ? _post.likeCount - 1 : _post.likeCount + 1,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $e')),
      );
    }

    _isLiking = false;
    return !isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar, Name, Time
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: _post.avatarUrl != null && _post.avatarUrl.isNotEmpty
                          ? NetworkImage(_post.avatarUrl)
                          : null,
                      child: (_post.avatarUrl == null || _post.avatarUrl.isEmpty)
                          ? const Icon(Icons.person, size: 28, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post.authorName ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            timeago.format(_post.createdAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        height: 220,
                        child: PageView.builder(
                          itemCount: _post.imageUrls.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: _post.imageUrls[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Title
                if (_post.title.isNotEmpty)
                  Text(
                    _post.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                if (_post.title.isNotEmpty) const SizedBox(height: 8),
                // Description
                if (_post.description.isNotEmpty)
                  Text(
                    _post.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                if (_post.description.isNotEmpty) const SizedBox(height: 10),
                // Tags
                if (_post.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _post.tags.map((tag) {
                      return InkWell(
                        onTap: () => widget.onTagTap?.call(tag),
                        child: Chip(
                          label: Text(tag, style: const TextStyle(fontWeight: FontWeight.w500)),
                          backgroundColor: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[200], thickness: 1, height: 24),
                // Actions: Like, Comment
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _post.isLiked ? Colors.redAccent : Colors.grey[500],
                        size: 26,
                      ),
                      onPressed: () async {
                        final newLiked = await _onLikeButtonTapped(_post.isLiked);
                        setState(() {
                          _post = _post.copyWith(
                            isLiked: newLiked,
                            likeCount: newLiked ? _post.likeCount + 1 : _post.likeCount - 1,
                          );
                        });
                      },
                    ),
                    Text('${_post.likeCount}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 18),
                    IconButton(
                      icon: const Icon(Icons.comment_rounded, color: Colors.blueGrey, size: 24),
                      onPressed: () => widget.onCommentTap?.call(_post.id),
                    ),
                    Text('${_post.commentCount}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    // Optionally, add a share or more button here
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 