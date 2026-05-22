<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

require 'db.php';      

// Define all partitions
$partitions = [
    'p_20240901' => ['start' => 2024090100, 'end' => 2024090200],
    'p_20240902' => ['start' => 2024090200, 'end' => 2024090300],
    'p_20240903' => ['start' => 2024090300, 'end' => 2024090400],
    'p_20240904' => ['start' => 2024090400, 'end' => 2024090500],
    'p_20240905' => ['start' => 2024090500, 'end' => 2024090600],
    'p_20240906' => ['start' => 2024090600, 'end' => 2024090700],
    'p_20240907' => ['start' => 2024090700, 'end' => 2024090800],
    'p_20240908' => ['start' => 2024090800, 'end' => 2024090900],
    'p_20240909' => ['start' => 2024090900, 'end' => 2024091000],
    'p_20240910' => ['start' => 2024091000, 'end' => 2024091100],
    'p_20240911' => ['start' => 2024091100, 'end' => 2024091200],
    'p_20240912' => ['start' => 2024091200, 'end' => PHP_INT_MAX]
];

// Set the batch size to 50
$batchSize = 200000;



// File to store offsets
$offsetFile = 'offsets.json';

// Load previous offsets (if any)
$offsets = file_exists($offsetFile) ? json_decode(file_get_contents($offsetFile), true) : [];

