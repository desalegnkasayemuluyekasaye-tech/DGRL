import "dart:convert";
import "package:shared_preferences/shared_preferences.dart";
import "package:http/http.dart" as http;

class AuthService {
  static const String _baseUrl = "http://localhost:3000/api";
  static const String _tokenKey = "jwt_token";
  static const String _loggedInKey = "logged_in_student";

  Future<bool> login(String id, String password, bool isAdmin) async {
    // Offline fallback for admin
    if (isAdmin && id.trim() == "ADMIN" && password == "ADMIN123") {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, "local_admin_token");
        await prefs.setString(
          _loggedInKey,
          jsonEncode({"username": "ADMIN", "role": "admin"}),
        );
        print("Offline admin login successful");
        return true;
      } catch (e) {
        print("Offline login error: $e");
      }
    }

    // Try API
    try {
      final endpoint = isAdmin ? "/auth/admin/login" : "/auth/student/login";
      final body = isAdmin
          ? {"username": id, "password": password}
          : {"studentId": id, "password": password};

      final response = await http.post(
        Uri.parse("$_baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data["token"]);
        await prefs.setString(
          _loggedInKey,
          jsonEncode(data["student"] ?? data["admin"]),
        );
        return true;
      }
      print("API login failed with status: ${response.statusCode}");
    } catch (e) {
      print("API login error: $e");
    }

    return false;
  }
}
