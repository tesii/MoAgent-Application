
<?php
// Set Content-Type to JSON
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Allow requests from any origin
require 'db.php';      


// SQL query
// Query the sales_data_mart_copy_partitioned table with a limit
$sql = "SELECT * FROM sales_data_mart_copy_partitioned LIMIT 50"; // Limiting results to 50


// Execute the query and fetch the results
$result = $conn->query($sql);

// Check if any rows are returned
if ($result->num_rows > 0) {
    // Create an array to store the results
    $data = [];
    while($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    // Return the data as a JSON response
    echo json_encode($data);
} else {
    echo json_encode(["message" => "No data found"]);
}

// Close the connection
$conn->close();
?>
