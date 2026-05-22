
<?php
include 'user.php'; // Ensure this file contains database connection setup

// Set a higher execution time limit
set_time_limit(800);  // Set the limit to 800 seconds (around 13 minutes)

$csvFile = 'D:\patience_data_encry\patience_data_encry.csv';

// Check if the file exists and is readable
if (!file_exists($csvFile) || !is_readable($csvFile)) {
    die('File not found or not readable.');
}

// Open the CSV file for reading
if (($handle = fopen($csvFile, 'r')) !== false) {
    $headers = fgetcsv($handle, 1000, ','); // Read the headers (not used but can be useful for validation)

    // Prepare the SQL statement
    $sql = "INSERT INTO sales_data_mart (date_key, Msisdn_Agents, from_profile, Province, District, Sector, Franchise_msisdn, Franchise_Name, Cash_IN_COUNTS, CASH_IN_AMOUNT, Cash_OUT_COUNTS, CASH_OUT_AMOUNT) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    $stmt = $pdo->prepare($sql);

    // Error handling for SQL preparation
    if ($stmt === false) {
        die("Error preparing the SQL statement: " . print_r($pdo->errorInfo(), true));
    }

    $batchSize = 50; // Set the batch size for inserts
    $rowCount = 0;
    $batchCount = 0;
    $batchData = [];

    // Read and process each row from the CSV
    while (($row = fgetcsv($handle, 1000, ',')) !== false) {
        if (count($row) !== 12) {
            echo "Skipping row due to incorrect number of columns: " . json_encode($row) . "<br>";
            continue;
        }

        // Date handling for format YYYYMMDDHH
        $date_str = trim($row[0]);
        if (!empty($date_str) && strlen($date_str) === 10 && is_numeric($date_str)) {
            $year = substr($date_str, 0, 4);
            $month = substr($date_str, 4, 2);
            $day = substr($date_str, 6, 2);
            $hour = substr($date_str, 8, 2);
            
            // Validate the date components
            if (checkdate($month, $day, $year) && $hour >= 0 && $hour <= 23) {
                $date_key = $date_str; // Store date in YYYYMMDDHH format
            } else {
                echo "Invalid date components in row: " . $date_str . "<br>";
                continue;
            }
        } else {
            echo "Invalid date format in row: " . $date_str . "<br>";
            continue;
        }

        // Clean and validate location data
        $province = trim($row[3]);
        $district = trim($row[4]);
        $sector = trim($row[5]);

        if (empty($province) || $province === '0' || 
            empty($district) || $district === '0' || 
            empty($sector) || $sector === '0') {
            echo "Skipping row due to invalid location data: " . json_encode($row) . "<br>";
            continue;
        }

        // Prepare data for batch insert
        $rowData = [
            $date_key,           // date_key (already in YYYYMMDDHH format)
            trim($row[1]),       // Msisdn_Agents
            trim($row[2]),       // from_profile
            $province,           // Province
            $district,           // District
            $sector,             // Sector
            trim($row[6]),       // Franchise_msisdn
            trim($row[7]),       // Franchise_Name
            floatval($row[8]),   // Cash_IN_COUNTS
            floatval($row[9]),   // CASH_IN_AMOUNT
            floatval($row[10]),  // Cash_OUT_COUNTS
            floatval($row[11])   // CASH_OUT_AMOUNT
        ];

        $batchData[] = $rowData; // Add row data to the batch
        $rowCount++; // Increment the row count

        // Check if the batch size limit is reached
        if (count($batchData) >= $batchSize) {
            try {
                $pdo->beginTransaction(); // Begin a transaction for batch insert
                foreach ($batchData as $data) {
                    $stmt->execute($data); // Execute each prepared statement
                }
                $pdo->commit(); // Commit the transaction
                $batchCount++; // Increment batch count
                echo "Batch $batchCount processed successfully. Rows inserted: " . count($batchData) . "<br>";
            } catch (PDOException $e) {
                $pdo->rollBack(); // Roll back on error
                echo "Error inserting batch: " . $e->getMessage() . "<br>";
                echo "Problematic row (batch): " . json_encode($batchData) . "<br>";
            }
            $batchData = []; // Reset batch data
        }
    }

    // Process any remaining rows in the last batch
    if (!empty($batchData)) {
        try {
            $pdo->beginTransaction();
            foreach ($batchData as $data) {
                $stmt->execute($data);
            }
            $pdo->commit();
            echo "Final batch processed successfully. Rows inserted: " . count($batchData) . "<br>";
        } catch (PDOException $e) {
            $pdo->rollBack();
            echo "Error inserting final batch: " . $e->getMessage() . "<br>";
            echo "Problematic row (final batch): " . json_encode($batchData) . "<br>";
        }
    }

    fclose($handle); // Close the CSV file
    echo "Import completed. Total rows processed: $rowCount, Total batches: $batchCount";
} else {
    die('Error opening the file.');
}
?>
