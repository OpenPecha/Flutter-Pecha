import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final LocalStorageService localStorageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorageService,
  });

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      await localStorageService.setUserData(userModel.toJson());
      return userModel.toEntity();
    } on NetworkException {
      // If no network, try local storage only
      final userData = await localStorageService.getUserData();
      if (userData != null) {
        return UserModel.fromJson(userData).toEntity();
      }
      throw const NetworkFailure(
        'No internet connection and no local user data',
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on AuthenticationException catch (e) {
      throw AuthenticationFailure(e.message);
    } catch (e) {
      throw UnknownFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // @override
  // Future<void> logout() async {
  //   try {
  //     // Try to logout on server first
  //     await remoteDataSource.logout(allDevices: false);
  //   } catch (e) {
  //     // Continue with local logout even if server logout fails
  //     logger.warning('Server logout failed: $e');
  //   }
  // }
}
