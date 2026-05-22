import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:user_management/pages/account_page.dart';
import 'dart:convert';
import 'ApiService.dart'; // Adjust the path as necessary

void main() {
  runApp(MyApp());
}

// Main Application Widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Data App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
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

    // Basic validation
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

        // Pass the correct username to SalesDataScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SalesDataScreen(
              token: _token!,
              userRole: role,
              username: username, // Correctly pass the username here
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
                // MTN Logo
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
                // Display error message if any
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 24),
                ],
                // GestureDetector for Registration Link
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
    );
  }
}
// Sales Data Screen
class SalesDataScreen extends StatefulWidget {
  final String token;
  final String userRole;
  final String username; // Accepting the username

  SalesDataScreen({required this.token, required this.userRole,required this.username});

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
  List<dynamic> _salesData = [];
  List<dynamic> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _salesDataFuture = ApiService().fetchSalesData(widget.token);
    _loadSalesData(); // Call this method to load data initially

    _salesDataFuture.then((data) {
      if (data != null) {
        _salesData = data;
        _applyRoleBasedFilters();
        _updateFilteredData();
      }
    });
  }
  void _loadSalesData() async {
    try {
      // Fetching sales data
      _salesData = (await ApiService().fetchSalesData(widget.token))!;
      if (_salesData.isNotEmpty) {
        _applyRoleBasedFilters();
        _updateFilteredData();
      }
    } catch (e) {
      print("Error fetching sales data: $e");
      // Optionally, you can show a snackbar or other UI feedback to the user
    }
  }

  void _refreshData() {
    // Call the method to reload data when the refresh button is pressed
    _loadSalesData();
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
          _selectedProvince = _salesData[0]['province'];
        }
        break;

      case 'Channel':
        _selectedDistrict = null;
        _selectedSector = null;
        // Optionally set these values based on a "select all" option in your UI
        break;

      case 'TDR':
        if (_salesData.isNotEmpty && _salesData[0].containsKey('sector')) {
          _selectedSector = _salesData[0]['sector'];
          var matchedItem = _salesData.firstWhere(
                  (item) => item['Sector'] == _selectedSector,
              orElse: () => {'District': null, 'Province': null});
          _selectedDistrict = matchedItem['District'];
          _selectedProvince = matchedItem['Province'];
        }
        break;

      case 'ALL':
        _selectedProvince = null;  // Indicating all provinces are selected
        _selectedDistrict = null;   // Indicating all districts are selected
        _selectedSector = null;     // Indicating all sectors are selected
        print("All options selected for role: ${widget.userRole}");
        break;

      default:
        print("Unknown user role: ${widget.userRole}");
        break;
    }
    void _resetDropdownsToAll() {
      setState(() {
        _selectedProvince = null;  // Null represents "All" in your current logic
        _selectedDistrict = null;
        _selectedSector = null;
      });

      // After resetting, you may want to refresh your data or UI
      _refreshData();  // You'll need to implement this method
    }

    // Call the refresh method to update UI or data based on selections
    _refreshDataBasedOnSelections();
  }

