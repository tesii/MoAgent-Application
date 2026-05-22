import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform, File;
import 'dart:html' as html; // For web
import 'package:universal_html/html.dart' as html; // For web
import 'pages/ApiService.dart'; // Adjust the path as necessary
import 'pages/account_page.dart'; // Adjust the path as necessary
import 'package:excel/excel.dart' as excel;
import 'package:flutter/foundation.dart' show kIsWeb;
void main() {
  runApp(MyApp());
}

// Main Application Widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Sales Data App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false, // Add this line to remove the DEBUG banner
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _token;
  String? _errorMessage;
  String _location = '';
  String _role = '';

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _login() async {
    final apiService = ApiService();

    if (_usernameController.text.isEmpty) {
      _showSnackBar("Please enter your username.");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar("Password should be at least 6 characters long.");
      return;
    }

    try {
      Map<String, dynamic>? loginResponse = await apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (loginResponse != null && loginResponse['username'] != null) {
        String username = loginResponse['username'];
        String role = loginResponse['role'];

        Map<String, dynamic> locationData = await apiService.fetchUserLocationData(username);

        setState(() {
          _location = [
            locationData['province'],
            locationData['district'],
            locationData['sector']
          ].where((element) => element.isNotEmpty).join(', ');
          _role = role;
        });

        _token = base64.encode(utf8.encode('$username|${_passwordController.text}'));

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SalesDataScreen(
              token: _token!,
              userRole: role,
              username: username,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar("Login failed: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.black],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 350,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/mtn.PNG',
                    width: 100,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.person, color: Colors.yellow),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.lock, color: Colors.yellow),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 24),
                  ],
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserRegistrationForm(),
                        ),
                      );
                    },
                    child: Text(
                      "Don't have an account? Register",
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Sales Data Screen
class SalesDataScreen extends StatefulWidget {
  final String token;
  final String userRole;
  final String username;

  SalesDataScreen({required this.token, required this.userRole, required this.username});

  @override
  _SalesDataScreenState createState() => _SalesDataScreenState();
}

class _SalesDataScreenState extends State<SalesDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>?> _salesDataFuture;

  int _currentDetailPage = 0;
  int _currentSummaryPage = 0;
  final int _rowsPerPage = 10;

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;
  String? _selectedHour;
  String? _selectedMsisdn; // Moved to class level to persist state// Moved to class level to persist state
  List<dynamic> _salesData = [];
  List<dynamic> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSalesData();
  }

  void _loadSalesData() async {
    try {
      print('Loading sales data...');
      _salesDataFuture = ApiService().fetchSalesData(widget.token);
      final data = await _salesDataFuture;
      if (data != null) {
        setState(() {
          _salesData = data;
          _applyRoleBasedFilters();
          _updateFilteredData();
        });
      } else {
        setState(() {
          _salesData = [];
          _filteredData = [];
        });
      }
    } catch (e) {
      print("Error fetching sales data: $e");
      setState(() {
        _salesData = [];
        _filteredData = [];
      });
    }
  }


  void _applyRoleBasedFilters() {
    switch (widget.userRole) {
      case 'SRM':
        _selectedProvince = null;
        _selectedDistrict = null;
        _selectedSector = null;
        break;
      case 'RM':
        if (_salesData.isNotEmpty && _salesData[0].containsKey('province')) {
          _selectedProvince = _salesData[0]['province']?.toString();
        }
        break;
      case 'Channel':
        _selectedDistrict = null;
        _selectedSector = null;
        break;
      case 'TDR':
        if (_salesData.isNotEmpty && _salesData[0].containsKey('sector')) {
          _selectedSector = _salesData[0]['sector']?.toString();
          var matchedItem = _salesData.firstWhere(
                (item) => item['Sector']?.toString() == _selectedSector,
            orElse: () => {'District': null, 'Province': null},
          );
          _selectedDistrict = matchedItem['District']?.toString();
          _selectedProvince = matchedItem['Province']?.toString();
        }
        break;
      case 'ALL':
        _selectedProvince = null;
        _selectedDistrict = null;
        _selectedSector = null;
        print("All options selected for role: ${widget.userRole}");
        break;
      default:
        print("Unknown user role: ${widget.userRole}");
        break;
    }
    _refreshDataBasedOnSelections();
  }

  void _refreshDataBasedOnSelections() {
    setState(() {
      _filteredData = _salesData.where((item) {
        bool matchesProvince = _selectedProvince == null || item['Province']?.toString() == _selectedProvince;
        bool matchesDistrict = _selectedDistrict == null || item['District']?.toString() == _selectedDistrict;
        bool matchesSector = _selectedSector == null || item['Sector']?.toString() == _selectedSector;
        bool matchesMsisdn = _selectedMsisdn == null || item['Msisdn_Agents']?.toString() == _selectedMsisdn;
        return matchesProvince && matchesDistrict && matchesSector && matchesMsisdn;
      }).toList();
    });
  }

  void _updateFilteredData() {
    setState(() {
      _filteredData = _salesData.where((item) {
        bool matchesProvince = _selectedProvince == null || item['Province']?.toString() == _selectedProvince;
        bool matchesDistrict = _selectedDistrict == null || item['District']?.toString() == _selectedDistrict;
        bool matchesSector = _selectedSector == null || item['Sector']?.toString() == _selectedSector;
        bool matchesMsisdn = _selectedMsisdn == null || item['Msisdn_Agents']?.toString() == _selectedMsisdn;
        return matchesProvince && matchesDistrict && matchesSector && matchesMsisdn;
      }).toList();

      int totalPages = (_filteredData.length / _rowsPerPage).ceil();
      if (_currentDetailPage >= totalPages) {
        _currentDetailPage = totalPages > 0 ? totalPages - 1 : 0;
      }
      if (_currentSummaryPage >= totalPages) {
        _currentSummaryPage = totalPages > 0 ? totalPages - 1 : 0;
      }
    });
  }

  // Method to find agent with highest cash-out exceeding cash-in
  Map<String, dynamic>? _getAgentWithHighestCashOutExceedingCashIn() {
    if (_filteredData.isEmpty) return null;

    Map<String, double> agentTotals = {};
    for (var item in _filteredData) {
      String agent = item['Msisdn_Agents']?.toString() ?? 'N/A';
      double cashIn = double.tryParse(item['CASH_IN_AMOUNT']?.toString() ?? '0') ?? 0.0;
      double cashOut = double.tryParse(item['CASH_OUT_AMOUNT']?.toString() ?? '0') ?? 0.0;

      agentTotals[agent] = (agentTotals[agent] ?? 0.0) + cashOut - cashIn;
    }

    String? topAgent;
    double maxDifference = double.negativeInfinity;

    agentTotals.forEach((agent, difference) {
      if (difference > 0 && difference > maxDifference) {
        maxDifference = difference;
        topAgent = agent;
      }
    });

    if (topAgent == null) return null;

    double totalCashIn = 0.0;
    double totalCashOut = 0.0;
    for (var item in _filteredData.where((item) => item['Msisdn_Agents']?.toString() == topAgent)) {
      totalCashIn += double.tryParse(item['CASH_IN_AMOUNT']?.toString() ?? '0') ?? 0.0;
      totalCashOut += double.tryParse(item['CASH_OUT_AMOUNT']?.toString() ?? '0') ?? 0.0;
    }

    return {
      'msisdn': topAgent,
      'totalCashIn': totalCashIn,
      'totalCashOut': totalCashOut,
      'difference': maxDifference,
    };
  }

  // Method to get top 3 sectors by cash-in and cash-out
  Map<String, dynamic> _getTopSectorsByCashFlow() {
    if (_filteredData.isEmpty) {
      return {'topCashIn': [], 'topCashOut': []};
    }

    Map<String, double> cashInBySector = {};
    Map<String, double> cashOutBySector = {};

    for (var data in _filteredData) {
      String sector = data['Sector']?.toString() ?? 'N/A';
      double cashIn = double.tryParse(data['CASH_IN_AMOUNT']?.toString() ?? '0') ?? 0.0;
      double cashOut = double.tryParse(data['CASH_OUT_AMOUNT']?.toString() ?? '0') ?? 0.0;

      cashInBySector[sector] = (cashInBySector[sector] ?? 0.0) + cashIn;
      cashOutBySector[sector] = (cashOutBySector[sector] ?? 0.0) + cashOut;
    }

    var topCashIn = cashInBySector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topCashOut = cashOutBySector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'topCashIn': topCashIn.take(3).toList(),
      'topCashOut': topCashOut.take(3).toList(),
    };
  }

  // Method to calculate average cash-in and cash-out per transaction
  Map<String, double> _getAveragePerTransaction() {
    if (_filteredData.isEmpty) {
      return {'avgCashIn': 0.0, 'avgCashOut': 0.0};
    }

    double totalCashIn = 0.0;
    double totalCashOut = 0.0;
    int cashInCount = 0;
    int cashOutCount = 0;

    for (var data in _filteredData) {
      double cashIn = double.tryParse(data['CASH_IN_AMOUNT']?.toString() ?? '0') ?? 0.0;
      double cashOut = double.tryParse(data['CASH_OUT_AMOUNT']?.toString() ?? '0') ?? 0.0;
      int cashInCounts = data['Cash_IN_COUNTS'] ?? 0;
      int cashOutCounts = data['Cash_OUT_COUNTS'] ?? 0;

      totalCashIn += cashIn;
      totalCashOut += cashOut;
      cashInCount += cashInCounts;
      cashOutCount += cashOutCounts;
    }

    return {
      'avgCashIn': cashInCount > 0 ? totalCashIn / cashInCount : 0.0,
      'avgCashOut': cashOutCount > 0 ? totalCashOut / cashOutCount : 0.0,
    };
  }

  // Method to count unique agents
  int _getUniqueAgentCount() {
    if (_filteredData.isEmpty) return 0;
    return _filteredData.map((data) => data['Msisdn_Agents']?.toString() ?? 'N/A').toSet().length;
  }

  @override
  Widget build(BuildContext context) {
    print('Building SalesDataScreen'); // Debug
    return Theme(
      data: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 10,
          shadowColor: Colors.yellow[700],
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.yellow,
          unselectedLabelColor: Colors.yellow[300],
          indicator: BoxDecoration(
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/mtn.PNG',
                width: 30,
              ),
              SizedBox(width: 8),
              Text(
                'Sales Data',
                style: TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Text(
                  'Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  'Summary',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  'Line Chart',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome ${widget.username}, to ${widget.userRole} dashboard!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsView(),
                  _buildSummaryView(),
                  _buildLineChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    return _buildFilteredView((context) {
      return FutureBuilder<List<dynamic>?>(
        future: _salesDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          } else if (_filteredData.isEmpty) {
            return Center(child: Text('No sales data found.', style: TextStyle(color: Colors.white)));
          }

          // Extract unique hours from date_key for filtering
          Set<String> availableHours = _filteredData
              .map((data) => data['date_key']?.toString().substring(8, 10) ?? 'N/A')
              .toSet();
          List<String> hourOptions = availableHours.toList()..sort();

          return StatefulBuilder(
            builder: (context, setState) {
              // Filter data by selected district and hour
              List<dynamic> filteredData = _filteredData;
              if (_selectedDistrict != null) {
                filteredData = filteredData.where((data) => data['District']?.toString() == _selectedDistrict).toList();
              }
              if (_selectedHour != null) {
                filteredData = filteredData.where((data) {
                  String dateKey = data['date_key']?.toString() ?? '';
                  String hour = dateKey.length >= 10 ? dateKey.substring(8, 10) : 'N/A';
                  return hour == _selectedHour;
                }).toList();
              }

              // Check if filtered data is empty after applying filters
              if (filteredData.isEmpty) {
                return Center(
                  child: Text(
                    'No data found for the selected hour${_selectedHour != null ? ' ($_selectedHour)' : ''} '
                        'and${_selectedDistrict != null ? ' district ($_selectedDistrict)' : ''}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }

              // Summary data processing (Province, District, Sector)
              Map<String, Map<String, Map<String, Map<String, dynamic>>>> summaryData = {};
              for (var data in filteredData) {
                var province = data['Province']?.toString() ?? 'N/A';
                var district = data['District']?.toString() ?? 'N/A';
                var sector = data['Sector']?.toString() ?? 'N/A';
                var agent = data['Msisdn_Agents']?.toString() ?? 'N/A';
                var cashInCount = (data['Cash_IN_COUNTS'] ?? 0).toInt();
                var cashOutCount = (data['Cash_OUT_COUNTS'] ?? 0).toInt();
                var cashInAmount = double.tryParse(data['CASH_IN_AMOUNT']?.toString() ?? '0') ?? 0.0;
                var cashOutAmount = double.tryParse(data['CASH_OUT_AMOUNT']?.toString() ?? '0') ?? 0.0;

                summaryData.putIfAbsent(province, () => {});
                summaryData[province]!.putIfAbsent(district, () => {});
                summaryData[province]![district]!.putIfAbsent(sector, () => {
                  'totalAgents': <String>{},
                  'totalCashInCount': 0,
                  'totalCashOutCount': 0,
                  'totalCashIn': 0.0,
                  'totalCashOut': 0.0,
                });
                summaryData[province]![district]![sector]!['totalAgents'].add(agent);
                summaryData[province]![district]![sector]!['totalCashInCount'] += cashInCount;
                summaryData[province]![district]![sector]!['totalCashOutCount'] += cashOutCount;
                summaryData[province]![district]![sector]!['totalCashIn'] += cashInAmount;
                summaryData[province]![district]![sector]!['totalCashOut'] += cashOutAmount;
              }

              List<DataRow> rows = [];
              summaryData.forEach((province, districts) {
                districts.forEach((district, sectorsMap) {
                  sectorsMap.forEach((sector, values) {
                    // Compare cash-in and cash-out to determine colors
                    double cashInValue = values['totalCashIn'] as double;
                    double cashOutValue = values['totalCashOut'] as double;

                    Color? cashInColor;
                    Color? cashOutColor;

                    if (cashInValue > cashOutValue) {
                      cashInColor = Colors.green; // More cash-in
                      cashOutColor = null; // No color (transparent)
                    } else if (cashInValue < cashOutValue) {
                      cashInColor = null; // No color (transparent)
                      cashOutColor = Colors.red; // More cash-out
                    } else {
                      cashInColor = Colors.yellow; // Equal cash-in and cash-out
                      cashOutColor = Colors.yellow; // Equal cash-in and cash-out
                    }

                    rows.add(DataRow(cells: [
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                          ),
                          child: Text(province, style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                          ),
                          child: Text(district, style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                          ),
                          child: Text(sector, style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                          ),
                          child: Text(values['totalAgents'].length.toString(), style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                          ),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(values['totalCashInCount'].toString(), style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                            color: cashInColor,
                          ),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            values['totalCashIn'].toStringAsFixed(2),
                            style: TextStyle(
                              color: cashInColor != null ? (cashInColor == Colors.yellow ? Colors.black : Colors.white) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                          ),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(values['totalCashOutCount'].toString(), style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                            color: cashOutColor,
                          ),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            values['totalCashOut'].toStringAsFixed(2),
                            style: TextStyle(
                              color: cashOutColor != null ? (cashOutColor == Colors.yellow ? Colors.black : Colors.white) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ]));
                  });
                });
              });

              final totalSummaryPages = (rows.length / _rowsPerPage).ceil();
              final startSummaryIndex = _currentSummaryPage * _rowsPerPage;
              final endSummaryIndex = (startSummaryIndex + _rowsPerPage > rows.length)
                  ? rows.length
                  : startSummaryIndex + _rowsPerPage;
              List<DataRow> currentSummaryRows = [];

              if (startSummaryIndex >= rows.length || startSummaryIndex < 0) {
                currentSummaryRows = [
                  DataRow(cells: [
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('No data available for this page', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ])
                ];
              } else {
                currentSummaryRows = rows.sublist(startSummaryIndex, endSummaryIndex);
              }

              // Time and Sector chart data
              Map<String, Map<String, Map<String, double>>> timeData = {};
              for (var data in filteredData) {
                String dateKey = data['date_key']?.toString() ?? 'N/A';
                String hour = dateKey.length >= 10 ? dateKey.substring(8, 10) : 'N/A';
                String sector = data['Sector']?.toString() ?? 'N/A';
                double cashIn = double.tryParse(data['CASH_IN_AMOUNT']?.toString() ?? '0') ?? 0.0;
                double cashOut = double.tryParse(data['CASH_OUT_AMOUNT']?.toString() ?? '0') ?? 0.0;

                String dateKeyHr = '${dateKey.substring(0, 8)}$hour';
                timeData.putIfAbsent(dateKeyHr, () => {});
                timeData[dateKeyHr]!.putIfAbsent(sector, () => {'cashIn': 0.0, 'cashOut': 0.0});
                timeData[dateKeyHr]![sector]!['cashIn'] = cashIn;
                timeData[dateKeyHr]![sector]!['cashOut'] = cashOut;
              }

              List<String> sortedDateKeys = timeData.keys.toList()..sort();
              List<Widget> timeCharts = [];
              for (String dateKeyHr in sortedDateKeys) {
                final sectorData = timeData[dateKeyHr]!;
                List<BarChartGroupData> barGroups = [];
                int index = 0;
                sectorData.forEach((sector, amounts) {
                  double cashIn = amounts['cashIn'] ?? 0.0;
                  double cashOut = amounts['cashOut'] ?? 0.0;
                  barGroups.add(
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: cashIn,
                          color: Colors.green,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: cashOut,
                          color: Colors.red,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                  index++;
                });

                timeCharts.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${dateKeyHr.substring(0, 8)} Hour: ${dateKeyHr.substring(8, 10)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.yellow),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8,
                                        child: Text(
                                          '${value.toStringAsFixed(0)} FRW',
                                          style: TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      final sectors = sectorData.keys.toList();
                                      if (index >= 0 && index < sectors.length) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 8,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              sectors[index],
                                              style: TextStyle(color: Colors.white, fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              barGroups: barGroups,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Get top agent data
              final topAgent = _getAgentWithHighestCashOutExceedingCashIn();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._buildFilterWidgets().map((widget) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: widget,
                          )),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Text('Filter by Hour: ', style: TextStyle(color: Colors.yellow)),
                                DropdownButton<String>(
                                  value: _selectedHour,
                                  hint: Text('All Hours', style: TextStyle(color: Colors.white)),
                                  dropdownColor: Colors.grey[800],
                                  style: TextStyle(color: Colors.white),
                                  items: [
                                    DropdownMenuItem(value: null, child: Text('All Hours')),
                                    ...hourOptions.map((hour) => DropdownMenuItem(value: hour, child: Text(hour))),
                                  ],
                                  onChanged: (value) => setState(() => _selectedHour = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Top Agent Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Agent Insight',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow),
                          ),
                          SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.yellow.withOpacity(0.5), width: 1),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agent with Highest Cash-Out Exceeding Cash-In',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                if (topAgent == null)
                                  Text(
                                    'No agent found with cash-out exceeding cash-in.',
                                    style: TextStyle(color: Colors.white),
                                  )
                                else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'MSISDN: ${topAgent['msisdn']}',
                                          style: TextStyle(color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Cash-In: ${topAgent['totalCashIn'].toStringAsFixed(2)} FRW',
                                          style: TextStyle(color: Colors.green),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Cash-Out: ${topAgent['totalCashOut'].toStringAsFixed(2)} FRW',
                                          style: TextStyle(color: Colors.red),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Difference: ${topAgent['difference'].toStringAsFixed(2)} FRW',
                                          style: TextStyle(color: Colors.yellow),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Summary Table
                    Text(
                      'Summary by Region',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: DataTable(
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                            verticalInside: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          headingRowColor: MaterialStateProperty.all(Colors.blueGrey[900]),
                          columns: [
                            DataColumn(label: Text('Province', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('District', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Sector', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Agents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Cash In Count', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Cash In Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Cash Out Count', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Cash Out Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                          rows: currentSummaryRows.isNotEmpty
                              ? currentSummaryRows
                              : [
                            DataRow(cells: [
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('No data', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('0', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('0', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('0.00', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('0', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                                  ),
                                  child: Text('0.00', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ])
                          ],
                          dataRowHeight: 56,
                          headingRowHeight: 60,
                          columnSpacing: 24,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _currentSummaryPage > 0 ? () => setState(() => _currentSummaryPage--) : null,
                          child: Text('Previous'),
                        ),
                        Text('Page ${_currentSummaryPage + 1} of $totalSummaryPages',
                            style: TextStyle(color: Colors.white)),
                        ElevatedButton(
                          onPressed: _currentSummaryPage < totalSummaryPages - 1
                              ? () => setState(() => _currentSummaryPage++)
                              : null,
                          child: Text('Next'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Time and Sector Charts
                    Text(
                      'Transactions by Time and Sector',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow),
                    ),
                    SizedBox(height: 16),
                    ...timeCharts,
                  ],
                ),
              );
            },
          );
        },
      );
    });
        }
  Future<void> _downloadDetailsCSV() async {
    if (_filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data available to download')),
      );
      return;
    }

    // Prepare CSV data
    List<List<dynamic>> csvData = [
      _buildCSVHeaders(widget.userRole),
      ..._filteredData.map((data) => _buildCSVRow(data, widget.userRole)),
    ];

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(csvData);

    try {
      if (kIsWeb) {
        // Web platform
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = 'sales_details_${DateTime.now().millisecondsSinceEpoch}.csv'
          ..click();

        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV file downloaded')),
        );
      } else {
        // Mobile or Desktop platforms
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/sales_details_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File(path);
        await file.writeAsString(csv);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV downloaded to $path')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading CSV: $e')),
      );
    }
  }

  List<dynamic> _buildCSVHeaders(String userRole) {
    List<dynamic> headers = [
      'Date',
      'Agent MSISDN',
      'From Profile',
    ];

    switch (userRole) {
      case 'Channel':
        headers.addAll(['District', 'Sector']);
        break;
      case 'TDR':
        headers.add('Sector');
        break;
      case 'SRM':
      case 'RM':
      default:
        headers.addAll(['Province', 'District', 'Sector']);
        break;
    }

    headers.addAll([
      'Franchise MSISDN',
      'Franchise Name',
      'Cash In Counts',
      'Cash In Amount',
      'Cash Out Counts',
      'Cash Out Amount',
    ]);

    return headers;
  }

  List<dynamic> _buildCSVRow(dynamic data, String userRole) {
    List<dynamic> row = [
      data['date_key'] ?? 'N/A',
      data['Msisdn_Agents'] ?? 'N/A',
      data['from_profile'] ?? 'N/A',
    ];

    switch (userRole) {
      case 'Channel':
        row.addAll([
          data['District'] ?? 'N/A',
          data['Sector'] ?? 'N/A',
        ]);
        break;
      case 'TDR':
        row.add(data['Sector'] ?? 'N/A');
        break;
      case 'SRM':
      case 'RM':
      default:
        row.addAll([
          data['Province'] ?? 'N/A',
          data['District'] ?? 'N/A',
          data['Sector'] ?? 'N/A',
        ]);
        break;
    }

    row.addAll([
      data['Franchise_msisdn'] ?? 'N/A',
      data['Franchise_Name'] ?? 'N/A',
      data['Cash_IN_COUNTS']?.toString() ?? '0',
      data['CASH_IN_AMOUNT']?.toString() ?? '0.00',
      data['Cash_OUT_COUNTS']?.toString() ?? '0',
      data['CASH_OUT_AMOUNT']?.toString() ?? '0.00',
    ]);

    return row;
  }

  Widget _buildDetailsView() {
    return _buildFilteredView((context) {
      return FutureBuilder<List<dynamic>?>(
        future: _salesDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Could not load data. Please try again later.',
                      style: TextStyle(color: Colors.white)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.yellow),
                  SizedBox(height: 16),
                  Text('No sales data available.', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          // Filter MSISDNs based on selected Province, District, and Sector
          List<String> availableMsisdns = _salesData
              .where((item) {
            bool matchesProvince = _selectedProvince == null || item['Province']?.toString() == _selectedProvince;
            bool matchesDistrict = _selectedDistrict == null || item['District']?.toString() == _selectedDistrict;
            bool matchesSector = _selectedSector == null || item['Sector']?.toString() == _selectedSector;
            return matchesProvince && matchesDistrict && matchesSector;
          })
              .map((data) => data['Msisdn_Agents']?.toString())
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();

          // Reset _selectedMsisdn if it’s not in the filtered list
          if (_selectedMsisdn != null && !availableMsisdns.contains(_selectedMsisdn)) {
            _selectedMsisdn = null;
            _updateFilteredData(); // Update data to reflect reset
          }

          if (_filteredData.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 48, color: Colors.yellow),
                  SizedBox(height: 16),
                  Text('No data matches the selected filters.', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          int totalPages = (_filteredData.length / _rowsPerPage).ceil();
          _currentDetailPage = _currentDetailPage.clamp(0, max(0, totalPages - 1));
          int startIndex = _currentDetailPage * _rowsPerPage;
          int endIndex = min(startIndex + _rowsPerPage, _filteredData.length);
          List<dynamic> currentSalesData = _filteredData.isNotEmpty ? _filteredData.sublist(startIndex, endIndex) : [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildFilterWidgets()
                        .map((widget) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: widget,
                    ))
                        .toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Agent MSISDN',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                        ),
                        value: _selectedMsisdn,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Agents'),
                          ),
                          ...availableMsisdns.map((msisdn) => DropdownMenuItem<String>(
                            value: msisdn,
                            child: Text(msisdn),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMsisdn = value;
                            _currentDetailPage = 0;
                            _updateFilteredData(); // Apply MSISDN filter immediately
                          });
                        },
                        dropdownColor: Colors.grey[800],
                        style: TextStyle(color: Colors.white),
                        isExpanded: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentDetailPage = 0;
                          _updateFilteredData(); // Reapply all filters including MSISDN
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_selectedMsisdn != null
                                ? 'Showing data for MSISDN: $_selectedMsisdn'
                                : 'Showing all agents for selected location'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: Text('Search'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _buildDataColumns(widget.userRole),
                    rows: currentSalesData.map((data) => _buildDataRow(data, widget.userRole)).toList(),
                  ),
                ),
              ),
              if (_filteredData.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentDetailPage > 0 ? () => setState(() => _currentDetailPage--) : null,
                      child: Text('Previous'),
                    ),
                    Text('Page ${_currentDetailPage + 1} of $totalPages'),
                    ElevatedButton(
                      onPressed: _currentDetailPage < totalPages - 1 ? () => setState(() => _currentDetailPage++) : null,
                      child: Text('Next'),
                    ),
                  ],
                ),
            ],
          );
        },
      );
    });
  }
  // Helper method for generating and downloading CSV
  void _generateAndDownloadCSV(List<dynamic> data) {
    try {
      // Assume this method exists in your class or call the appropriate method
      _downloadDetailsCSV();
    } catch (e) {
      // Show error message if download fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshData() {
    setState(() {
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedSector = null;
      _selectedMsisdn = null; // Ensure MSISDN is reset
      _currentDetailPage = 0;
      _currentSummaryPage = 0;
      _salesDataFuture = ApiService().fetchSalesData(widget.token);
    });
    _loadSalesData(); // This will call _applyRoleBasedFilters and _updateFilteredData
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data refreshed, all filters reset'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  List<Widget> _buildFilterWidgets() {
    final widgets = <Widget>[];
    widgets.add(
      ElevatedButton.icon(
        onPressed: _resetFiltersToAll,
        icon: Icon(Icons.refresh),
        label: Text('View All'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
    widgets.add(SizedBox(width: 10));

    if (widget.userRole == 'SRM') {
      widgets.add(_buildDropdown(
        'Province',
        _salesData.map((e) => e['Province']?.toString() ?? 'N/A').toSet().toList(),
        _selectedProvince,
            (value) => setState(() {
          _selectedProvince = value;
          _selectedDistrict = null;
          _selectedSector = null;
          _updateFilteredData();
        }),
      ));
      widgets.add(_buildDropdown(
        'District',
        _filteredData.map((e) => e['District']?.toString() ?? 'N/A').toSet().toList(),
        _selectedDistrict,
            (value) => setState(() {
          _selectedDistrict = value;
          _selectedSector = null;
          _updateFilteredData();
        }),
      ));
      widgets.add(_buildDropdown(
        'Sector',
        _filteredData.map((e) => e['Sector']?.toString() ?? 'N/A').toSet().toList(),
        _selectedSector,
            (value) => setState(() {
          _selectedSector = value;
          _updateFilteredData();
        }),
      ));
    } else if (widget.userRole == 'RM') {
      widgets.add(_buildDropdown(
        'Province',
        _salesData.map((e) => e['Province']?.toString() ?? 'N/A').toSet().toList(),
        _selectedProvince,
            (value) => setState(() {
          _selectedProvince = value;
          _selectedDistrict = null;
          _selectedSector = null;
          _updateFilteredData();
        }),
      ));
      widgets.add(_buildDropdown(
        'District',
        _filteredData.map((e) => e['District']?.toString() ?? 'N/A').toSet().toList(),
        _selectedDistrict,
            (value) => setState(() {
          _selectedDistrict = value;
          _selectedSector = null;
          _updateFilteredData();
        }),
      ));
    } else if (widget.userRole == 'Channel') {
      widgets.add(_buildDropdown(
        'District',
        _filteredData.map((e) => e['District']?.toString() ?? 'N/A').toSet().toList(),
        _selectedDistrict,
            (value) => setState(() {
          _selectedDistrict = value;
          _selectedSector = null;
          _updateFilteredData();
        }),
      ));
      widgets.add(_buildDropdown(
        'Sector',
        _filteredData.map((e) => e['Sector']?.toString() ?? 'N/A').toSet().toList(),
        _selectedSector,
            (value) => setState(() {
          _selectedSector = value;
          _updateFilteredData();
        }),
      ));
    } else if (widget.userRole == 'TDR') {
      widgets.add(_buildDropdown(
        'Sector',
        _filteredData.map((e) => e['Sector']?.toString() ?? 'N/A').toSet().toList(),
        _selectedSector,
            (value) => setState(() {
          _selectedSector = value;
          _updateFilteredData();
        }),
      ));
    }

    return widgets;
  }

  void _resetFiltersToAll() {
    setState(() {
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedSector = null;
      _selectedMsisdn = null;
      _updateFilteredData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing all data'), duration: Duration(seconds: 2)),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, void Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: DropdownButton<String>(
        hint: Text(label),
        value: selectedValue,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(value),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<DataColumn> _buildDataColumns(String userRole) {
    List<DataColumn> columns = [
      DataColumn(label: Text('Date', style: TextStyle(color: Colors.white))),
      DataColumn(label: Text('Agent Number', style: TextStyle(color: Colors.white))),
    ];

    switch (userRole) {
      case 'Channel':
        columns.addAll([
          DataColumn(label: Text('District', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Sector', style: TextStyle(color: Colors.white))),
        ]);
        break;
      case 'TDR':
        columns.add(DataColumn(label: Text('Sector', style: TextStyle(color: Colors.white))));
        break;
      case 'SRM':
      case 'RM':
      default:
        columns.addAll([
          DataColumn(label: Text('Province', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('District', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Sector', style: TextStyle(color: Colors.white))),
        ]);
        break;
    }

    columns.addAll([

      DataColumn(label: Text('Cash In Counts', style: TextStyle(color: Colors.white))),
      DataColumn(label: Text('Cash In Amount', style: TextStyle(color: Colors.white))),
      DataColumn(label: Text('Cash Out Counts', style: TextStyle(color: Colors.white))),
      DataColumn(label: Text('Cash Out Amount', style: TextStyle(color: Colors.white))),
    ]);

    return columns;
  }

  DataRow _buildDataRow(dynamic data, String userRole) {
    List<DataCell> cells = [
      DataCell(Text((data['date_key'] ?? 'N/A').toString())),
      DataCell(Text((data['Msisdn_Agents'] ?? 'N/A').toString())),
    ];

    switch (userRole) {
      case 'Channel':
        cells.addAll([
          DataCell(Text((data['District'] ?? 'N/A').toString())),
          DataCell(Text((data['Sector'] ?? 'N/A').toString())),
        ]);
        break;
      case 'TDR':
        cells.add(DataCell(Text((data['Sector'] ?? 'N/A').toString())));
        break;
      case 'SRM':
      case 'RM':
      default:
        cells.addAll([
          DataCell(Text((data['Province'] ?? 'N/A').toString())),
          DataCell(Text((data['District'] ?? 'N/A').toString())),
          DataCell(Text((data['Sector'] ?? 'N/A').toString())),
        ]);
        break;
    }

    cells.addAll([

      DataCell(Text((data['Cash_IN_COUNTS']?.toString() ?? '0'))),
      DataCell(Text((data['CASH_IN_AMOUNT']?.toString() ?? '0.00'))),
      DataCell(Text((data['Cash_OUT_COUNTS']?.toString() ?? '0'))),
      DataCell(Text((data['CASH_OUT_AMOUNT']?.toString() ?? '0.00'))),
    ]);

    return DataRow(cells: cells);
  }

  Widget _buildLineChart() {
    // State variables for day filter
    String? _selectedDay;
    List<String> _availableDays = [];

    // Function to extract available days from data
    void _extractAvailableDays() {
      if (_filteredData.isNotEmpty) {
        Set<String> days = {};
        for (var item in _filteredData) {
          String dateKey = item['date_key']?.toString() ?? '';
          if (dateKey.isNotEmpty && dateKey.length >= 10) {
            String dayStr = dateKey.substring(6, 8); // Get the day from date_key
            days.add(dayStr);
          }
        }
        _availableDays = days.toList()..sort();
      }
    }

    // Function to filter data by selected day
    List<dynamic> _filterDataByDay(List<dynamic> data, String? day) {
      if (day == null) return data;
      return data.where((item) {
        String dateKey = item['date_key']?.toString() ?? '';
        if (dateKey.isNotEmpty && dateKey.length >= 10) {
          String dayStr = dateKey.substring(6, 8);
          return dayStr == day;
        }
        return false;
      }).toList();
    }

    return _buildFilteredView((context) {
      return FutureBuilder<List<dynamic>?>(
        future: _salesDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}, Please try again later.', style: TextStyle(color: Colors.yellow[700])));
          } else if (snapshot.data == null) {
            return Center(child: Text('No data retrieved. Please check your connection.', style: TextStyle(color: Colors.yellow[700])));
          } else if (_filteredData.isEmpty) {
            return Center(child: Text('No sales data found for the selected filters.', style: TextStyle(color: Colors.yellow[700])));
          }

          // Extract available days on first load
          if (_availableDays.isEmpty) {
            _extractAvailableDays();
          }

          // Apply day filter if selected
          List<dynamic> dayFilteredData = _filterDataByDay(_filteredData, _selectedDay);

          // If no data after day filtering
          if (dayFilteredData.isEmpty) {
            return Center(child: Text('No data found for the selected day.', style: TextStyle(color: Colors.yellow[700])));
          }

          Map<String, Map<String, double>> cashInByDateRegion = {};
          Map<String, Map<String, double>> cashOutByDateRegion = {};
          double totalCashInAmount = 0.0;
          double totalCashOutAmount = 0.0;
          double highestCashIn = 0.0;
          double lowestCashIn = double.infinity;
          double highestCashOut = 0.0;
          double lowestCashOut = double.infinity;
          String highestCashInDate = '';
          String lowestCashInDate = '';
          String highestCashInRegion = '';
          String lowestCashInRegion = '';
          String highestCashOutDate = '';
          String lowestCashOutDate = '';
          String highestCashOutRegion = '';
          String lowestCashOutRegion = '';

          for (var item in dayFilteredData) {
            String dateKey = item['date_key']?.toString() ?? '';
            if (dateKey.isNotEmpty && dateKey.length >= 10) {
              try {
                var datetime = DateTime.parse(dateKey.substring(0, 8) + 'T' + dateKey.substring(8, 10) + ':00:00');
                String dayStr = dateKey.substring(6, 8); // Get the day from date_key
                String hourStr = dateKey.substring(8, 10); // Get the hour from date_key
                int hour = int.parse(hourStr);
                String amPm = hour < 12 ? 'AM' : 'PM';
                if (hour == 0) hour = 12; // Handle midnight
                else if (hour > 12) hour -= 12; // Convert to 12-hour format

                // Get the ordinal suffix
                String ordinalSuffix;
                if (dayStr.endsWith('1') && dayStr != '11') {
                  ordinalSuffix = 'st';
                } else if (dayStr.endsWith('2') && dayStr != '12') {
                  ordinalSuffix = 'nd';
                } else if (dayStr.endsWith('3') && dayStr != '13') {
                  ordinalSuffix = 'rd';
                } else {
                  ordinalSuffix = 'th';
                }

                String formattedDate = '$dayStr$ordinalSuffix,$hour $amPm'; // Format it as dd, H AM/PM
                String region = item['Sector']?.toString() ?? item['District']?.toString() ?? item['Province']?.toString() ?? 'N/A';
                double cashIn = double.tryParse(item['CASH_IN_AMOUNT']?.toString() ?? '0') ?? 0.0;
                double cashOut = double.tryParse(item['CASH_OUT_AMOUNT']?.toString() ?? '0') ?? 0.0;

                // Round cashIn and cashOut to 2 decimal places
                cashIn = double.parse(cashIn.toStringAsFixed(2));
                cashOut = double.parse(cashOut.toStringAsFixed(2));

                cashInByDateRegion[formattedDate] ??= {};
                cashOutByDateRegion[formattedDate] ??= {};
                cashInByDateRegion[formattedDate]![region] = (cashInByDateRegion[formattedDate]![region] ?? 0) + cashIn;
                cashOutByDateRegion[formattedDate]![region] = (cashOutByDateRegion[formattedDate]![region] ?? 0) + cashOut;
                totalCashInAmount += cashIn;
                totalCashOutAmount += cashOut;

                // Track highest and lowest cash in and out
                if (cashIn > highestCashIn) {
                  highestCashIn = cashIn;
                  highestCashInDate = formattedDate;
                  highestCashInRegion = region;
                }
                if (cashIn < lowestCashIn && cashIn != 0) { // Permit zero
                  lowestCashIn = cashIn;
                  lowestCashInDate = formattedDate;
                  lowestCashInRegion = region;
                }
                if (cashOut > highestCashOut) {
                  highestCashOut = cashOut;
                  highestCashOutDate = formattedDate;
                  highestCashOutRegion = region;
                }
                if (cashOut < lowestCashOut && cashOut != 0) { // Permit zero
                  lowestCashOut = cashOut;
                  lowestCashOutDate = formattedDate;
                  lowestCashOutRegion = region;
                }
              } catch (e) {
                // Handle Date parsing error
                return Center(child: Text('Date format error for entry: $item, Please check the data.', style: TextStyle(color: Colors.yellow[700])));
              }
            }
          }

          // Round totals to 2 decimal places
          totalCashInAmount = double.parse(totalCashInAmount.toStringAsFixed(2));
          totalCashOutAmount = double.parse(totalCashOutAmount.toStringAsFixed(2));
          highestCashIn = double.parse(highestCashIn.toStringAsFixed(2));
          if (lowestCashIn != double.infinity) lowestCashIn = double.parse(lowestCashIn.toStringAsFixed(2));
          highestCashOut = double.parse(highestCashOut.toStringAsFixed(2));
          if (lowestCashOut != double.infinity) lowestCashOut = double.parse(lowestCashOut.toStringAsFixed(2));

          List<FlSpot> cashInSpots = [];
          List<FlSpot> cashOutSpots = [];
          List<String> sortedDates = cashInByDateRegion.keys.toList()..sort((a, b) => a.compareTo(b));
          double maxY = 0.0;
          double minY = 0.0; // Initialize minY to allow negatives

          for (int i = 0; i < sortedDates.length; i++) {
            double totalCashIn = cashInByDateRegion[sortedDates[i]]!.values.reduce((a, b) => a + b);
            double totalCashOut = cashOutByDateRegion[sortedDates[i]]!.values.reduce((a, b) => a + b);
            // Round chart data to 2 decimal places
            totalCashIn = double.parse(totalCashIn.toStringAsFixed(2));
            totalCashOut = double.parse(totalCashOut.toStringAsFixed(2));
            cashInSpots.add(FlSpot(i.toDouble(), totalCashIn));
            cashOutSpots.add(FlSpot(i.toDouble(), totalCashOut));
            maxY = max(maxY, max(totalCashIn, totalCashOut));
            minY = min(minY, min(totalCashIn, totalCashOut)); // Calculate minimum including negatives
          }

          return StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Filter Dropdown
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            'Filter by Day: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                            ),
                          ),
                          SizedBox(width: 16),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.yellow, width: 1),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedDay,
                              hint: Text('Select Day', style: TextStyle(color: Colors.yellow[200])),
                              dropdownColor: Colors.grey[800],
                              style: TextStyle(color: Colors.white),
                              icon: Icon(Icons.arrow_drop_down, color: Colors.yellow),
                              underline: SizedBox(), // Remove underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDay = newValue;
                                });
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Days', style: TextStyle(color: Colors.white)),
                                ),
                                ..._availableDays.map<DropdownMenuItem<String>>((String day) {
                                  return DropdownMenuItem<String>(
                                    value: day,
                                    child: Text(day, style: TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cash Flow Summary Section (above the chart)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash Flow Summary',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Total Cash In
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Cash In',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          NumberFormat.currency(symbol: 'FRW ', decimalDigits: 2).format(totalCashInAmount),
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Total Cash Out
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Cash Out',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          NumberFormat.currency(symbol: 'FRW ', decimalDigits: 2).format(totalCashOutAmount),
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Highest Cash In
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trending_up, color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Highest Cash In',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '${NumberFormat.currency(symbol: 'FRW ', decimalDigits: 2).format(highestCashIn)} on $highestCashInDate in $highestCashInRegion',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Lowest Cash In
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trending_down, color: Colors.green[300], size: 20),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lowest Cash In',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          lowestCashIn == double.infinity ? 'N/A' : '${NumberFormat.currency(symbol: 'FRW ', decimalDigits: 2).format(lowestCashIn)} on $lowestCashInDate in $lowestCashInRegion',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Highest Cash Out
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trending_up, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Highest Cash Out',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '${NumberFormat.currency(symbol: 'FRW ', decimalDigits: 2).format(highestCashOut)} on $highestCashOutDate in $highestCashOutRegion',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Lowest Cash Out
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trending_down, color: Colors.red[300], size: 20),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lowest Cash Out',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          lowestCashOut == double.infinity ? 'N/A' : '${NumberFormat.currency(symbol: 'FRW ', decimalDigits: 2).format(lowestCashOut)} on $lowestCashOutDate in $lowestCashOutRegion',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Chart Section
                    Container(
                      height: 500,
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.yellow.withOpacity(0.2), spreadRadius: 2, blurRadius: 8),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: max(800, sortedDates.length * 100.0),
                          child: LineChart(
                            LineChartData(
                              backgroundColor: Colors.grey[900],
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.3),
                                  strokeWidth: 1,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.3),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      int index = value.toInt();
                                      if (index >= 0 && index < sortedDates.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: RotatedBox(
                                            quarterTurns: 0,
                                            child: Text(
                                              sortedDates[index],
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        );
                                      }
                                      return Container();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    interval: (maxY - minY) / 10,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        NumberFormat('#,##0.00').format(value),
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              minY: double.parse((minY * 1.1).toStringAsFixed(2)),
                              maxY: double.parse((maxY * 1.1).toStringAsFixed(2)),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: cashInSpots,
                                  isCurved: true,
                                  color: Colors.greenAccent,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.greenAccent.withOpacity(0.2),
                                  ),
                                ),
                                LineChartBarData(
                                  spots: cashOutSpots,
                                  isCurved: true,
                                  color: Colors.redAccent,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.redAccent.withOpacity(0.2),
                                  ),
                                ),
                              ],
                              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }
  // Helper method to get ordinal suffix (unchanged)
  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
  Widget _buildSummaryContainer(
      double totalCashInAmount,
      double totalCashOutAmount,
      double highestCashIn,
      String highestCashInDate,
      String highestCashInRegion,
      double lowestCashIn,
      String lowestCashInDate,
      String lowestCashInRegion,
      double highestCashOut,
      String highestCashOutDate,
      String highestCashOutRegion,
      double lowestCashOut,
      String lowestCashOutDate,
      String lowestCashOutRegion) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        //  border: Border.all(color: Colors.yellow.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cash Flow Summary:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10, width: 14),
          Text('Total Cash In: ${NumberFormat.currency(symbol: 'FRW ').format(totalCashInAmount)}', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('Total Cash Out: ${NumberFormat.currency(symbol: 'FRW ').format(totalCashOutAmount)}', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 24),
          Text('Highest Cash In:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          Text('${NumberFormat.currency(symbol: 'FRW ').format(highestCashIn)} on $highestCashInDate', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('Region: $highestCashInRegion', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 12),
          Text('Lowest Cash In:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.withOpacity(0.7))),
          Text('${lowestCashIn == double.infinity ? 'N/A' : NumberFormat.currency(symbol: 'FRW ').format(lowestCashIn)} on $lowestCashInDate', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('Region: $lowestCashInRegion', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 24),
          Text('Highest Cash Out:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          Text('${NumberFormat.currency(symbol: 'FRW ').format(highestCashOut)} on $highestCashOutDate', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('Region: $highestCashOutRegion', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 12),
          Text('Lowest Cash Out:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.withOpacity(0.7))),
          Text('${lowestCashOut == double.infinity ? 'N/A' : NumberFormat.currency(symbol: 'FRW ').format(lowestCashOut)} on $lowestCashOutDate', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('Region: $lowestCashOutRegion', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGraphLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(width: 16, height: 4, color: Colors.green),
              SizedBox(width: 8),
              Text('Cash In', style: TextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(width: 24),
          Row(
            children: [
              Container(width: 16, height: 4, color: Colors.red),
              SizedBox(width: 8),
              Text('Cash Out', style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFilteredView(Widget Function(BuildContext) builder) {
    return Column(
      children: [
        Expanded(child: builder(context)),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
