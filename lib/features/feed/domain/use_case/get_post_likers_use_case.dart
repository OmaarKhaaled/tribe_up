import 'package:injectable/injectable.dart';
import 'package:tribe_up/config/base_response/base_response.dart';
import 'package:tribe_up/features/feed/domain/entities/post_liker_entity.dart';
import 'package:tribe_up/features/feed/domain/repository/feed_repository.dart';

@injectable
class GetPostLikersUseCase {
  final FeedRepository _feedRepository;

  const GetPostLikersUseCase(this._feedRepository);

  Future<BaseResponse<List<PostLikerEntity>>> call({
    required int postId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _feedRepository.getPostLikes(
      postId: postId,
      page: page,
      pageSize: pageSize,
    );
  }
}