// Method to refresh data based on the selected filters
  void _refreshDataBasedOnSelections() {
    // Example logic for filtering sales data based on selections
    List filteredData = _salesData.where((item) {
      bool matchesProvince = _selectedProvince == null || item['province'] == _selectedProvince;
      bool matchesDistrict = _selectedDistrict == null || item['District'] == _selectedDistrict;
      bool matchesSector = _selectedSector == null || item['Sector'] == _selectedSector;
      return matchesProvince && matchesDistrict && matchesSector;
    }).toList();

    // Update state or UI with the filtered data (you may need to define _filteredSalesData)
    setState(() {
      // Assuming you have a variable for filtered data
      // _filteredSalesData = filteredData; // Example variable to hold filtered results
      print("Filtered Data: $filteredData"); // Print or update the UI accordingly
    });
  }
  void _updateFilteredData() {
    _filteredData = _salesData.where((item) {
      bool matchesProvince = _selectedProvince == null || item['Province']?.toString() == _selectedProvince;
      bool matchesDistrict = _selectedDistrict == null || item['District']?.toString() == _selectedDistrict;
      bool matchesSector = _selectedSector == null || item['Sector']?.toString() == _selectedSector;
      return matchesProvince && matchesDistrict && matchesSector;
    }).toList();

    // Pagination logic
    int totalPages = (_filteredData.length / _rowsPerPage).ceil();
    if (_currentDetailPage >= totalPages) {
      _currentDetailPage = totalPages > 0 ? totalPages - 1 : 0;
    }
    if (_currentSummaryPage >= totalPages) {
      _currentSummaryPage = totalPages > 0 ? totalPages - 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        // Black and Yellow Theme
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
            border: Border(
              bottom: BorderSide(
                color: Colors.yellow,
                width: 3,
              ),
            ),
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
                width: 30, // Adjust logo size
              ),
              SizedBox(width: 8), // Space between logo and title
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
              Tab(
                child: Text(
                  'Performance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Welcome Message
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome ${widget.username}, to, ${widget.userRole} dashboard!',
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
  // Build Details View with the respective dropdown filters based on the role
  Widget _buildDetailsView() {
    return _buildFilteredView((context) {
      return FutureBuilder<List<dynamic>?>(
        future: _salesDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No sales data found.'));
          }

          List<Widget> filterWidgets = _buildFilterWidgets();

          final totalPages = (_filteredData.length / _rowsPerPage).ceil();
          final startIndex = _currentDetailPage * _rowsPerPage;
          final endIndex = (startIndex + _rowsPerPage > _filteredData.length)
              ? _filteredData.length
              : startIndex + _rowsPerPage;
          final currentSalesData = _filteredData.sublist(startIndex, endIndex);

          List<DataColumn> columns = _buildDataColumns(widget.userRole);

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filterWidgets.map((widget) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: widget,
                  )).toList(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: columns,
                    rows: currentSalesData.map<DataRow>((data) {
                      return _buildDataRow(data, widget.userRole);
                    }).toList(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentDetailPage > 0
                        ? () {
                      setState(() {
                        _currentDetailPage--;
                      });
                    }
                        : null,
                    child: Text('Previous'),
                  ),
                  Text('Page ${_currentDetailPage + 1} of $totalPages'),
                  ElevatedButton(
                    onPressed: _currentDetailPage < totalPages - 1
                        ? () {
                      setState(() {
                        _currentDetailPage++;
                      });
                    }
                        : null,
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
        _salesData.map((e) => e['Province'] as String).toSet().toList(),
        _selectedProvince,
            (value) {
          setState(() {
            _selectedProvince = value;
            _selectedDistrict = null;
            _selectedSector = null;
            _updateFilteredData();
          });
        },
      ));
      widgets.add(_buildDropdown(
        'District',
        _filteredData.map((e) => e['District'] as String).toSet().toList(),
        _selectedDistrict,
            (value) {
          setState(() {
            _selectedDistrict = value;
            _selectedSector = null;
            _updateFilteredData();
          });
        },
      ));
      widgets.add(_buildDropdown(
        'Sector',
        _filteredData.map((e) => e['Sector'] as String).toSet().toList(),
        _selectedSector,
            (value) {
          setState(() {
            _selectedSector = value;
            _updateFilteredData();
          });
        },
      ));
    } else if (widget.userRole == 'RM') {
      widgets.add(_buildDropdown(
        'Province',
        _salesData.map((e) => e['Province'] as String).toSet().toList(),
        _selectedProvince,
            (value) {
          setState(() {
            _selectedProvince = value;
            _selectedDistrict = null;
            _selectedSector = null;
            _updateFilteredData();
          });
        },
      ));
      widgets.add(_buildDropdown(
        'District',
        _filteredData.map((e) => e['District'] as String).toSet().toList(),
        _selectedDistrict,
            (value) {
          setState(() {
            _selectedDistrict = value;
            _selectedSector = null;
            _updateFilteredData();
          });
        },
      ));
    } else if (widget.userRole == 'Channel') {
      widgets.add(_buildDropdown(
        'District',
        _filteredData.map((e) => e['District'] as String).toSet().toList(),
        _selectedDistrict,
            (value) {
          setState(() {
            _selectedDistrict = value;
            _selectedSector = null;
            _updateFilteredData();
          });
        },
      ));
      widgets.add(_buildDropdown(
        'Sector',
        _filteredData.map((e) => e['Sector'] as String).toSet().toList(),
        _selectedSector,
            (value) {
          setState(() {
            _selectedSector = value;
            _updateFilteredData();
          });
        },
      ));
    } else if (widget.userRole == 'TDR') {
      widgets.add(_buildDropdown(
        'Sector',
        _filteredData.map((e) => e['Sector'] as String).toSet().toList(),
        _selectedSector,
            (value) {
          setState(() {
            _selectedSector = value;
            _updateFilteredData();
          });
        },
      ));
    }

    return widgets;
  }
  void _resetFiltersToAll() {
    setState(() {
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedSector = null;

      // Make sure to update filtered data after resetting
      _updateFilteredData();
    });

    // Optional: You might want to show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing all data'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  // Dropdown widget
  Widget _buildDropdown(String label, List<String> items, String? selectedValue, void Function(String?)? onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
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
      DataColumn(label: Text('Date', style: TextStyle(color: Colors.white))), // Update the Title color
      DataColumn(label: Text('Agent MSISDN', style: TextStyle(color: Colors.white))),
      DataColumn(label: Text('From Profile', style: TextStyle(color: Colors.white))),
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

    // Common columns
    columns.addAll([
      DataColumn(label: Text('Franchise MSISDN', style: TextStyle(color: Colors.white))),
      DataColumn(label: Text('Franchise Name', style: TextStyle(color: Colors.white))),
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
      DataCell(Text((data['from_profile'] ?? 'N/A').toString())),
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

    // Common cells
    cells.addAll([
      DataCell(Text((data['Franchise_msisdn'] ?? 'N/A').toString())),
      DataCell(Text((data['Franchise_Name'] ?? 'N/A').toString())),
      DataCell(Text((data['Cash_IN_COUNTS']?.toString() ?? '0'))),
      DataCell(Text((data['CASH_IN_AMOUNT']?.toString() ?? '0.00'))),
      DataCell(Text((data['Cash_OUT_COUNTS']?.toString() ?? '0'))),
      DataCell(Text((data['CASH_OUT_AMOUNT']?.toString() ?? '0.00'))),
    ]);

    return DataRow(cells: cells);
  }

  Widget _buildSummaryView() {
    return _buildFilteredView((context) {
      return FutureBuilder<List<dynamic>?>(
        future: _salesDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString(), style: TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No sales data found.', style: TextStyle(color: Colors.white)));
          }

          // Apply filters to salesData
          final salesData = _filteredData; // Use filtered data

          Map<String, Map<String, Map<String, Map<String, dynamic>>>> summaryData = {};

          // Aggregate data for summary
          for (var data in salesData) {
            var province = data['Province'] ?? 'N/A';
            var district = data['District'] ?? 'N/A';
            var sector = data['Sector'] ?? 'N/A';
            var agent = data['Msisdn_Agents'] ?? 'N/A';
            var cashInCount = (data['Cash_IN_COUNTS'] ?? 0).toInt();
            var cashOutCount = (data['Cash_OUT_COUNTS'] ?? 0).toInt();
            var cashInAmount = double.tryParse(data['CASH_IN_AMOUNT'].toString()) ?? 0.0;
            var cashOutAmount = double.tryParse(data['CASH_OUT_AMOUNT'].toString()) ?? 0.0;

            summaryData.putIfAbsent(province, () => {});
            summaryData[province]!.putIfAbsent(district, () => {});
            summaryData[province]![district]!.putIfAbsent(sector, () => {
              'totalAgents': Set<String>(),
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
          List<String> sectors = []; // To hold sector names
          List<double> cashInTotals = []; // To hold total cash in values
          List<double> cashOutTotals = []; // To hold total cash out values

          summaryData.forEach((province, districts) {
            districts.forEach((district, sectorsMap) {
              sectorsMap.forEach((sector, values) {
                rows.add(DataRow(
                  cells: [
                    DataCell(Text(province, style: TextStyle(color: Colors.white))),
                    DataCell(Text(district, style: TextStyle(color: Colors.white))),
                    DataCell(Text(sector, style: TextStyle(color: Colors.white))),
                    DataCell(Text(values['totalAgents'].length.toString(), style: TextStyle(color: Colors.white))),
                    DataCell(Text(values['totalCashInCount'].toString(), style: TextStyle(color: Colors.white))),
                    DataCell(Text(values['totalCashIn'].toStringAsFixed(2), style: TextStyle(color: Colors.white))),
                    DataCell(Text(values['totalCashOutCount'].toString(), style: TextStyle(color: Colors.white))),
                    DataCell(Text(values['totalCashOut'].toStringAsFixed(2), style: TextStyle(color: Colors.white))),
                  ],
                ));
                sectors.add(sector);
                cashInTotals.add(values['totalCashIn']);
                cashOutTotals.add(values['totalCashOut']);
              });
            });
          });

          final totalSummaryPages = (rows.length / _rowsPerPage).ceil();
          final startSummaryIndex = _currentSummaryPage * _rowsPerPage;
          final endSummaryIndex = (startSummaryIndex + _rowsPerPage > rows.length)
              ? rows.length
              : startSummaryIndex + _rowsPerPage;
          final currentSummaryRows = rows.sublist(startSummaryIndex, endSummaryIndex);

          // Sort the cash totals for the graph
          final cashInGraphData = List.generate(sectors.length, (index) => cashInTotals[index])
              .asMap().entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // Sort descending

          final cashOutGraphData = List.generate(sectors.length, (index) => cashOutTotals[index])
              .asMap().entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // Sort descending

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildFilterWidgets().map((widget) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: widget,
                  )).toList(),
                ),
              ),
              SizedBox(height: 16),
              // Bar Chart showing total cash in and cash out amounts
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < sectors.length) {
                              return Text(sectors[value.toInt()], style: TextStyle(color: Colors.white));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(enabled: false),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    barGroups: List.generate(sectors.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: cashInGraphData[index].value,
                            color: Colors.green,
                            width: 20,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: cashOutGraphData[index].value,
                            color: Colors.red,
                            width: 20,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              // Data Table
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Province', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('District', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Sector', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Total Agents', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Total Cash In Count', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Total Cash In Amount', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Total Cash Out Count', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Total Cash Out Amount', style: TextStyle(color: Colors.white))),
                    ],
                    rows: currentSummaryRows.isNotEmpty
                        ? currentSummaryRows
                        : [
                      DataRow(cells: [
                        DataCell(Text('No data', style: TextStyle(color: Colors.white))),
                        DataCell(Text('', style: TextStyle(color: Colors.white))),
                        DataCell(Text('', style: TextStyle(color: Colors.white))),
                        DataCell(Text('0', style: TextStyle(color: Colors.white))),
                        DataCell(Text('0', style: TextStyle(color: Colors.white))),
                        DataCell(Text('0.00', style: TextStyle(color: Colors.white))),
                        DataCell(Text('0', style: TextStyle(color: Colors.white))),
                        DataCell(Text('0.00', style: TextStyle(color: Colors.white))),
                      ]),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentSummaryPage > 0
                        ? () {
                      setState(() {
                        _currentSummaryPage--;
                      });
                    }
                        : null,
                    child: Text('Previous'),
                  ),
                  Text('Page ${_currentSummaryPage + 1} of $totalSummaryPages', style: TextStyle(color: Colors.white)),
                  ElevatedButton(
                    onPressed: _currentSummaryPage < totalSummaryPages - 1
                        ? () {
                      setState(() {
                        _currentSummaryPage++;
                      });
                    }
                        : null,
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
  /// Build the Line Chart with new insights and highest cash flow analysis
  Widget _buildLineChart() {
    return _buildFilteredView((context) {
      return FutureBuilder<List<dynamic>?>(
        future: _salesDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.yellow[700]),
                ));
          } else if (_filteredData.isEmpty) {
            return Center(
                child: Text(
                  'No sales data found for the selected filters.',
                  style: TextStyle(color: Colors.yellow[700]),
                ));
          }

          // Prepare data for line chart
          Map<String, double> totalCashInByDate = {};
          Map<String, double> totalCashOutByDate = {};
          double totalCashInAmount = 0.0;
          double totalCashOutAmount = 0.0;

          // Detailed metrics for highest and lowest points
          double highestCashIn = 0.0;
          double lowestCashIn = double.infinity;
          double highestCashOut = 0.0;
          double lowestCashOut = double.infinity;

          String highestCashInDate = '';
          String lowestCashInDate = '';
          String highestCashOutDate = '';
          String lowestCashOutDate = '';

          for (var item in _filteredData) {
            String dateKey = item['date_key']?.toString() ?? '';
            if (dateKey.isNotEmpty) {
              var datetime = DateTime.parse(dateKey.substring(0, 8) + 'T' + dateKey.substring(8, 10) + ':00:00');
              String formattedDate = DateFormat('dd H').format(datetime);

              double cashIn = double.tryParse(item['CASH_IN_AMOUNT'].toString()) ?? 0.0;
              double cashOut = double.tryParse(item['CASH_OUT_AMOUNT'].toString()) ?? 0.0;

              totalCashInByDate[formattedDate] = (totalCashInByDate[formattedDate] ?? 0) + cashIn;
              totalCashOutByDate[formattedDate] = (totalCashOutByDate[formattedDate] ?? 0) + cashOut;

              totalCashInAmount += cashIn;
              totalCashOutAmount += cashOut;

              if (cashIn > highestCashIn) {
                highestCashIn = cashIn;
                highestCashInDate = formattedDate;
              }
              if (cashIn < lowestCashIn && cashIn > 0) {
                lowestCashIn = cashIn;
                lowestCashInDate = formattedDate;
              }

              if (cashOut > highestCashOut) {
                highestCashOut = cashOut;
                highestCashOutDate = formattedDate;
              }
              if (cashOut < lowestCashOut && cashOut > 0) {
                lowestCashOut = cashOut;
                lowestCashOutDate = formattedDate;
              }
            }
          }

          List<FlSpot> cashInSpots = [];
          List<FlSpot> cashOutSpots = [];
          List<String> sortedDates = totalCashInByDate.keys.toList()..sort();

          // Populate cashInSpots and cashOutSpots for the line chart
          for (int i = 0; i < sortedDates.length; i++) {
            cashInSpots.add(FlSpot(i.toDouble(), totalCashInByDate[sortedDates[i]] ?? 0));
            cashOutSpots.add(FlSpot(i.toDouble(), totalCashOutByDate[sortedDates[i]] ?? 0));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.grey[800],
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < sortedDates.length) {
                                return Text(
                                  sortedDates[value.toInt()],
                                  style: const TextStyle(color: Colors.white),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${NumberFormat.compact().format(value)} FRW',
                                style: const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: cashInSpots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.3)),
                        ),
                        LineChartBarData(
                          spots: cashOutSpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.3)),
                        ),
                      ],
                    ),
                  ),
                ),
                // Display highest and lowest cash flow results
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Flow Summary:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow),
                      ),
                      SizedBox(height: 8),
                      Text('Total Cash In: ${totalCashInAmount.toStringAsFixed(2)} FRW', style: TextStyle(color: Colors.white)),
                      Text('Total Cash Out: ${totalCashOutAmount.toStringAsFixed(2)} FRW', style: TextStyle(color: Colors.white)),
                      SizedBox(height: 16),
                      Text('Highest Cash In: ${highestCashIn.toStringAsFixed(2)} FRW on $highestCashInDate', style: TextStyle(color: Colors.white)),
                      Text('Lowest Cash In: ${lowestCashIn == double.infinity ? 'N/A' : lowestCashIn.toStringAsFixed(2)} FRW on $lowestCashInDate', style: TextStyle(color: Colors.white)),
                      SizedBox(height: 8),
                      Text('Highest Cash Out: ${highestCashOut.toStringAsFixed(2)} FRW on $highestCashOutDate', style: TextStyle(color: Colors.white)),
                      Text('Lowest Cash Out: ${lowestCashOut == double.infinity ? 'N/A' : lowestCashOut.toStringAsFixed(2)} FRW on $lowestCashOutDate', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // Build the filtered view with dropdowns
  Widget _buildFilteredView(Widget Function(BuildContext) builder) {
    return Column(
      children: [
        Expanded(child: builder(context)),
      ],
    );
  }
}