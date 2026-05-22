<?php
require 'db.php';      

// Set the content type to JSON and allow CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Allow requests from any origin

// Uncomment the following lines for development purposes
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Function to fetch unique values with optional filtering
function fetchUniqueValues($conn, $table, $column, $filterColumn = null, $filterValue = null) {
    $sql = "SELECT DISTINCT $column FROM $table";
    
    if ($filterColumn && $filterValue) {
        $sql .= " WHERE $filterColumn = ?";
    }
    
    $sql .= " ORDER BY $column";
    
    $stmt = $conn->prepare($sql);
    if ($filterColumn && $filterValue) {
        $stmt->bind_param("s", $filterValue);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    $values = [];
    
    while ($row = $result->fetch_assoc()) {
        $values[] = $row[$column];
    }
    
    $stmt->close();
    return $values;
}

// Improved function to handle multiple locations
function fetchFranchiseMsisdn($conn, $provinces = null, $district = null, $location = null) {
    $sql = "SELECT DISTINCT franchise_msisdn_hash FROM franchises";
    $params = [];
    $types = "";
    $whereAdded = false;
    
    // Handle location parameter (comma-separated values)
    if ($location) {
        $locationArray = array_map('trim', explode(',', $location));
        $locationConditions = [];
        
        // For each location item, check in province, district, and sector
        foreach ($locationArray as $loc) {
            $locationConditions[] = "province = ? OR district = ? OR sector = ?";
            $params[] = $loc;
            $params[] = $loc;
            $params[] = $loc;
            $types .= "sss";
        }
        
        if (!empty($locationConditions)) {
            $sql .= " WHERE (" . implode(") OR (", $locationConditions) . ")";
            $whereAdded = true;
        }
    }
    // Handle multiple province filters
    else if ($provinces) {
        $provinceArray = array_map('trim', explode(',', $provinces));
        $placeholders = implode(',', array_fill(0, count($provinceArray), '?'));
        
        $sql .= " WHERE province IN ($placeholders)";
        $params = array_merge($params, $provinceArray);
        $types .= str_repeat("s", count($provinceArray));
        $whereAdded = true;
    }
    
    // Handle district filter
    if ($district) {
        $sql .= ($whereAdded ? " AND" : " WHERE") . " district = ?";
        $params[] = $district;
        $types .= "s";
    }
    
    // Add debugging
    error_log("SQL Query: " . $sql);
    error_log("Params: " . print_r($params, true));
    
    $stmt = $conn->prepare($sql);
    
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    $msisdns = [];
    
    while ($row = $result->fetch_assoc()) {
        $msisdns[] = $row['franchise_msisdn_hash'];
    }
    
    $stmt->close();
    
    // Log the results
    error_log("Found " . count($msisdns) . " franchise IDs");
    
    return $msisdns;
}

// Handle request
$type = isset($_GET['type']) ? $_GET['type'] : '';
$province = isset($_GET['province']) ? $_GET['province'] : null;
$district = isset($_GET['district']) ? $_GET['district'] : null;
$location = isset($_GET['location']) ? $_GET['location'] : null;

// Log the incoming request
error_log("Request type: $type, province: $province, district: $district, location: $location");

$response = [];

switch ($type) {
    case 'provinces':
        $response = fetchUniqueValues($conn, 'franchises', 'province');
        break;
    case 'districts':
        if ($province) {
            $response = fetchUniqueValues($conn, 'franchises', 'district', 'province', $province);
        } else {
            http_response_code(400); // Bad Request
            $response = ['error' => 'Province parameter is required'];
        }
        break;
    case 'sectors':
        if ($district) {
            $response = fetchUniqueValues($conn, 'franchises', 'sector', 'district', $district);
        } else {
            http_response_code(400); // Bad Request
            $response = ['error' => 'District parameter is required'];
        }
        break;
    case 'franchise_msisdn_hash':
        // Check if at least one of province, district or location is provided
        if ($province || $district || $location) {
            $response = fetchFranchiseMsisdn($conn, $province, $district, $location);
        } else {
            http_response_code(400); // Bad Request
            $response = [
                'error' => 'At least one parameter (province, district, or location) is required'
            ];
        }
        break;
    default:
        http_response_code(400); // Bad Request
        $response = ['error' => 'Invalid request'];
        break;
}

// Log the response
error_log("Response: " . json_encode($response));

// Return the JSON response
echo json_encode($response);

// Close the database connection
$conn->close();
?>
