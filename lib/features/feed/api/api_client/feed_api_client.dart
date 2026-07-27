import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/core/constants/ui_constants.dart';
import 'package:tribe_up/features/feed/data/models/create_post_response.dart';
import 'package:tribe_up/features/feed/data/models/feed_response.dart';
import 'package:tribe_up/features/feed/data/models/toggle_like_response.dart';
import 'package:tribe_up/features/feed/data/models/post_model.dart';

import 'package:tribe_up/features/feed/data/models/post_likers_response.dart';

part 'feed_api_client.g.dart';

@injectable
@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class FeedApiClient {
  @factoryMethod
  factory FeedApiClient(Dio dio) = _FeedApiClient;

  @GET(ApiConstants.feedEndPoint)
  Future<FeedResponse> getFeed(
    @Query(UiConstants.page) int page,
    @Query(UiConstants.pageSize) int pageSize,
  );

  @GET(ApiConstants.groupFeedEndPoint)
  Future<FeedResponse> getGroupFeed(
    @Path('groupId') int groupId,
    @Query(UiConstants.page) int page,
    @Query(UiConstants.pageSize) int pageSize,
  );

  @GET(ApiConstants.personalFeedEndPoint)
  Future<FeedResponse> getPersonalFeed(
    @Query('username') String username,
    @Query(UiConstants.page) int page,
    @Query(UiConstants.pageSize) int pageSize,
  );

  @POST(ApiConstants.createPostEndPoint)
  @MultiPart()
  Future<CreatePostResponse> createPost(
    @Part(name: 'GroupId') int? groupId,
    @Part(name: 'Caption') String caption,
    @Part(name: 'Accessibility') int accessibility,
    @Part(name: 'TaggedUserIds') List<String>? taggedUserIds,
    @Part(name: 'mediaFiles') List<File>? mediaFiles,
  );

  @DELETE(ApiConstants.deletePostEndPoint)
  Future<void> deletePost(@Path('postId') int postId);

  @POST(ApiConstants.postToggleLikeEndPoint)
  Future<ToggleLikeResponse> toggleLikePost(@Path('postId') int postId);

  @PUT(ApiConstants.editPostEndPoint)
  Future<CreatePostResponse> editPost(
    @Path('postId') int postId,
    @Body() FormData body,
  );

  @GET(ApiConstants.getPostByIdEndPoint)
  Future<PostModel> getPostById(@Path('postId') int postId);

  @GET(ApiConstants.postLikesEndPoint)
  Future<PostLikersResponse> getPostLikes(
    @Path('postId') int postId,
    @Query(UiConstants.page) int page,
    @Query(UiConstants.pageSize) int pageSize,
  );
}
