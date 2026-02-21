import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'edge_functions_client.g.dart';

/// Supabase Edge Functions APIクライアント (Retrofit)
///
/// TODO: Add Edge Function endpoints as needed
@RestApi()
abstract class EdgeFunctionsClient {
  factory EdgeFunctionsClient(Dio dio, {String baseUrl}) = _EdgeFunctionsClient;

  // Add your Edge Function endpoints here
  // Example:
  // @POST('/my-function')
  // Future<MyResponse> myFunction(@Body() MyRequest body);
}
