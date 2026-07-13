import '../../../core/networks/api_client.dart';
import 'storage_service.dart';

/// Single shared [ApiClient] instance. Points at the same host as the RN app.
class ApiProvider {
  ApiProvider._();

  static const String localIp = '192.168.1.3';
  static const String baseUrl = 'http://$localIp:9999/api';

  static final ApiClient client = ApiClient(
    baseUrl: baseUrl,
    tokenProvider: StorageService.instance.getToken,
  );
}