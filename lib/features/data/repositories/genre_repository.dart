import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/genre.dart';

class GenreRepository {
<<<<<<< HEAD
  GenreRepository._() : _api = ApiProvider.client;
  static final GenreRepository instance = GenreRepository._();

  GenreRepository.forTesting(this._api);

  final ApiClient _api;
=======
  GenreRepository._();
  static final GenreRepository instance = GenreRepository._();

  final ApiClient _api = ApiProvider.client;
>>>>>>> 331bf74aa9a34405dfb5f1f8cc7d5a7146acd02a

  Future<List<Genre>> fetchGenres() async {
    final res = await _api.get('/genres');
    final data = ApiClient.decodeList(res);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Genre.fromJson)
        .toList();
  }

  /// Admin: lấy toàn bộ genre (cả inactive).
  Future<List<Map<String, dynamic>>> fetchAllForAdmin() async {
    final res = await _api.get('/genres/admin/all', auth: true);
    final data = ApiClient.decodeList(res);
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> createGenre(Map<String, dynamic> data) async {
    final res = await _api.post('/genres', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Create genre failed',
      );
    }
  }

  Future<void> updateGenre(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/genres/$id', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Update genre failed',
      );
    }
  }

  Future<void> deleteGenre(String id) async {
    final res = await _api.delete('/genres/$id', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Delete genre failed',
      );
    }
  }
}
