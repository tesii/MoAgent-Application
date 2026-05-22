import 'dart:convert';
import 'package:http/http.dart' as http;

class SalesData {
  final int userId;
  final String username;
  final String fullname;
  final String role;
  final String location;
  final int franchiseId;
  final String dateKey;
  final String msisdnAgents;
  final String fromProfile;
  final String province;
  final String district;
  final String sector;
  final String franchiseMsisdn;
  final String franchiseName;
  final int cashInCounts;
  final double cashInAmount;
  final int cashOutCounts;
  final double cashOutAmount;

  SalesData({
    required this.userId,
    required this.username,
    required this.fullname,
    required this.role,
    required this.location,
    required this.franchiseId,
    required this.dateKey,
    required this.msisdnAgents,
    required this.fromProfile,
    required this.province,
    required this.district,
    required this.sector,
    required this.franchiseMsisdn,
    required this.franchiseName,
    required this.cashInCounts,
    required this.cashInAmount,
    required this.cashOutCounts,
    required this.cashOutAmount,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      fullname: json['fullname'] ?? '',
      role: json['role'] ?? '',
      location: json['location'] ?? '',
      franchiseId: json['franchise_id'] ?? 0,
      dateKey: json['date_key'] ?? '',
      msisdnAgents: json['Msisdn_Agents'] ?? '',
      fromProfile: json['from_profile'] ?? '',
      province: json['Province'] ?? '',
      district: json['District'] ?? '',
      sector: json['Sector'] ?? '',
      franchiseMsisdn: json['Franchise_msisdn'] ?? '',
      franchiseName: json['Franchise_Name'] ?? '',
      cashInCounts: json['Cash_IN_COUNTS'] ?? 0,
      cashInAmount: json['CASH_IN_AMOUNT'] ?? 0.0,
      cashOutCounts: json['Cash_OUT_COUNTS'] ?? 0,
      cashOutAmount: json['CASH_OUT_AMOUNT'] ?? 0.0,
    );
  }
}

class UserService {
  final String baseUrl = 'http://localhost/dem/check_location.php';

  Future<List<SalesData>> getSalesByLocation(String location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?location=$location'),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        // Check if there's an error message
        if (decodedData is Map && decodedData.containsKey('error')) {
          throw Exception(decodedData['error']);
        }

        // Parse the list of sales data
        return (decodedData as List)
            .map((item) => SalesData.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load sales data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sales data: $e');
    }
  }
}