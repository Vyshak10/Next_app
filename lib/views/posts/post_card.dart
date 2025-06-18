import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:like_button/like_button.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post.dart';
import '../../services/api_service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final Function(String)? onTagTap;

  const PostCard({
    Key? key,
    required this.post,
    this.onTap,
    this.onTagTap,
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Images
            if (_post.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: _post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: _post.imageUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _post.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    _post.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),

                  // Tags
                  Wrap(
                    spacing: 8,
                    children: _post.tags.map((tag) {
                      return InkWell(
                        onTap: () => widget.onTagTap?.call(tag),
                        child: Chip(
                          label: Text(tag),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Like and Comment Count
                  Row(
                    children: [
                      LikeButton(
                        isLiked: _post.isLiked,
                        likeCount: _post.likeCount,
                        onTap: _onLikeButtonTapped,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: () {
                          // TODO: Implement comment functionality
                        },
                      ),
                      Text('${_post.commentCount}'),
                      const Spacer(),
                      Text(
                        timeago.format(_post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 