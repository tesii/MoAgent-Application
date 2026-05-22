
<?php
// filtered_sales_data.php

// Set headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get JSON input
$json = file_get_contents('php://input');
$data = json_decode($json, true);

// Check for required parameters
if (!isset($data)) {
    echo json_encode(['error' => 'No data provided']);
    exit();
}

require 'db.php';      



// Extract filter parameters
$role = $data['role'] ?? '';
$province = $data['province'] ?? '';
$district = $data['district'] ?? '';
$sector = $data['sector'] ?? '';
$franchise_id = $data['franchise_id'] ?? '';
$page = $data['page'] ?? 1;
$limit = $data['limit'] ?? 50; // Default 50 as requested

// Calculate offset
$offset = ($page - 1) * $limit;

// Base query
$query = "SELECT date_key, Msisdn_Agents, from_profile, Province, District, Sector, 
          Franchise_msisdn, Franchise_Name, Cash_IN_COUNTS, CASH_IN_AMOUNT, 
          Cash_OUT_COUNTS, CASH_OUT_AMOUNT 
          FROM sales_data_mart_copy_partitioned 
          WHERE 1";

// Add filters based on role and location
if ($role == 'TDR') {
    // Franchise level - most restrictive
    if (!empty($franchise_id)) {
        $query .= " AND Franchise_msisdn = ?";
        $params[] = $franchise_id;
    }
} else if ($role == 'Channel') {
    // Sector level
    if (!empty($province) && !empty($district) && !empty($sector)) {
        $query .= " AND Province = ? AND District = ? AND Sector = ?";
        $params = [$province, $district, $sector];
    }
} else if ($role == 'RM') {
    // District level
    if (!empty($province) && !empty($district)) {
        $query .= " AND Province = ? AND District = ?";
        $params = [$province, $district];
    }
} else if ($role == 'SRM') {
    // Province level
    if (!empty($province)) {
        $query .= " AND Province = ?";
        $params = [$province];
    }
}

// Add pagination
$query .= " LIMIT ? OFFSET ?";
$params[] = $limit;
$params[] = $offset;

// Prepare statement
$stmt = $conn->prepare($query);

// Bind parameters if any
if (!empty($params)) {
    // Create parameter types string
    $types = str_repeat('s', count($params) - 2) . 'ii'; // All strings except limit and offset
    
    // Bind parameters dynamically
    $stmt->bind_param($types, ...$params);
}

// Execute the query
$stmt->execute();
$result = $stmt->get_result();

// Fetch data as associative array
$sales_data = [];
while ($row = $result->fetch_assoc()) {
    $sales_data[] = $row;
}

// Close connection
$stmt->close();
$conn->close();

// Return data as JSON
echo json_encode($sales_data);
?>
