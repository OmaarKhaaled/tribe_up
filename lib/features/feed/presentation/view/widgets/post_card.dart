import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tribe_up/core/constants/date_constants.dart';
import 'package:tribe_up/core/resources/color_manager.dart';
import 'package:tribe_up/core/constants/ui_constants.dart';
import 'package:tribe_up/features/feed/domain/entities/post_entity.dart';
import 'package:tribe_up/features/feed/presentation/view/widgets/dialogs/confirm_delete_post_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:tribe_up/core/constants/app_routes_constants.dart';
import 'package:tribe_up/features/feed/presentation/view/widgets/dialogs/edit_post_sheet.dart';
import 'package:tribe_up/features/feed/presentation/view/widgets/video_player_widget.dart';
import 'package:tribe_up/features/comments/presentation/view/widgets/comments_bottom_sheet.dart';
import 'package:tribe_up/features/feed/presentation/view/widgets/expandable_text.dart';
import 'package:tribe_up/features/feed/presentation/view/widgets/post_likers_bottom_sheet.dart';
import 'package:tribe_up/features/groups/data/models/response/groups_response.dart';

class PostCard extends StatelessWidget {
  final PostEntity post;
  final String? currentUserProfilePicture;
  final bool isTogglingLike;
  final bool isDeleting;
  final bool isEditing;
  final VoidCallback? onToggleLike;
  final VoidCallback? onDelete;
  final void Function(
    String caption,
    List<File>? newMediaFiles,
    List<int>? deleteMediaIds,
  )?
  onEditSubmit;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserProfilePicture,
    this.isTogglingLike = false,
    this.isDeleting = false,
    this.isEditing = false,
    this.onToggleLike,
    this.onDelete,
    this.onEditSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: isDeleting ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.pushNamed(
                      AppRoutesConstants.tribeProfile,
                      extra: Group(
                        id: post.groupId,
                        groupName: post.groupName,
                        groupProfilePicture: post.groupProfilePicture,
                      ),
                    );
                  },
                  child: _GroupAvatar(
                    groupProfilePicture: post.groupProfilePicture,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            AppRoutesConstants.tribeProfile,
                            extra: Group(
                              id: post.groupId,
                              groupName: post.groupName,
                              groupProfilePicture: post.groupProfilePicture,
                            ),
                          );
                        },
                        child: Text(
                          post.groupName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            AppRoutesConstants.profile,
                            extra: post.username,
                          );
                        },
                        child: Text(
                          'from @${post.username}',
                          style: textTheme.bodySmall?.copyWith(
                            color: ColorManager.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // More options — shown to author (edit+delete) or admin/owner (delete only)
                if (post.canDelete || post.isAuthor)
                  _PostMoreMenu(
                    post: post,
                    isDeleting: isDeleting,
                    isEditing: isEditing,
                    onDelete: (isDeleting || isEditing)
                        ? null
                        : () => _showDeleteDialog(context),
                    onEditSubmit: onEditSubmit,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Media ──
            if (post.media.isNotEmpty) _MediaSection(media: post.media),
            const SizedBox(height: 12),

            // ── Caption ──
            if (post.caption != null && post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ExpandableText(
                  text: post.caption!,
                  style: textTheme.bodyMedium,
                ),
              ),

            Row(
              children: [
                GestureDetector(
                  onTap: isTogglingLike ? null : onToggleLike,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      post.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      key: ValueKey(post.isLikedByCurrentUser),
                      color: post.isLikedByCurrentUser
                          ? Colors.red
                          : ColorManager.black,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    PostLikersBottomSheet.show(context, post.postId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Text(
                      '${post.likesCount}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Comments
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CommentsBottomSheet(
                        postId: post.postId,
                        userProfilePicture: currentUserProfilePicture,
                      ),
                    );
                  },
                  child: const Icon(Icons.add_comment_outlined, size: 24),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.link, size: 26),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              DateConstants.formatDate(post.createdAt),
              style: textTheme.bodySmall?.copyWith(
                color: ColorManager.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: ColorManager.grey, thickness: .3, height: 1),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDeletePostDialog(
        onConfirm: () {
          onDelete?.call();
        },
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final String? groupProfilePicture;
  const _GroupAvatar({this.groupProfilePicture});

  @override
  Widget build(BuildContext context) {
    final hasValidUrl =
        groupProfilePicture != null &&
        groupProfilePicture!.isNotEmpty &&
        groupProfilePicture != 'null' &&
        groupProfilePicture!.startsWith('http');

    return CircleAvatar(
      radius: 20,
      backgroundColor: ColorManager.lightGrey.withValues(alpha: 0.4),
      backgroundImage: hasValidUrl
          ? CachedNetworkImageProvider(groupProfilePicture!)
          : null,
      child: hasValidUrl
          ? null
          : Icon(Icons.groups, color: ColorManager.grey, size: 20),
    );
  }
}

class _PostMoreMenu extends StatefulWidget {
  final PostEntity post;
  final bool isDeleting;
  final bool isEditing;
  final VoidCallback? onDelete;
  final void Function(
    String caption,
    List<File>? newMediaFiles,
    List<int>? deleteMediaIds,
  )?
  onEditSubmit;

  const _PostMoreMenu({
    required this.post,
    this.isDeleting = false,
    this.isEditing = false,
    this.onDelete,
    this.onEditSubmit,
  });

  @override
  State<_PostMoreMenu> createState() => _PostMoreMenuState();
}

class _PostMoreMenuState extends State<_PostMoreMenu> {
  void _openEditSheet() {
    if (!mounted || widget.onEditSubmit == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) =>
          EditPostSheet(post: widget.post, onSubmit: widget.onEditSubmit!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isBusy = widget.isDeleting || widget.isEditing;
    return PopupMenuButton<String>(
      icon: isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.more_horiz),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'delete') widget.onDelete?.call();
        if (value == 'edit') _openEditSheet();
      },
      itemBuilder: (_) => [
        if (widget.post.isAuthor)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: ColorManager.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  UiConstants.edit,
                  style: textTheme.bodyMedium?.copyWith(
                    color: ColorManager.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: ColorManager.red, size: 20),
              const SizedBox(width: 8),
              Text(
                UiConstants.delete,
                style: textTheme.bodyMedium?.copyWith(
                  color: ColorManager.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaSection extends StatefulWidget {
  final List<dynamic> media;
  const _MediaSection({required this.media});

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.93),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.media.length,
            itemBuilder: (context, index) {
              final postMedia = widget.media[index];
              Widget mediaWidget;

              if (postMedia.mediaType == 'Image') {
                mediaWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: postMedia.mediaURL,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 250,
                      width: double.infinity,
                      color: ColorManager.lightGrey.withValues(alpha: 0.2),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: ColorManager.grey,
                      ),
                    ),
                  ),
                );
              } else if (postMedia.mediaType == 'Video') {
                mediaWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: VideoPlayerWidget(url: postMedia.mediaURL),
                );
              } else {
                mediaWidget = const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: mediaWidget,
              );
            },
          ),
        ),
        if (widget.media.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.media.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 6,
                  width: _currentIndex == index ? 20 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? ColorManager.primary
                        : ColorManager.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
