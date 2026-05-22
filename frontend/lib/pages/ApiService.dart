import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String loginUrl = 'http://192.168.10.30/dem/login.php';
  static const String userLocationsUrl = 'http://192.168.10.30/dem/user_accounts.php';
  static const String checkApiUrl = 'http://192.168.10.30/dem/api.php';

  /// **Helper method to safely decode JSON responses**
  Map<String, dynamic>? _safeJsonDecode(http.Response response) {
    try {
      print("Response status: ${response.statusCode}");
      print("Response headers: ${response.headers}");

      if (response.body.trim().startsWith('<')) {
        throw Exception("Server returned HTML instead of JSON.");
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception("Unexpected response format: Not JSON.");
      }

      final decodedData = jsonDecode(response.body) as Map<String, dynamic>;
      return decodedData;
    } catch (e) {
      print("JSON decoding error: $e");
      return null;
    }
  }

  /// **Login API**
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      print("Attempting login for user: $username");

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final responseData = _safeJsonDecode(response);

      if (response.statusCode != 200) {
        throw Exception("Server returned status: ${response.statusCode}");
      }

      if (responseData == null) throw Exception("Invalid response format from server");

      if (responseData['success'] == true) {
        if (!responseData.containsKey('userData')) {
          throw Exception("Missing 'userData' in response.");
        }

        return {
          'username': responseData['userData']['username'] ?? 'Unknown',
          'role': responseData['userData']['role'] ?? 'Unknown',
        };
      } else {
        throw Exception(responseData['message'] ?? "Login failed.");
      }
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  /// **Fetch User Location Data**
  Future<Map<String, String>> fetchUserLocationData(String userId) async {
    try {
      print("Fetching location data for user ID: $userId");

      final response = await http.post(
        Uri.parse(userLocationsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      final responseData = _safeJsonDecode(response);

      if (responseData == null || response.statusCode != 200) {
        throw Exception("Failed to load user location data.");
      }

      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'Unknown error occurred');
      }

      return {
        'province': responseData['location'] ?? '',
        'district': responseData['district'] ?? '',
        'sector': responseData['sector'] ?? '',
        'role': responseData['role'] ?? '',
      };
    } catch (e) {
      print('Error fetching user location data: $e');
      return {'province': '', 'district': '', 'sector': '', 'role': ''};
    }
  }

  /// **Fetch Sales Data**
  Future<List<dynamic>?> fetchSalesData(String token) async {
    try {
      print("Fetching sales data...");

      final response = await http.get(
        Uri.parse(checkApiUrl),
        headers: {"Authorization": token, "Content-Type": "application/json"},
      );

      final responseData = _safeJsonDecode(response);

      if (responseData == null) throw Exception("Invalid response format from server.");

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData['data'];
      } else {
        throw Exception(responseData['message'] ?? "Failed to fetch sales data.");
      }
    } catch (e) {
      print("Sales data fetch error: $e");
      return null;
    }
  }

  /// **Test Connection to Server**
  Future<bool> testConnection() async {
    try {
      print("Testing connection to server...");

      final response = await http.get(
        Uri.parse(loginUrl),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 10));

      print("Connection test status: ${response.statusCode}");

      return response.statusCode == 200;
    } catch (e) {
      print("Connection test failed: $e");
      return false;
    }
  }
}
