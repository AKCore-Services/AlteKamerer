import '../../core/network/api_client.dart';
import 'me.dart';

abstract interface class MeService {
  Future<Me> getMe();
}

class MeApi implements MeService {
  MeApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Me> getMe() async {
    final json = await _apiClient.getJson('/api/v1/me');

    return Me.fromJson(json);
  }
}