foreach ($partitions as $partitionName => $partition) {
    echo "<h3>Processing partition: $partitionName</h3>";
    
    // Get total records for this partition
    $countStmt = $conn->prepare("
        SELECT COUNT(*) FROM sales_data_mart 
        WHERE date_key >= :start AND date_key < :end
    ");
    $countStmt->bindParam(':start', $partition['start'], PDO::PARAM_INT);
    $countStmt->bindParam(':end', $partition['end'], PDO::PARAM_INT);
    $countStmt->execute();
    $partitionCount = $countStmt->fetchColumn();
    
    echo "<div class='alert alert-info'>Found $partitionCount records for partition $partitionName</div>";
    
    // Determine the offset for this partition
    $offset = isset($offsets[$partitionName]) ? $offsets[$partitionName] : 0;
    
    if ($offset >= $partitionCount) {
        echo "<div class='alert alert-warning'>All records processed for this partition. Skipping.</div>";
        continue;
    }
    
    $startTime = microtime(true);
    $processedRecords = $offset;
    
    echo "<div id='progress-$partitionName' class='progress' style='height: 30px;'>
            <div id='progress-bar-$partitionName' class='progress-bar' role='progressbar' style='width: 0%;' 
                 aria-valuenow='0' aria-valuemin='0' aria-valuemax='100'>0%</div>
          </div>";
    echo "<div id='status-$partitionName'>Starting...</div>";
    
    ob_flush();
    flush();
    
    while ($offset < $partitionCount) {
        // Start a new transaction for each batch
        $conn->beginTransaction();
        
        try {
            // Select data from source table for current batch
            $selectStmt = $conn->prepare("
                SELECT 
                    date_key, Msisdn_Agents, from_profile, Province, District, 
                    Sector, Franchise_msisdn, Franchise_Name, Cash_IN_COUNTS, 
                    CASH_IN_AMOUNT, Cash_OUT_COUNTS, CASH_OUT_AMOUNT
                FROM sales_data_mart 
                WHERE date_key >= :start AND date_key < :end
                LIMIT :offset, :batchSize
            ");
            $selectStmt->bindParam(':start', $partition['start'], PDO::PARAM_INT);
            $selectStmt->bindParam(':end', $partition['end'], PDO::PARAM_INT);
            $selectStmt->bindParam(':offset', $offset, PDO::PARAM_INT);
            $selectStmt->bindParam(':batchSize', $batchSize, PDO::PARAM_INT);
            $selectStmt->execute();
            
            $rows = $selectStmt->fetchAll(PDO::FETCH_ASSOC);
            $recordsInBatch = count($rows);
            
            if ($recordsInBatch == 0) {
                break; // Exit the loop if no more records
            }
            
            // Prepare bulk insert statement
            $insertQuery = "
                INSERT INTO sales_data_mart_copy_partitioned (
                    date_key, Msisdn_Agents, from_profile, Province, District, 
                    Sector, Franchise_msisdn, Franchise_Name, Cash_IN_COUNTS, 
                    CASH_IN_AMOUNT, Cash_OUT_COUNTS, CASH_OUT_AMOUNT
                ) VALUES 
            ";
            
            $placeholders = [];
            $insertValues = [];
            
            foreach ($rows as $row) {
                $placeholder = "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                $placeholders[] = $placeholder;
                
                // Add values in the same order as columns in the insert statement
                $insertValues[] = $row['date_key'];
                $insertValues[] = $row['Msisdn_Agents'];
                $insertValues[] = $row['from_profile'];
                $insertValues[] = $row['Province'];
                $insertValues[] = $row['District'];
                $insertValues[] = $row['Sector'];
                $insertValues[] = $row['Franchise_msisdn'];
                $insertValues[] = $row['Franchise_Name'];
                $insertValues[] = $row['Cash_IN_COUNTS'];
                $insertValues[] = $row['CASH_IN_AMOUNT'];
                $insertValues[] = $row['Cash_OUT_COUNTS'];
                $insertValues[] = $row['CASH_OUT_AMOUNT'];
            }
            
            $insertQuery .= implode(", ", $placeholders);
            
            // Prepare and execute insert statement
            $insertStmt = $conn->prepare($insertQuery);
            $insertResult = $insertStmt->execute($insertValues);
            
            // Commit this batch's transaction
            $conn->commit();
            
            $processedRecords += $recordsInBatch;
            $progress = round(($processedRecords / $partitionCount) * 100, 2);
            
            // Update progress in the browser
            echo "<script>
                document.getElementById('progress-bar-$partitionName').style.width = '{$progress}%';
                document.getElementById('progress-bar-$partitionName').setAttribute('aria-valuenow', {$progress});
                document.getElementById('progress-bar-$partitionName').innerHTML = '{$progress}%';
                document.getElementById('status-$partitionName').innerHTML = 'Processing: {$processedRecords} of {$partitionCount} records';
            </script>";
            
            ob_flush();
            flush();
            
            // Add a small delay to prevent server overload
            usleep(100000); // 0.1 second delay
            
        } catch (PDOException $e) {
            // Rollback transaction on error
            $conn->rollBack();
            echo "<div class='alert alert-danger'>Error in batch at offset $offset: " . $e->getMessage() . "</div>";
            // Continue with next batch even if this one fails
        }
        
        $offset += $batchSize;
        
        // Save the current offset to the offsets file
        $offsets[$partitionName] = $offset;
        file_put_contents($offsetFile, json_encode($offsets));
    }
    
    $endTime = microtime(true);
    $executionTime = round($endTime - $startTime, 2);
    echo "<div class='alert alert-success'>Completed partition $partitionName: $processedRecords records in $executionTime seconds</div>";
    
    // Add separator between partitions
    echo "<hr>";
}

// Optionally, clear the offsets file if all partitions are completely processed
if (array_sum($offsets) >= $partitionCount) {
    unlink($offsetFile);
}

$conn = null;
echo "<div class='alert alert-success'><strong>All partitions processed!</strong></div>";
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Automatic Partition Processing</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            padding: 20px;
        }
        .alert {
            margin-top: 10px;
        }
        hr {
            margin: 30px 0;
            border-top: 2px solid #ccc;
        }
    </style>
</head>
<body class="container">
    <h1 class="mb-4">Automatic Partition Processing</h1>
    <div class="alert alert-info">
        <strong>Processing all partitions automatically.</strong><br>
        Each partition will be processed in batches of 50 records.
    </div>
</body>
</html>
