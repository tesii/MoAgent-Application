import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Base URLs
  static const String baseUrl = 'http://192.168.10.30/dem/franchises.php';
  static const String loginUrl = 'http://192.168.10.30/dem/login.php';
  static const String createAccountUrl = 'http://192.168.10.30/dem/create_account.php';
  static const String userAccountsUrl = 'http://192.168.10.30/dem/user_accounts.php';
  static const String salesDataUrl = 'http://192.168.10.30/dem/get_sales_data.php';
  static const String filteredSalesDataUrl = 'http://192.168.10.30/dem/check_franchise_exists.php'; // Added new URL
  static const String checkLocationUrl = 'http://192.168.10.30/dem/check_location.php';
  static const String checkApiUrl = 'http://192.168.10.30/dem/api.php'; //using this

  static const Duration timeoutDuration = Duration(seconds: 60);
  Future<dynamic> checkApi(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse(checkApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during API request: $e');
      throw Exception('API request failed: $e');
    }
  }

  Future<Map<String, dynamic>> fetchSalesDataByUserLocation(
      String username, String password) async {
    try {
      final response = await checkApi({
        'username': username,
        'password': password,
        'action': 'getSalesByUserLocation',
      });

      if (response is Map) {
        if (response['error'] != null) {
          throw Exception(response['error']);
        } else if (response['salesData'] != null && response['userData'] != null) {
          // Explicitly cast the keys to String:
          return response.map((key, value) => MapEntry(key.toString(), value));
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      print('Error fetching sales data by user location: $e');
      throw Exception('Failed to fetch sales data: $e');
    }
  }
  Future<Map<String, dynamic>> fetchUserLocationData(String userId) async {
    const String userLocationsUrl = 'http://localhost/dem/user_accounts.php';

    try {
      final response = await http.post(
        Uri.parse(userLocationsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}), // Send the userId in the request
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(response.body);

        if (userData['success'] != null && userData['success'] == false) {
          throw Exception(userData['message']);
        }

        return {
          'province': userData['location'] ?? '',
          'district': userData['district'] ?? '', // Adjust to match your location structure
          'sector': userData['sector'] ?? '', // Adjust to match your location structure
          'role': userData['role']
        };
      } else {
        throw Exception('Failed to load user location data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user location data: $e');
      return {
        'province': '',
        'district': '',
        'sector': ''
      };
    }
  }
  // Method to fetch provinces, districts, and sectors from sales data
  Future<Map<String, List<String>>> fetchLocationData(userData) async {
    try {
      // Assuming the sales data URL returns all the necessary data
      final salesResponse = await http.get(Uri.parse(salesDataUrl)).timeout(timeoutDuration);

      if (salesResponse.statusCode == 200) {
        final List<dynamic> salesData = jsonDecode(salesResponse.body);

        // Initialize sets to hold unique provinces, districts, and sectors
        Set<String> provinces = {};
        Set<String> districts = {};
        Set<String> sectors = {};

        for (var item in salesData) {
          if (item['Province'] != null) {
            provinces.add(item['Province'].toString());
          }
          if (item['District'] != null) {
            districts.add(item['District'].toString());
          }
          if (item['Sector'] != null) {
            sectors.add(item['Sector'].toString());
          }
        }

        return {
          'provinces': provinces.toList()..sort(),
          'districts': districts.toList()..sort(),
          'sectors': sectors.toList()..sort(),
        };
      } else {
        throw Exception('Failed to load sales data: ${salesResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching location data: $e');
      return {
        'provinces': [],
        'districts': [],
        'sectors': [],
      };
    }
  }
  Future<List<dynamic>> fetchSalesDatal(String username) async {
    try {
      final salesResponse = await http.get(
          Uri.parse(checkApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': username // Using username as a simple token
          }
      ).timeout(timeoutDuration);

      final responseData = jsonDecode(salesResponse.body);

      if (responseData['success']) {
        return responseData['data'];
      }
      throw Exception('Failed to load sales data');
    } on TimeoutException {
      throw Exception('Request timed out');
    } on http.ClientException {
      throw Exception('Network error');
    } catch (e) {
      throw Exception('Failed to load sales data: ${e.toString()}');
    }
  }

  Future<List<String>> fetchSalesData(int currentPage, int rowsPerPage) async {
    return await _fetchData(salesDataUrl, 'Failed to load sales data', isJsonList: true);
  }
  Future<List<Map<String, dynamic>>> fetchSalesDataDropdown(int currentPage, int rowsPerPage) async {
    try {
      final response = await http.get(Uri.parse(salesDataUrl)).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
      } else {
        throw Exception('Failed to load sales data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sales data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFranchiseNames(List<String> locationParts) async {
    const String franchiseNameUrl = 'http://localhost/dem/check_franchise_exists.php';

    try {
      final response = await http.post(
        Uri.parse(franchiseNameUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'province': locationParts.isNotEmpty ? locationParts[0] : '',
          'district': locationParts.length > 1 ? locationParts[1] : '',
          'sector': locationParts.length > 2 ? locationParts[2] : '',
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data.map((item) => Map<String, dynamic>.from(item))
        );
      } else {
        throw Exception('Failed to load franchise names: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching franchise names: $e');
      throw Exception('Error fetching franchise names');
    }
  }

  Future<String?> login(String username, String password) async {
    final response = await http.post(
        Uri.parse('http://localhost/dem/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password
        })
    );

    final responseData = jsonDecode(response.body);

    if (responseData['success']) {
      // The token is generated server-side and returned in the login response
      return responseData['userData']['username']; // or a specific token
    }
    return null;
  }


  // Helper method to save user data
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Helper method to get user data
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        return jsonDecode(userDataString);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return {};
  }

  // Helper method to check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Helper method to logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('user_data');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<List<String>> fetchProvinces() async {
    return await _fetchData('$baseUrl?type=provinces', 'Failed to load provinces');
  }

  Future<List<String>> fetchDistricts(String province) async {
    return await _fetchData('$baseUrl?type=districts&province=${Uri.encodeComponent(province)}', 'Failed to load districts');
  }

  Future<List<String>> fetchSectors(String district) async {
    return await _fetchData('$baseUrl?type=sectors&district=${Uri.encodeComponent(district)}', 'Failed to load sectors');
  }

  Future<List<String>> fetchUserLocations() async {
    return await _fetchData(userAccountsUrl, 'Failed to load user locations', isJsonList: true);
  }

  Future<List<String>> fetchFranchiseMsisdnHash(String location) async {
    final url = '$baseUrl?type=franchise_msisdn_hash&location=${Uri.encodeComponent(location)}';
    try {
      final response = await _getRequest(url);
      return _processFetchFranchiseResponse(response);
    } catch (e) {
      print('Exception in fetchFranchiseMsisdnHash: $e');
      return [];
    }
  }

  Future<String> createAccount(String username, String fullname, String password, String role, String location, String franchiseId) async {
    // Role validation logic
    List<String> validRoles = ['SRM', 'RM', 'Channel', 'TDR']; // Define valid roles

    if (!validRoles.contains(role)) {
      return 'Error: Invalid user role selected';
    }

    if (franchiseId.isEmpty) {
      return 'Error: No franchise ID selected';
    }

    final payload = {
      'username': username,
      'fullname': fullname,
      'password': password,
      'role': role,
      'location': location,
      'franchise_id': franchiseId,
    };

    try {
      final response = await _postRequest(createAccountUrl, payload);
      return _handleResponse(response, 'User creation failed.');
    } catch (e) {
      print('Error creating account: $e');
      return 'An error occurred while creating the account: $e';
    }
  }

  Future<List<String>> _fetchData(String url, String errorMessage, {bool isJsonList = false}) async {
    try {
      final response = await _getRequest(url);
      return _processFetchResponse(response, errorMessage, isJsonList);
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  // Network request methods
  Future<http.Response> _getRequest(String url) async {
    try {
      return await http.get(Uri.parse(url)).timeout(timeoutDuration);
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException catch (_) {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Some error occurred: $e');
    }
  }

  Future<http.Response> _postRequest(String url, Map<String, dynamic> payload) async {
    try {
      return await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(timeoutDuration);
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException catch (_) {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Some error occurred: $e');
    }
  }

  // Response processing methods
  List<String> _processFetchResponse(http.Response response, String errorMessage, bool isJsonList) {
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return isJsonList
          ? data.map((item) => item['location'].toString()).toList()
          : List<String>.from(data.map((item) => item.toString()));
    } else {
      print('$errorMessage - HTTP Status Code: ${response.statusCode}');
      return [];
    }
  }

  List<String> _processFetchFranchiseResponse(http.Response response) {
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<String>.from(data.map((item) => item.toString()));
    } else {
      print('Failed to load franchise IDs - HTTP Status Code: ${response.statusCode}');
      return [];
    }
  }

  Map<String, dynamic> _handleLoginResponse(http.Response response) {
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Login failed',
        'userData': result['userData'] ?? {}
      };
    }
    return {'success': false, 'message': 'Login failed'};
  }

  String _handleResponse(http.Response response, String errorMessage) {
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['message'] ?? 'Success';
    } else {
      throw Exception(errorMessage);
    }
  }
}