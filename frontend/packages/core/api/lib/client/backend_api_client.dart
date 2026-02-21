import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'backend_api_client.g.dart';

/// Python Backend API クライアント (Retrofit)
///
/// TODO: Add API endpoints as needed
@RestApi()
abstract class BackendApiClient {
  factory BackendApiClient(Dio dio, {String baseUrl}) = _BackendApiClient;

  // Add your API endpoints here
  // Example:
  // @GET('/users/{id}')
  // Future<User> getUser(@Path('id') String id);
}
