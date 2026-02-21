# core_api

Core API client package with Dio + Retrofit for Flutter Boilerplate.

## Features

- **Dio HTTP Client**: High-performance HTTP client
- **Retrofit**: Type-safe REST API client
- **Auto Authentication**: Automatic Bearer token injection
- **Logging**: Request/Response logging for debugging
- **Dual Backend Support**: Edge Functions and Python Backend

## Usage

### 1. Python Backend API

```dart
final backendDio = ref.watch(backendDioProvider);
final backendClient = BackendApiClient(backendDio);

// Call API
final response = await backendClient.getUserInfo();

if (response.isSuccess) {
  print('User: ${response.data}');
} else {
  print('Error: ${response.error}');
}
```

### 2. Edge Functions API

```dart
final edgeDio = ref.watch(edgeFunctionsDioProvider);
final edgeClient = EdgeFunctionsClient(edgeDio);

// Call Edge Function
final result = await edgeClient.callFunction(
  'my-function',
  {'key': 'value'},
);
```

### 3. Custom API Client

Create your own Retrofit client:

```dart
@RestApi(baseUrl: '/api/v1')
abstract class MyApiClient {
  factory MyApiClient(Dio dio, {String baseUrl}) = _MyApiClient;

  @GET('/users')
  Future<List<User>> getUsers();

  @POST('/users')
  Future<User> createUser(@Body() User user);
}

// Usage
final dio = ref.watch(dioProvider);
final client = MyApiClient(dio);
```

## Architecture

- **DioProvider**: Provides configured Dio instances
  - `dioProvider`: Base Dio with interceptors
  - `edgeFunctionsDioProvider`: For Edge Functions
  - `backendDioProvider`: For Python Backend
- **AuthInterceptor**: Automatically adds Bearer token
- **LoggingInterceptor**: Logs all HTTP traffic
- **ApiResponse**: Standard response wrapper

## Environment Variables

Configure base URLs via environment variables:

```dart
--dart-define=SUPABASE_URL=https://your-project.supabase.co
--dart-define=BACKEND_URL=https://your-backend.com
```

## Dependencies

- `dio`: HTTP client
- `retrofit`: REST API client generator
- `logger`: Logging utility
- `core_auth`: Authentication state access
