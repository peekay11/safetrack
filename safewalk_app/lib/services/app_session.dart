import 'package:flutter/foundation.dart';
import '../models.dart';
import 'api_client.dart';
import 'session_store.dart';

/// App-wide auth/session state. A plain singleton `ChangeNotifier` — no
/// external state management package needed for a session this small.
class AppSession extends ChangeNotifier {
  AppSession._internal();
  static final AppSession instance = AppSession._internal();

  final ApiClient client = ApiClient();
  final SessionStore _store = SessionStore();

  String? _token;
  SWUser? currentUser;
  bool restored = false;

  String? get token => _token;
  bool get isLoggedIn => _token != null;

  /// Loads any previously saved session. Call once at app start.
  Future<void> restore() async {
    final token = await _store.readToken();
    final userJson = await _store.readUser();
    if (token != null && userJson != null) {
      _token = token;
      client.token = token;
      currentUser = SWUser.fromJson(userJson);
    }
    restored = true;
    notifyListeners();
  }

  Future<void> signIn({required String token, required Map<String, dynamic> userJson}) async {
    _token = token;
    client.token = token;
    currentUser = SWUser.fromJson(userJson);
    await _store.save(token, userJson);
    notifyListeners();
  }

  Future<void> updateCurrentUser(Map<String, dynamic> userJson) async {
    currentUser = SWUser.fromJson(userJson);
    if (_token != null) await _store.save(_token!, userJson);
    notifyListeners();
  }

  Future<void> signOut() async {
    _token = null;
    currentUser = null;
    client.token = null;
    await _store.clear();
    notifyListeners();
  }
}
