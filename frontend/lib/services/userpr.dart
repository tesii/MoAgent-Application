import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> loadCSVIntoTransactions() async {
  final csvUrl =
      'https://tphcuhgrvokazjpusmrn.supabase.co/storage/v1/object/public/csv/sample_50mb_cleaned_no_zeros.csv';

  final response = await http.get(Uri.parse(csvUrl));

  if (response.statusCode == 200) {
    final csvData = response.body;
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    // Extract headers and remove the first row
    final headers = rows.first;
    rows.removeAt(0);

    for (var row in rows) {
      String rawDate = row[0].toString(); // Example: "2024090100"
      String formattedDate = "${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)} ${rawDate.substring(8, 10)}:00:00";

      // First, insert into the 'franchises' table to avoid foreign key violations
      await supabase.from('userprofiles').upsert({

        'province': row[3],
        'district': row[4],
        'sector': row[5],
      });



    }

    print("CSV data successfully inserted into transactions table.");
  } else {
    print("Failed to fetch CSV file: ${response.statusCode}");
  }
}

