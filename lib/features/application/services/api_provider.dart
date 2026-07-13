import '../../../core/networks/api_client.dart';
import 'storage_service.dart';

/// Single shared [ApiClient] instance. Points at the same host as the RN app.
class ApiProvider {
  ApiProvider._();

<<<<<<< HEAD
  static const String localIp = '192.168.1.141';
  static const String baseUrl = 'http://${localIp}:9999/api';
=======
  // static const String localIp = '192.168.1.3';
  static const String baseUrl = 'http://localhost:9999/api';
>>>>>>> b6823d82887991fb8ee0e4343f0db1076cc1df5b

  static final ApiClient client = ApiClient(
    baseUrl: baseUrl,
    tokenProvider: StorageService.instance.getToken,
  );
}