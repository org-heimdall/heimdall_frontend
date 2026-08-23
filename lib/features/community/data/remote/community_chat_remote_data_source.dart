import 'package:dio/dio.dart';

class CommunityChatRemoteDataSource {
  const CommunityChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> fetchMessages(String communityId) async {
    final response = await _dio.get<List<dynamic>>(
      '/communities/$communityId/messages',
    );
    return response.data ?? const [];
  }

  Future<List<dynamic>> fetchOpinions(String communityId) async {
    final response = await _dio.get<List<dynamic>>(
      '/communities/$communityId/opinions',
    );
    return response.data ?? const [];
  }
}
