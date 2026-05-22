
<?php
// Enable CORS header
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Set content type to JSON
header("Content-Type: application/json");

// Database connection configuration
$host = "localhost";
$user = "root";
$password = "";
$database = "mynewdb";

// Function to send standardized JSON response
function sendResponse($success, $message, $data = null, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

// Connect to database
$conn = new mysqli($host, $user, $password, $database);

if ($conn->connect_error) {
    sendResponse(false, 'Database connection failed: ' . $conn->connect_error, null, 500);
}

// Get JSON data from the request
$data = json_decode(file_get_contents('php://input'), true);

// Check for authorization
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

if (!$authHeader) {
    sendResponse(false, 'Authorization token is required', null, 401);
}

// Validate the token (this is a simple validation - replace with proper JWT verification in production)
$tokenParts = explode('|', base64_decode($authHeader));
if (count($tokenParts) !== 2) {
    sendResponse(false, 'Invalid authorization token', null, 401);
}

$username = $tokenParts[0];

// Prepare the complex SQL query
$query = "SELECT
    ua.username,
    TRIM(SUBSTRING_INDEX(ua.location, ',', 1)) AS province,
    TRIM(SUBSTRING_INDEX(ua.location, ',', -1)) AS district,
    s.*
FROM
    mynewdb.user_accounts ua
JOIN
    mynewdb.sales_data_mart_copy_partitioned s ON (
        (ua.role = 'Channel' 
        AND (
            TRIM(SUBSTRING_INDEX(ua.location, ',', -1)) = s.District OR 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', -2), ',', 1)) = s.District OR 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', -3), ',', 1)) = s.District
        ))
        OR
        (ua.role = 'TDR' 
        AND (
            TRIM(SUBSTRING_INDEX(ua.location, ',', -1)) = s.Sector OR 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', -2), ',', 1)) = s.Sector OR 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', -3), ',', 1)) = s.Sector
        ))
        OR
        (ua.role = 'SRM' 
        AND (
            TRIM(SUBSTRING_INDEX(ua.location, ',', 1)) = s.Province OR
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', 2), ',', -1)) = s.Province OR
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', 3), ',', -1)) = s.Province OR
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', 4), ',', -1)) = s.Province OR
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', 5), ',', -1)) = s.Province
        ))
        OR
        (ua.role = 'RM' 
        AND (
            TRIM(SUBSTRING_INDEX(ua.location, ',', 1)) = s.Province 
            AND (
                TRIM(SUBSTRING_INDEX(ua.location, ',', -1)) = s.District OR 
                TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ua.location, ',', -2), ',', 1)) = s.District
            )
        ))
    )
WHERE
    ua.username = ? 
    AND ua.role IN ('Channel', 'TDR', 'SRM', 'RM')
    limit 5000
";

// Prepare and execute the query
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

// Check if query was successful and has results
if ($result) {
    if ($result->num_rows > 0) {
        $salesData = [];
        while ($row = $result->fetch_assoc()) {
            $salesData[] = $row;
        }
        
        sendResponse(true, 'Sales data retrieved successfully', $salesData);
    } else {
        sendResponse(false, 'No sales data found for the user', null, 404);
    }
} else {
    sendResponse(false, 'Error executing query: ' . $stmt->error, null, 500);
}

// Close statement and connection
$stmt->close();
$conn->close();
?>
