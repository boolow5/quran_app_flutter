import 'package:dio/dio.dart';
import 'package:quran_app_flutter/services/auth.dart';

// Initialize ApiService
ApiService apiService = ApiService(
  baseUrl: 'https://api.yourserver.com',
  authService: AuthService(),
);

class ApiService {
  final String baseUrl;
  final AuthService _authService;
  late final Dio _dio;

  ApiService({
    required this.baseUrl,
    required AuthService authService,
  }) : _authService = authService {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      validateStatus: (status) {
        return status! < 500;
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get fresh token before each request
          final token = await _authService.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized error (e.g., force logout)
            await _authService.signOut();
          }
          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  // Generic request method
  Future<T> _request<T>({
    required String path,
    required String method,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
    ResponseConverter<T>? converter,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method).copyWith(
          headers: options?.headers,
          contentType: options?.contentType,
        ),
      );

      // Handle different status codes
      if (response.statusCode == 404) {
        throw NotFoundException('Resource not found');
      }

      if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized');
      }

      if (response.statusCode == 400) {
        throw BadRequestException(
          response.data['message'] ?? 'Bad request',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          response.data['message'] ?? 'Something went wrong',
          response.statusCode,
        );
      }

      // Convert response data if converter is provided
      if (converter != null) {
        return converter(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // GET request
  Future<T> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ResponseConverter<T>? converter,
  }) async {
    return _request<T>(
      path: path,
      method: 'GET',
      queryParameters: queryParameters,
      options: options,
      converter: converter,
    );
  }

  // POST request
  Future<T> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ResponseConverter<T>? converter,
  }) async {
    return _request<T>(
      path: path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      options: options,
      converter: converter,
    );
  }

  // PUT request
  Future<T> put<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ResponseConverter<T>? converter,
  }) async {
    return _request<T>(
      path: path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      options: options,
      converter: converter,
    );
  }

  // PATCH request
  Future<T> patch<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ResponseConverter<T>? converter,
  }) async {
    return _request<T>(
      path: path,
      method: 'PATCH',
      data: data,
      queryParameters: queryParameters,
      options: options,
      converter: converter,
    );
  }

  // DELETE request
  Future<T> delete<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ResponseConverter<T>? converter,
  }) async {
    return _request<T>(
      path: path,
      method: 'DELETE',
      queryParameters: queryParameters,
      options: options,
      converter: converter,
    );
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timeout');
      case DioExceptionType.badResponse:
        return ApiException(
          error.response?.data['message'] ?? 'Something went wrong',
          error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return RequestCancelledException('Request cancelled');
      default:
        return NetworkException('Network error occurred');
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message);
}

class TimeoutException extends ApiException {
  TimeoutException(String message) : super(message);
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class RequestCancelledException extends ApiException {
  RequestCancelledException(String message) : super(message);
}

// Type definition for response converters
typedef ResponseConverter<T> = T Function(dynamic data);