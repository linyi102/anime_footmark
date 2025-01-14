import 'package:flutter_test_future/models/bangumi/bangumi.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/network/bangumi_api.dart';

class BangumiRepository {
  final episodesLimit = 100;

  Future<BgmSubject?> fetchSubject(String subjectId) async {
    final result = await DioUtil.get(BangumiApi.subject(subjectId),
        headers: BangumiApi.headers);
    return result.toModel(
      transform: BgmSubject.fromMap,
      dataType: ResultDataType.responseBody,
      onError: () => null,
    );
  }

  Future<List<BgmEpisode>> fetchEpisodes(String subjectId) async {
    final result = await DioUtil.get(
      BangumiApi.episodes,
      headers: BangumiApi.headers,
      query: {
        'subject_id': subjectId,
        'limit': episodesLimit,
        'offset': 0,
      },
    );
    return result.toModelList(
      transform: BgmEpisode.fromMap,
      dataType: ResultDataType.responseBodyData,
    );
  }

  Future<List<BgmCharacter>> fetchCharacters(String subjectId) async {
    final result = await DioUtil.get(BangumiApi.characters(subjectId),
        headers: BangumiApi.headers);
    return result.toModelList(
      transform: BgmCharacter.fromMap,
      dataType: ResultDataType.responseBody,
    );
  }

  Future<List<BgmPerson>> fetchPersons(String subjectId) async {
    final result = await DioUtil.get(BangumiApi.persons(subjectId),
        headers: BangumiApi.headers);
    return result.toModelList(
      transform: BgmPerson.fromMap,
      dataType: ResultDataType.responseBody,
    );
  }
}
