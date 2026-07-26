import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tribe_up/config/di/di.dart';
import 'package:tribe_up/core/constants/app_routes_constants.dart';
import 'package:tribe_up/core/resources/color_manager.dart';
import 'package:tribe_up/features/feed/domain/entities/post_liker_entity.dart';
import 'package:tribe_up/features/feed/presentation/cubit/post_likers_cubit.dart';

class PostLikersBottomSheet extends StatefulWidget {
  final int postId;

  const PostLikersBottomSheet({super.key, required this.postId});

  static void show(BuildContext context, int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostLikersBottomSheet(postId: postId),
    );
  }

  @override
  State<PostLikersBottomSheet> createState() => _PostLikersBottomSheetState();
}

class _PostLikersBottomSheetState extends State<PostLikersBottomSheet> {
  late final PostLikersCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PostLikersCubit>();
    _cubit.fetchPostLikers(widget.postId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider.value(
      value: _cubit,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.70,
        ),
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Bottom sheet drag handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorManager.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            BlocBuilder<PostLikersCubit, PostLikersState>(
              builder: (context, state) {
                final totalCount = state.likers.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Likes',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (totalCount > 0 && !state.isLoading) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ColorManager.lightGrey.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalCount',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ColorManager.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ColorManager.lightGrey.withValues(
                                alpha: 0.3,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: ColorManager.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Search bar (if likers > 4)
            BlocBuilder<PostLikersCubit, PostLikersState>(
              builder: (context, state) {
                if (state.likers.length > 4) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorManager.lightGrey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search likers...',
                          hintStyle: textTheme.bodySmall?.copyWith(
                            color: ColorManager.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: ColorManager.grey,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            Divider(
              height: 1,
              color: ColorManager.grey.withValues(alpha: 0.15),
            ),

            // Likers Body
            Expanded(
              child: BlocBuilder<PostLikersCubit, PostLikersState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => Row(
                          children: [
                            const Bone.circle(size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Bone.text(width: 120, fontSize: 14),
                                  SizedBox(height: 6),
                                  Bone.text(width: 80, fontSize: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state.errorMessage != null && state.likers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 44,
                            color: ColorManager.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: ColorManager.grey,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _cubit.fetchPostLikers(widget.postId),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredLikers = state.likers.where((liker) {
                    if (_searchQuery.isEmpty) return true;
                    final u = liker.username.toLowerCase();
                    final n = (liker.name ?? '').toLowerCase();
                    return u.contains(_searchQuery) || n.contains(_searchQuery);
                  }).toList();

                  if (filteredLikers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorManager.lightGrey.withValues(
                                alpha: 0.3,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 40,
                              color: ColorManager.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No likers found matching "$_searchQuery"'
                                : 'No likes yet',
                            style: textTheme.bodyMedium?.copyWith(
                              color: ColorManager.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: filteredLikers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final liker = filteredLikers[index];

                      // Strict current user check
                      final isCurrentUser =
                          (state.currentUsername != null &&
                              state.currentUsername!.isNotEmpty &&
                              liker.username.toLowerCase() ==
                                  state.currentUsername!.toLowerCase()) ||
                          (state.currentUserId != null &&
                              state.currentUserId!.isNotEmpty &&
                              liker.userId == state.currentUserId);

                      return _LikerTile(
                        liker: liker,
                        isCurrentUser: isCurrentUser,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (liker.username.isNotEmpty) {
                            context.pushNamed(
                              AppRoutesConstants.profile,
                              extra: liker.username,
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikerTile extends StatelessWidget {
  final PostLikerEntity liker;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const _LikerTile({
    required this.liker,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarUrl = liker.profilePictureUrl;
    final hasValidAvatar =
        avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != 'null' &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            children: [
              // Clean Avatar
              hasValidAvatar
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        backgroundImage: imageProvider,
                        radius: 22,
                      ),
                      placeholder: (_, __) => CircleAvatar(
                        radius: 22,
                        backgroundColor: ColorManager.lightGrey.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      errorWidget: (_, __, ___) => CircleAvatar(
                        radius: 22,
                        backgroundColor: ColorManager.lightGrey.withValues(
                          alpha: 0.4,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: ColorManager.grey,
                          size: 24,
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 22,
                      backgroundColor: ColorManager.lightGrey.withValues(
                        alpha: 0.4,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: ColorManager.grey,
                        size: 24,
                      ),
                    ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            liker.name != null && liker.name!.isNotEmpty
                                ? liker.name!
                                : (liker.username.isNotEmpty
                                      ? liker.username
                                      : 'User'),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You',
                              style: textTheme.bodySmall?.copyWith(
                                color: ColorManager.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (liker.username.isNotEmpty)
                      Text(
                        '@${liker.username}',
                        style: textTheme.bodySmall?.copyWith(
                          color: ColorManager.grey,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Chevron action hint
              Icon(
                Icons.chevron_right_rounded,
                color: ColorManager.grey.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
