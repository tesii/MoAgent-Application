import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:user_management/pages/api_service.dart'; // Adjust according to your file structure
import 'package:csv/csv.dart';

class SummaryData {
  double cashIn = 0;
  double cashOut = 0;
  int cashInCount = 0;
  int cashOutCount = 0;
}

class Dmdashboard extends StatefulWidget {
  final UserService userService; // Assuming you have a service class
  final Map<String, dynamic> userData; // Passed userData containing role
  final List<String> franchiseIds;
  final Map<String, bool> franchiseStatus;
  final Map<String, String?> franchiseNames;
  final Map<String, dynamic> salesData;

  Dmdashboard({
    required this.userService,
    required this.userData,
    required this.franchiseIds,
    required this.franchiseStatus,
    required this.franchiseNames,
    required this.salesData,
  });

  @override
  _RMDashboardState createState() => _RMDashboardState();
}

class _RMDashboardState extends State<Dmdashboard> with SingleTickerProviderStateMixin {
  int currentPage = 0;
  int rowsPerPage = 10;
  int totalPages = 0;

  List<String> _allSectors = [];
  List<String> _allDistricts = [];
  List<String> _allProvinces = [];

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;

  bool _isLoading = true;
  String _userRole = '';

  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _filteredData = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userRole = widget.userData['role'] ?? 'RM'; // Get user role from userData
    _fetchAndAnalyzeData();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check that the role is read correctly
    debugPrint("User Role: $_userRole");
  }
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: currentPage > 0
              ? () {
            setState(() {
              currentPage--;
              _updateFilteredData(); // Refresh the data after changing the page
            });
          }
              : null,
        ),
        Text('Page ${currentPage + 1} of $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: currentPage < totalPages - 1
              ? () {
            setState(() {
              currentPage++;
              _updateFilteredData(); // Refresh the data after changing the page
            });
          }
              : null,
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Regional Manager Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Summary'),
            Tab(text: 'Details'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Summary Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSummaryTable(),
                      _buildLineChart(),
                    ],
                  ),
                ),
                // Details Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSalesDataTable(),
                      _buildPagination(),
                    ],
                  ),
                ),
                // Analytics Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildLineChart(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndAnalyzeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.userService.fetchSalesData(currentPage, rowsPerPage);
      if (response.isNotEmpty) {
        _salesData = List<Map<String, dynamic>>.from(response);
        _extractRegions();
        _applyRoleBasedFilters();
        _updateFilteredData();
      } else {
        debugPrint("No sales data fetched.");
      }
    } catch (error) {
      _showErrorDialog('Data Fetching Error', error.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _extractRegions() {
    Set<String> sectors = {};
    Set<String> districts = {};
    Set<String> provinces = {};

    // Loop through sales data to extract unique regions
    for (var item in _salesData) {
      if (item['Sector'] != null && item['Sector'].toString().isNotEmpty) {
        sectors.add(item['Sector'].toString());
      }
      if (item['District'] != null && item['District'].toString().isNotEmpty) {
        districts.add(item['District'].toString());
      }
      if (item['Province'] != null && item['Province'].toString().isNotEmpty) {
        provinces.add(item['Province'].toString());
      }
    }

    // Sort and assign unique values to filters
    _allSectors = sectors.toList()..sort();
    _allDistricts = districts.toList()..sort();
    _allProvinces = provinces.toList()..sort();
  }

  void _applyRoleBasedFilters() {
    // Apply initial filters based on user role
    debugPrint("Applying role-based filters for role: $_userRole");
    switch (_userRole) {
      case 'SRM':
      // Senior Regional Manager sees all data, do nothing.
        break;
      case 'RM':
      // Regional Manager sees only their province
        if (widget.userData.containsKey('province')) {
          _selectedProvince = widget.userData['province'];
        }
        break;
      case 'Channel':
      // Channel manager sees only their district
        if (widget.userData.containsKey('district')) {
          _selectedDistrict = widget.userData['district'];
          // Set Province based on District
          _selectedProvince = _salesData.firstWhere(
                  (item) => item['District'] == _selectedDistrict,
              orElse: () => {'Province': null}
          )['Province'];
        }
        break;
      case 'TDR':
      // TDR sees only their sector
        if (widget.userData.containsKey('sector')) {
          _selectedSector = widget.userData['sector'];
          // Set District and Province based on Sector
          var matchedItem = _salesData.firstWhere(
                  (item) => item['Sector'] == _selectedSector,
              orElse: () => {'District': null, 'Province': null}
          );

          _selectedDistrict = matchedItem['District'];
          _selectedProvince = matchedItem['Province'];
        }
        break;
      default:
        debugPrint("Unknown user role: $_userRole");
        break;
    }

    debugPrint("Selected Province: $_selectedProvince, District: $_selectedDistrict, Sector: $_selectedSector");
  }

  void _updateFilteredData() {
    _filteredData = _salesData.where((item) {
      bool matchesProvince = _selectedProvince == null ||
          item['Province']?.toString() == _selectedProvince;
      bool matchesDistrict = _selectedDistrict == null ||
          item['District']?.toString() == _selectedDistrict;
      bool matchesSector = _selectedSector == null ||
          item['Sector']?.toString() == _selectedSector;
      return matchesProvince && matchesDistrict && matchesSector;
    }).toList();

    totalPages = (_filteredData.length / rowsPerPage).ceil();
    if (currentPage >= totalPages && totalPages > 0) {
      currentPage = totalPages - 1; // Adjust current page
    }
  }

  // Method to get data summary
  List<Map<String, dynamic>> _getSummaryData() {
    Map<String, Map<String, dynamic>> summaryMap = {};

    for (var item in _filteredData) {
      String dateKey = item['date_key'].toString();
      double cashIn = (item['CASH_IN_AMOUNT'] is double)
          ? item['CASH_IN_AMOUNT']
          : double.tryParse(item['CASH_IN_AMOUNT'].toString()) ?? 0.0;

      double cashOut = (item['CASH_OUT_AMOUNT'] is double)
          ? item['CASH_OUT_AMOUNT']
          : double.tryParse(item['CASH_OUT_AMOUNT'].toString()) ?? 0.0;

      if (!summaryMap.containsKey(dateKey)) {
        summaryMap[dateKey] = {
          'date_key': dateKey,
          'total_agents': 0,
          'total_cash_in': 0.0,
          'total_cash_out': 0.0,
          'total_cash_in_count': 0,
          'total_cash_out_count': 0,
        };
      }

      summaryMap[dateKey]!['total_agents'] += 1; // Increment agent count
      summaryMap[dateKey]!['total_cash_in'] += cashIn;
      summaryMap[dateKey]!['total_cash_out'] += cashOut;
      summaryMap[dateKey]!['total_cash_in_count'] += cashIn;
      summaryMap[dateKey]!['total_cash_out_count'] += cashOut;
    }

    return summaryMap.values.toList();
  }

  // Method to get paginated data for sales data table
  List<Map<String, dynamic>> _getPaginatedData() {
    if (_filteredData.isEmpty) return [];
    int startIndex = currentPage * rowsPerPage;
    int endIndex = min(startIndex + rowsPerPage, _filteredData.length);
    return _filteredData.sublist(startIndex, endIndex);
  }

  // Method to build the sales data table
  Widget _buildSalesDataTable() {
    final paginatedData = _getPaginatedData();

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all<Color>(Colors.yellow),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Msisdn Agents')),
            DataColumn(label: Text('From Profile')),
            DataColumn(label: Text('Province')),
            DataColumn(label: Text('District')),
            DataColumn(label: Text('Sector')),
            DataColumn(label: Text('Franchise Msisdn')),
            DataColumn(label: Text('Franchise Name')),
            DataColumn(label: Text('Cash IN Counts')),
            DataColumn(label: Text('Cash IN Amount')),
            DataColumn(label: Text('Cash OUT Counts')),
            DataColumn(label: Text('Cash OUT Amount')),
          ],
          rows: paginatedData.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['date_key'] ?? '')),
              DataCell(Text(item['Msisdn_Agents'] ?? '')),
              DataCell(Text(item['From_Profile'] ?? '')),
              DataCell(Text(item['Province'] ?? '')),
              DataCell(Text(item['District'] ?? '')),
              DataCell(Text(item['Sector'] ?? '')),
              DataCell(Text(item['Franchise_Msisdn'] ?? '')),
              DataCell(Text(item['Franchise_Name'] ?? '')),
              DataCell(Text(item['Cash_IN_COUNTS']?.toString() ?? '')),
              DataCell(Text(
                NumberFormat("#,##0.00", "en_US").format(
                  (item['CASH_IN_AMOUNT'] is double)
                      ? item['CASH_IN_AMOUNT']
                      : double.tryParse(item['CASH_IN_AMOUNT'].toString()) ?? 0.0,
                ),
                style: TextStyle(color: Colors.green),
              )),
              DataCell(Text(item['Cash_OUT_COUNTS']?.toString() ?? '')),
              DataCell(Text(
                NumberFormat("#,##0.00", "en_US").format(
                  (item['CASH_OUT_AMOUNT'] is double)
                      ? item['CASH_OUT_AMOUNT']
                      : double.tryParse(item['CASH_OUT_AMOUNT'].toString()) ?? 0.0,
                ),
                style: TextStyle(color: Colors.red),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // Method to build the summary table
  Widget _buildSummaryTable() {
    double totalCashIn = 0;
    double totalCashOut = 0;
    num totalCashInCounts = 0;
    num totalCashOutCounts = 0;
    Set<String> uniqueAgents = {};

    Map<String, Map<String, Map<String, SummaryData>>> summaryMap = {};

    for (var item in _filteredData) {
      String province = item['Province'] ?? 'Unknown';
      String district = item['District'] ?? 'Unknown';
      String sector = item['Sector'] ?? 'Unknown';

      int? dateKey = item['date_key'] is int ? item['date_key'] : int.tryParse(item['date_key'].toString());

      if (dateKey != null) {
        double cashInAmount = item['CASH_IN_AMOUNT'] is double
            ? item['CASH_IN_AMOUNT']
            : double.tryParse(item['CASH_IN_AMOUNT'].toString()) ?? 0.0;
        double cashOutAmount = item['CASH_OUT_AMOUNT'] is double
            ? item['CASH_OUT_AMOUNT']
            : double.tryParse(item['CASH_OUT_AMOUNT'].toString()) ?? 0.0;
        int cashInCount = item['Cash_IN_COUNTS'] is int
            ? item['Cash_IN_COUNTS']
            : int.tryParse(item['Cash_IN_COUNTS'].toString()) ?? 0;
        int cashOutCount = item['Cash_OUT_COUNTS'] is int
            ? item['Cash_OUT_COUNTS']
            : int.tryParse(item['Cash_OUT_COUNTS'].toString()) ?? 0;

        if (!summaryMap.containsKey(province)) {
          summaryMap[province] = {};
        }
        if (!summaryMap[province]!.containsKey(district)) {
          summaryMap[province]![district] = {};
        }
        if (!summaryMap[province]![district]!.containsKey(sector)) {
          summaryMap[province]![district]![sector] = SummaryData();
        }

        summaryMap[province]![district]![sector]!.cashIn += cashInAmount;
        summaryMap[province]![district]![sector]!.cashOut += cashOutAmount;
        summaryMap[province]![district]![sector]!.cashInCount += cashInCount;
        summaryMap[province]![district]![sector]!.cashOutCount += cashOutCount;

        uniqueAgents.add(item['Msisdn_Agents'] ?? '');
      }
    }

    int totalAgents = uniqueAgents.length;

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      color: Colors.black,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all<Color>(Colors.grey[800]!),
            columns: [
              DataColumn(label: Text('PROVINCE', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('DISTRICT', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('SECTOR', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Total Agents', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Total Cash IN', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Total Cash OUT', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Total Cash IN COUNT', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Total Cash OUT COUNT', style: TextStyle(color: Colors.white))),
            ],
            rows: summaryMap.entries.expand((provinceEntry) {
              String province = provinceEntry.key;
              return provinceEntry.value.entries.expand((districtEntry) {
                String district = districtEntry.key;
                return districtEntry.value.entries.map((sectorEntry) {
                  String sector = sectorEntry.key;
                  var data = sectorEntry.value;
                  return DataRow(cells: [
                    DataCell(Text(province, style: TextStyle(color: Colors.white))),
                    DataCell(Text(district, style: TextStyle(color: Colors.white))),
                    DataCell(Text(sector, style: TextStyle(color: Colors.white))),
                    DataCell(Text('$totalAgents', style: TextStyle(color: Colors.white))),
                    DataCell(Text('FRW ${NumberFormat("#,##0.00", "en_US").format(data.cashIn)}', style: TextStyle(color: Colors.green))),
                    DataCell(Text('FRW ${NumberFormat("#,##0.00", "en_US").format(data.cashOut)}', style: TextStyle(color: Colors.red))),
                    DataCell(Text('${data.cashInCount}', style: TextStyle(color: Colors.white))),
                    DataCell(Text('${data.cashOutCount}', style: TextStyle(color: Colors.white))),
                  ]);
                });
              });
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Method to build the filter bar
  Widget _buildFilterBar() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Role: $_userRole', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                // Show Province dropdown based on role
                if (_userRole == 'SRM' || _userRole == 'RM')
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Province',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedProvince,
                      items: [
                        if (_userRole == 'SRM')
                          DropdownMenuItem<String>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.keyboard_arrow_down),
                                SizedBox(width: 8),
                                Text('All Provinces'),
                              ],
                            ),
                          ),
                        ..._allProvinces
                            .where((province) => _userRole != 'RM' || widget.userData['province'] == province)
                            .map((province) => DropdownMenuItem<String>(
                          value: province,
                          child: Text(province),
                        )).toList(),
                      ],
                      onChanged: _userRole == 'RM' && widget.userData.containsKey('province')
                          ? null // Disable for RM with assigned province
                          : (newValue) {
                        setState(() {
                          _selectedProvince = newValue;
                          _selectedDistrict = null;
                          _selectedSector = null;
                          _updateFilteredData();
                          currentPage = 0;
                        });
                      },
                    ),
                  ),
                if (_userRole == 'SRM' || _userRole == 'RM' || _userRole == 'Channel') SizedBox(width: 16),
                // Show District dropdown based on role
                if (_userRole == 'SRM' || _userRole == 'RM' || _userRole == 'Channel')
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDistrict,
                      items: [
                        if (_userRole != 'Channel')
                          DropdownMenuItem<String>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.keyboard_arrow_down),
                                SizedBox(width: 8),
                                Text('All Districts'),
                              ],
                            ),
                          ),
                        ..._allDistricts
                            .where((district) =>
                        _selectedProvince == null ||
                            _salesData.any((item) =>
                            item['Province'] == _selectedProvince && item['District'] == district))
                            .where((district) =>
                        _userRole != 'Channel' ||
                            widget.userData['district'] == district)
                            .map((district) => DropdownMenuItem<String>(
                          value: district,
                          child: Text(district),
                        )).toList(),
                      ],
                      onChanged: _userRole == 'Channel' && widget.userData.containsKey('district')
                          ? null // Disable for Channel with assigned district
                          : (newValue) {
                        setState(() {
                          _selectedDistrict = newValue;
                          _selectedSector = null;
                          _updateFilteredData();
                          currentPage = 0;
                        });
                      },
                    ),
                  ),
                SizedBox(width: 16),
                // Show Sector dropdown for all roles
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Sector',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSector,
                    items: [
                      if (_userRole != 'TDR')
                        DropdownMenuItem<String>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.keyboard_arrow_down),
                              SizedBox(width: 8),
                              Text('All Sectors'),
                            ],
                          ),
                        ),
                      ..._allSectors
                          .where((sector) =>
                      (_selectedDistrict == null ||
                          _salesData.any((item) =>
                          item['District'] == _selectedDistrict && item['Sector'] == sector)))
                          .where((sector) =>
                      _userRole != 'TDR' ||
                          widget.userData['sector'] == sector)
                          .map((sector) => DropdownMenuItem<String>(
                        value: sector,
                        child: Text(sector),
                      )).toList(),
                    ],
                    onChanged: _userRole == 'TDR' && widget.userData.containsKey('sector')
                        ? null // Disable for TDR with assigned sector
                        : (newValue) {
                      setState(() {
                        _selectedSector = newValue;
                        _updateFilteredData();
                        currentPage = 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the line chart
  Widget _buildLineChart() {
    // Create a map to store data by region
    Map<String, List<FlSpot>> cashInByRegion = {};
    Map<String, List<FlSpot>> cashOutByRegion = {};

    // Define region label based on the most specific filter applied
    String regionType = 'Region';
    String regionLabel = 'All';

    if (_selectedSector != null) {
      regionType = 'Sector';
      regionLabel = _selectedSector!;
    } else if (_selectedDistrict != null) {
      regionType = 'District';
      regionLabel = _selectedDistrict!;
    } else if (_selectedProvince != null) {
      regionType = 'Province';
      regionLabel = _selectedProvince!;
    }

    // Group data by date for the line chart
    Map<String, Map<String, double>> dateCashInMap = {};
    Map<String, Map<String, double>> dateCashOutMap = {};

    for (var item in _filteredData) {
      String dateKey = item['date_key'].toString();
      if (dateKey.isNotEmpty) {
        try {
          String region;
          if (_selectedSector != null) {
            region = item['Sector'] ?? 'Unknown';
          } else if (_selectedDistrict != null) {
            region = item['District'] ?? 'Unknown';
          } else if (_selectedProvince != null) {
            region = item['Province'] ?? 'Unknown';
          } else {
            region = 'All Regions';
          }

          // Parse date and amounts
          int timestamp = int.parse(dateKey);
          var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          String formattedDate = DateFormat('yyyy-MM-dd').format(date);

          double cashIn = (item['CASH_IN_AMOUNT'] is double)
              ? item['CASH_IN_AMOUNT']
              : double.tryParse(item['CASH_IN_AMOUNT'].toString()) ?? 0.0;

          double cashOut = (item['CASH_OUT_AMOUNT'] is double)
              ? item['CASH_OUT_AMOUNT']
              : double.tryParse(item['CASH_OUT_AMOUNT'].toString()) ?? 0.0;

          // Initialize maps if needed
          dateCashInMap[formattedDate] ??= {};
          dateCashOutMap[formattedDate] ??= {};

          // Add values to maps
          dateCashInMap[formattedDate]![region] =
              (dateCashInMap[formattedDate]![region] ?? 0) + cashIn;
          dateCashOutMap[formattedDate]![region] =
              (dateCashOutMap[formattedDate]![region] ?? 0) + cashOut;
        } catch (e) {
          print("Error parsing date_key for item: $item, Error: $e");
        }
      }
    }

    // Convert grouped data to spots for chart
    List<String> sortedDates = dateCashInMap.keys.toList()..sort();

    // Set of all regions from both maps
    Set<String> allRegions = {};
    dateCashInMap.forEach((date, regions) => allRegions.addAll(regions.keys));
    dateCashOutMap.forEach((date, regions) => allRegions.addAll(regions.keys));

    // Initialize spot lists for each region
    for (var region in allRegions) {
      cashInByRegion[region] = [];
      cashOutByRegion[region] = [];
    }

    // Fill in spots with data points
    for (int i = 0; i < sortedDates.length; i++) {
      String date = sortedDates[i];
      double xValue = i.toDouble(); // Use index as x value for even spacing

      for (var region in allRegions) {
        double cashInValue = dateCashInMap[date]?[region] ?? 0;
        double cashOutValue = dateCashOutMap[date]?[region] ?? 0;

        cashInByRegion[region]!.add(FlSpot(xValue, cashInValue));
        cashOutByRegion[region]!.add(FlSpot(xValue, cashOutValue));
      }
    }

    // Create color map for regions
    final List<Color> regionColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.indigo,
      Colors.lightGreen,
      Colors.pink,
      Colors.amber
    ];

    Map<String, Color> regionToColor = {};
    int colorIndex = 0;
    for (var region in allRegions) {
      regionToColor[region] = regionColors[colorIndex % regionColors.length];
      colorIndex++;
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Cash Flow by $regionType: $regionLabel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            // Legend for the chart
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                ...allRegions.map((region) =>
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          color: regionToColor[region],
                        ),
                        SizedBox(width: 4),
                        Text(region),
                      ],
                    )),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Cash IN'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text('Cash OUT'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                              var date = DateFormat('yyyy-MM-dd').parse(sortedDates[value.toInt()]);
                              return Text(DateFormat('MM/dd').format(date));
                            }
                            return const Text('');
                          }
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 55,
                          getTitlesWidget: (value, meta) {
                            return Text('${NumberFormat.compact().format(value)} FRW');
                          }
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Generate cash in lines for each region
                    ...allRegions.map((region) =>
                        LineChartBarData(
                          spots: cashInByRegion[region]!,
                          isCurved: true,
                          color: regionToColor[region]!.withOpacity(0.8),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          dashArray: [5, 5], // Dash pattern
                          belowBarData: BarAreaData(show: false),
                        )),
                    // Generate cash out lines for each region
                    ...allRegions.map((region) =>
                        LineChartBarData(
                          spots: cashOutByRegion[region]!,
                          isCurved: true,
                          color: regionToColor[region]!.withRed(200).withOpacity(0.8),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadCSV(List<Map<String, dynamic>> data, String fileName) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'Date',
      'Msisdn Agents',
      'From Profile',
      'Province',
      'District',
      'Sector',
      'Franchise Msisdn',
      'Franchise Name',
      'Cash IN Counts',
      'Cash IN Amount',
      'Cash OUT Counts',
      'Cash OUT Amount'
    ]);

    // Add data rows
    for (var item in data) {
      rows.add([
        item['date_key'] ?? '',
        item['Msisdn_Agents'] ?? '',
        item['From_Profile'] ?? '',
        item['Province'] ?? '',
        item['District'] ?? '',
        item['Sector'] ?? '',
        item['Franchise_Msisdn'] ?? '',
        item['Franchise_Name'] ?? '',
        item['Cash_IN_COUNTS']?.toString() ?? '',
        item['CASH_IN_AMOUNT']?.toString() ?? '',
        item['Cash_OUT_COUNTS']?.toString() ?? '',
        item['CASH_OUT_AMOUNT']?.toString() ?? '',
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName.csv';
    final File file = File(path);
    await file.writeAsString(csv);

    // Show success message
    _showErrorDialog('Download Complete', 'File saved to: $path');
  }
}



