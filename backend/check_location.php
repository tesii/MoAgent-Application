
<?php
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Methods: POST, OPTIONS");
header('Access-Control-Allow-Headers: Content-Type');

$servername = "localhost"; // Your database server name
$username = "root"; // Your database username
$password = ""; // Your database password
$dbname = "mynewdb"; // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

function getSalesDataByLocation($location) {
    global $conn;

    // Prepare the SQL query using prepared statements
    $sql = "
        SELECT 
            ua.id AS user_id,
            ua.username,
            ua.fullname,
            ua.role,
            ua.location,
            ua.franchise_id,
            sdmp.date_key,
            sdmp.Msisdn_Agents,
            sdmp.from_profile,
            sdmp.Province,
            sdmp.District,
            sdmp.Sector,
            sdmp.Franchise_msisdn,
            sdmp.Franchise_Name,
            sdmp.Cash_IN_COUNTS,
            sdmp.CASH_IN_AMOUNT,
            sdmp.Cash_OUT_COUNTS,
            sdmp.CASH_OUT_AMOUNT
        FROM user_accounts ua
        LEFT JOIN sales_data_mart_copy_partitioned sdmp 
            ON 
                FIND_IN_SET(sdmp.Province, ua.location) OR
                FIND_IN_SET(sdmp.District, ua.location) OR
                FIND_IN_SET(sdmp.Sector, ua.location)
        WHERE ua.location LIKE ? 
        LIMIT 50
    ";

    if ($stmt = $conn->prepare($sql)) {
        // Use a wildcard search to allow for partial matches for the LIKE clause
        $locationParam = "%$location%";
        $stmt->bind_param("s", $locationParam);
        $stmt->execute();

        $result = $stmt->get_result();
        $data = [];

        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }

        $stmt->close();
        return $data;
    } else {
        error_log("SQL prepare failed: " . $conn->error);
        return [];
    }
}

// Get the location from the POST request instead
$data = json_decode(file_get_contents("php://input"), true);
$location = isset($data['location']) ? $data['location'] : null;

if ($location) {
    // Check if location format is correct
    $location = trim($location); // Ensure no leading/trailing spaces
    $data = getSalesDataByLocation($location);
    
    if (empty($data)) {
        echo json_encode(["error" => "No sales data found for this location."]);
    } else {
        echo json_encode($data);
    }
} else {
    echo json_encode(["error" => "No location specified."]);
}

$conn->close();
