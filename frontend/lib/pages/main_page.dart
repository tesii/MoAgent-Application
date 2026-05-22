import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  final List<dynamic> salesData;

  const MainPage({Key? key, required this.salesData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sales Data")),
      body: salesData.isEmpty
          ? Center(child: Text("No sales data available"))
          : ListView.builder(
        itemCount: salesData.length,
        itemBuilder: (context, index) {
          final item = salesData[index];
          return Card(
            child: ListTile(
              title: Text("Franchise: ${item['Franchise_Name']}"),
              subtitle: Text("Cash In: ${item['CASH_IN_AMOUNT']} - Cash Out: ${item['CASH_OUT_AMOUNT']}"),
            ),
          );
        },
      ),
    );
  }
}
