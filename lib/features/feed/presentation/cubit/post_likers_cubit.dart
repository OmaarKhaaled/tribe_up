import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tribe_up/config/base_response/base_response.dart';
import 'package:tribe_up/features/auth/data/data_sources/local/login_local_data_source.dart';
import 'package:tribe_up/features/feed/domain/entities/post_liker_entity.dart';
import 'package:tribe_up/features/feed/domain/use_case/get_post_likers_use_case.dart';

class PostLikersState extends Equatable {
  final bool isLoading;
  final List<PostLikerEntity> likers;
  final String? errorMessage;
  final int currentPostId;
  final String? currentUsername;
  final String? currentUserId;

  const PostLikersState({
    this.isLoading = false,
    this.likers = const [],
    this.errorMessage,
    this.currentPostId = -1,
    this.currentUsername,
    this.currentUserId,
  });

  PostLikersState copyWith({
    bool? isLoading,
    List<PostLikerEntity>? likers,
    String? errorMessage,
    bool clearError = false,
    int? currentPostId,
    String? currentUsername,
    String? currentUserId,
  }) {
    return PostLikersState(
      isLoading: isLoading ?? this.isLoading,
      likers: likers ?? this.likers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPostId: currentPostId ?? this.currentPostId,
      currentUsername: currentUsername ?? this.currentUsername,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    likers,
    errorMessage,
    currentPostId,
    currentUsername,
    currentUserId,
  ];
}

@injectable
class PostLikersCubit extends Cubit<PostLikersState> {
  final GetPostLikersUseCase _getPostLikersUseCase;
  final LoginLocalDataSource _localDataSource;

  PostLikersCubit(this._getPostLikersUseCase, this._localDataSource)
    : super(const PostLikersState());

  Future<void> fetchPostLikers(int postId) async {
    emit(
      state.copyWith(isLoading: true, clearError: true, currentPostId: postId),
    );

    String? currentUsername;
    String? currentUserId;

    try {
      final userSummary = await _localDataSource.getUserSummary();
      if (userSummary != null) {
        currentUsername = userSummary.userName;
        currentUserId = userSummary.id;
      }
    } catch (_) {}

    final response = await _getPostLikersUseCase(postId: postId);

    switch (response) {
      case SuccessResponse(:final data):
        List<PostLikerEntity> sortedLikers = List.from(data);

        if (currentUsername != null || currentUserId != null) {
          final index = sortedLikers.indexWhere((liker) {
            final usernameMatch =
                currentUsername != null &&
                currentUsername.isNotEmpty &&
                liker.username.toLowerCase() == currentUsername.toLowerCase();
            final idMatch =
                currentUserId != null &&
                currentUserId.isNotEmpty &&
                liker.userId == currentUserId;
            return usernameMatch || idMatch;
          });

          if (index > 0) {
            final currentUserLiker = sortedLikers.removeAt(index);
            sortedLikers.insert(0, currentUserLiker);
          }
        }

        emit(
          state.copyWith(
            isLoading: false,
            likers: sortedLikers,
            clearError: true,
            currentUsername: currentUsername,
            currentUserId: currentUserId,
          ),
        );
      case ErrorResponse(:final error):
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: error.message,
            currentUsername: currentUsername,
            currentUserId: currentUserId,
          ),
        );
    }
  }
}
