import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

class AuthState {
  final String? accessToken;
  final String? userId;
  final bool loading;
  final String? error;
  final bool socialPending; // indicates awaiting social provider token exchange
  final String? planCode;
  final DateTime? planExpiresAt;
  final bool? planActive;
  const AuthState({this.accessToken, this.userId, this.loading=false, this.error, this.socialPending=false, this.planCode, this.planExpiresAt, this.planActive});
  bool get isAuthenticated => accessToken!=null && accessToken!.isNotEmpty;
  AuthState copyWith({String? accessToken,String? userId,bool? loading,String? error,bool? socialPending,String? planCode,DateTime? planExpiresAt,bool? planActive}) => AuthState(
    accessToken: accessToken ?? this.accessToken,
    userId: userId ?? this.userId,
    loading: loading ?? this.loading,
    error: error,
    socialPending: socialPending ?? this.socialPending,
    planCode: planCode ?? this.planCode,
    planExpiresAt: planExpiresAt ?? this.planExpiresAt,
    planActive: planActive ?? this.planActive,
  );
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref){
  final n = AuthNotifier();
  n.init();
  return n;
});

class AuthNotifier extends StateNotifier<AuthState>{
  AuthNotifier(): super(const AuthState());
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
    receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
  ));
  final AuthService _google = AuthService();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final uid = prefs.getString('auth_uid');
    if(token!=null){
      state = state.copyWith(accessToken: token, userId: uid);
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> signup({String? email,String? mobile, required String password}) async{
    state = state.copyWith(loading:true,error:null);
    try{
      final resp = await _dio.post('/auth/signup', data:{'email':email,'mobile':mobile,'password':password});
      _storeToken(resp.data['access_token'], resp.data['user_id']);
    }catch(e){
      state = state.copyWith(loading:false,error:e.toString());
    }
  }

  Future<void> login({String? email,String? mobile, required String password}) async{
    state = state.copyWith(loading:true,error:null);
    try{
      final resp = await _dio.post('/auth/login', data:{'email':email,'mobile':mobile,'password':password});
      _storeToken(resp.data['access_token'], resp.data['user_id']);
    }catch(e){
      state = state.copyWith(loading:false,error:e.toString());
    }
  }

  Future<void> googleLogin() async {
    state = state.copyWith(loading:true,error:null,socialPending:true);
    try{
      final account = await _google.signInWithGoogle();
      if(account==null){
        state = state.copyWith(loading:false,socialPending:false);
        return;
      }
      final idToken = await _google.currentIdToken();
      if(idToken==null){
        state = state.copyWith(loading:false,error:'Failed to obtain Google idToken',socialPending:false);
        return;
      }
      final resp = await _dio.post('/auth/google', data:{'token': idToken});
      _storeToken(resp.data['access_token'], resp.data['user_id']);
    }catch(e){
      state = state.copyWith(loading:false,error:e.toString(),socialPending:false);
    }
  }

  Future<void> facebookLogin(String accessToken) async {
    state = state.copyWith(loading:true,error:null,socialPending:true);
    try{
      final resp = await _dio.post('/auth/facebook', data:{'token': accessToken});
      _storeToken(resp.data['access_token'], resp.data['user_id']);
    }catch(e){
      state = state.copyWith(loading:false,error:e.toString(),socialPending:false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_uid');
    _dio.options.headers.remove('Authorization');
    state = const AuthState();
  }

  Future<void> _storeToken(String token,String userId) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_uid', userId);
    _dio.options.headers['Authorization'] = 'Bearer $token';
    state = state.copyWith(accessToken: token,userId:userId,loading:false,socialPending:false);
    await refreshUser();
  }

  Future<void> refreshUser() async {
    if(state.accessToken==null) return;
    try{
      final resp = await _dio.get('/auth/me');
      final data = resp.data;
      DateTime? expires;
      if(data['plan_expires_at']!=null){
        expires = DateTime.tryParse(data['plan_expires_at']);
      }
      state = state.copyWith(
        planCode: data['plan_code'],
        planExpiresAt: expires,
        planActive: data['plan_active'] == true,
      );
    }catch(e){
      // keep prior state, attach non-fatal error
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> upgradePlan(String code) async {
    if(!state.isAuthenticated) return;
    state = state.copyWith(loading:true,error:null);
    try{
      final resp = await _dio.post('/plan/upgrade', data:{'code': code});
      final data = resp.data;
      DateTime? expires;
      if(data['plan_expires_at']!=null){
        expires = DateTime.tryParse(data['plan_expires_at']);
      }
      state = state.copyWith(
        loading:false,
        planCode: data['plan_code'],
        planExpiresAt: expires,
        planActive: data['plan_active'] == true,
      );
    }catch(e){
      state = state.copyWith(loading:false,error:e.toString());
    }
  }
}
