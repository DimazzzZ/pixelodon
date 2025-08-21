import 'package:dio/dio.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/models/account.dart';

/// Service for handling account-related API calls
class AccountService {
  final ApiService _apiService;
  
  /// Constructor
  AccountService({
    required ApiService apiService,
  }) : _apiService = apiService;
  
  /// Fetch the authenticated user's account
  Future<Account> getVerifyCredentials(String domain) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/accounts/verify_credentials',
      );
      
      return Account.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Fetch an account by ID
  Future<Account> getAccount(String domain, String id) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/accounts/$id',
      );
      
      return Account.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Search for accounts
  Future<List<Account>> searchAccounts(
    String domain, {
    required String query,
    int? limit,
    bool? following,
    bool? resolve,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/accounts/search',
        queryParameters: {
          'q': query,
          if (limit != null) 'limit': limit,
          if (following != null) 'following': following,
          if (resolve != null) 'resolve': resolve,
        },
      );
      
      return (response.data as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Get an account's followers
  Future<List<Account>> getFollowers(
    String domain,
    String id, {
    int? limit,
    String? maxId,
    String? sinceId,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/accounts/$id/followers',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
        },
      );
      
      return (response.data as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Get accounts followed by an account
  Future<List<Account>> getFollowing(
    String domain,
    String id, {
    int? limit,
    String? maxId,
    String? sinceId,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/accounts/$id/following',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
        },
      );
      
      return (response.data as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Follow an account
  Future<Account> followAccount(String domain, String id) async {
    try {
      await _apiService.post(
        'https://$domain/api/v1/accounts/$id/follow',
      );
      // The follow endpoint returns a Relationship, not an Account.
      // To keep the app logic simple, refetch the updated account.
      return await getAccount(domain, id);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Unfollow an account
  Future<Account> unfollowAccount(String domain, String id) async {
    try {
      await _apiService.post(
        'https://$domain/api/v1/accounts/$id/unfollow',
      );
      // The unfollow endpoint returns a Relationship; refetch the account.
      return await getAccount(domain, id);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Block an account
  Future<Account> blockAccount(String domain, String id) async {
    try {
      await _apiService.post(
        'https://$domain/api/v1/accounts/$id/block',
      );
      // The block endpoint returns a Relationship; refetch the account.
      return await getAccount(domain, id);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Unblock an account
  Future<Account> unblockAccount(String domain, String id) async {
    try {
      await _apiService.post(
        'https://$domain/api/v1/accounts/$id/unblock',
      );
      // The unblock endpoint returns a Relationship; refetch the account.
      return await getAccount(domain, id);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Mute an account
  Future<Account> muteAccount(String domain, String id) async {
    try {
      await _apiService.post(
        'https://$domain/api/v1/accounts/$id/mute',
      );
      // The mute endpoint returns a Relationship; refetch the account.
      return await getAccount(domain, id);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Unmute an account
  Future<Account> unmuteAccount(String domain, String id) async {
    try {
      await _apiService.post(
        'https://$domain/api/v1/accounts/$id/unmute',
      );
      // The unmute endpoint returns a Relationship; refetch the account.
      return await getAccount(domain, id);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Update the authenticated user's account
  Future<Account> updateCredentials(
    String domain, {
    String? displayName,
    String? note,
    String? avatar,
    String? header,
    bool? locked,
    bool? bot,
  }) async {
    try {
      var formData = FormData();
      
      if (displayName != null) formData.fields.add(MapEntry('display_name', displayName));
      if (note != null) formData.fields.add(MapEntry('note', note));
      if (locked != null) formData.fields.add(MapEntry('locked', locked.toString()));
      if (bot != null) formData.fields.add(MapEntry('bot', bot.toString()));
      
      final response = await _apiService.patch(
        'https://$domain/api/v1/accounts/update_credentials',
        data: formData,
      );
      
      return Account.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Handle errors
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    return Exception('Failed to perform account operation: $error');
  }
}
