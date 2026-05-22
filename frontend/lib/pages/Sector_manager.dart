import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:user_management/pages/api_service.dart'; // Adjust according to your file structure

class TDRDashboard extends StatefulWidget {
  final UserService userService; // Assuming you have a service class
  final Map<String, dynamic> userData; // User data containing role and sector

  final Map<String, dynamic> salesData;


  TDRDashboard({
    required this.userService,
    required this.userData,

    required this.salesData,

  });

  @override
  _TDRDashboardState createState() => _TDRDashboardState();
}

class _TDRDashboardState extends State<TDRDashboard> with SingleTickerProviderStateMixin {
  int currentPage = 0;
  int rowsPerPage = 10;
  int totalPages = 0;

  List<String> _allSectors = [];
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _filteredData = [];
  String? _selectedSector;

  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAndAnalyzeData();
  }

  Future<void> _fetchAndAnalyzeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.userService.fetchSalesDataDropdown(currentPage, rowsPerPage);
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
    // Loop through sales data to extract unique sectors
    for (var item in _salesData) {
      if (item['Sector'] != null && item['Sector'].toString().isNotEmpty) {
        sectors.add(item['Sector'].toString());
      }
    }

    // Sort and assign unique values to filters
    _allSectors = sectors.toList()..sort();
  }

  void _applyRoleBasedFilters() {
    // TDR sees only their sector
    if (widget.userData.containsKey('sector')) {
      _selectedSector = widget.userData['sector'];
    }
  }

  void _updateFilteredData() {
    _filteredData = _salesData.where((item) {
      bool matchesSector = _selectedSector == null || item['Sector']?.toString() == _selectedSector;
      return matchesSector;
    }).toList();

    totalPages = (_filteredData.length / rowsPerPage).ceil();
    if (currentPage >= totalPages && totalPages > 0) {
      currentPage = totalPages - 1; // Adjust current page
    }
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
        title: Text('TDR Dashboard'),
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

  Widget _buildFilterBar() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Sector',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSector,
                items: _allSectors.map((sector) => DropdownMenuItem<String>(
                  value: sector,
                  child: Text(sector),
                )).toList(),
                onChanged: (newValue) {
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
      ),
    );
  }

  Widget _buildSummaryTable() {
    // Implement the summary table logic specific to TDR here
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('Sector')),
              DataColumn(label: Text('Total Cash IN')),
              DataColumn(label: Text('Total Cash OUT')),
              DataColumn(label: Text('Total Counts')),
            ],
            // Here we should implement rows based on _filteredData
            rows: [], // Populate with appropriate data.
          ),
        ),
      ),
    );
  }

  Widget _buildSalesDataTable() {
    // Similar structure to sales data, implement the details view.
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Msisdn Agents')),
            DataColumn(label: Text('From Profile')),
            DataColumn(label: Text('Sector')),
            DataColumn(label: Text('Cash IN Counts')),
            DataColumn(label: Text('Cash IN Amount')),
            DataColumn(label: Text('Cash OUT Counts')),
            DataColumn(label: Text('Cash OUT Amount')),
          ],
          rows: [], // Populate rows based on _filteredData.
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    // Implement the line chart logic specific to TDR here
    return Card(
      child: Container(
        height: 300,
        child: LineChart(LineChartData()),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}