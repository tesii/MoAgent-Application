
<?php
// Enable CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Set content type to JSON
header("Content-Type: application/json");

// Connect to database
$host = "localhost";
$user = "root";
$password = "";
$database = "mynewdb";

$conn = new mysqli($host, $user, $password, $database);

if ($conn->connect_error) {
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $conn->connect_error
    ]);
    exit;
}

// Get JSON data from the request
$data = json_decode(file_get_contents('php://input'), true);

// If data is null, check if the request is form-encoded instead
if ($data === null) {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
} else {
    $username = $data['username'] ?? '';
    $password = $data['password'] ?? '';
}

// Log the received username (for debugging)
error_log("Login attempt for username: $username");

// Validate that both fields are provided
if (empty($username) || empty($password)) {
    echo json_encode([
        'success' => false,
        'message' => 'Username and password are required'
    ]);
    $conn->close();
    exit;
}

// Query user_accounts table
$stmt = $conn->prepare("SELECT * FROM user_accounts WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // For debugging - check what hash format is stored (DO NOT include actual password in logs)
    error_log("Hash format check for " . $username . ": starts with " . 
              substr($user['password'], 0, 7) . "..., length: " . strlen($user['password']));
    
    // Verify the password using password_verify if using PHP's password_hash
    if (password_verify($password, $user['password'])) {
        // Password is correct
        unset($user['password']);
        
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'userData' => $user
        ]);
    } else {
        // If password_verify fails, try direct comparison as fallback (in case you're using a custom hash)
        if ($password === $user['password']) {
            // Direct comparison succeeded (though this is less secure)
            unset($user['password']);
            
            echo json_encode([
                'success' => true,
                'message' => 'Login successful (using direct comparison)',
                'userData' => $user
            ]);
            
            error_log("WARNING: Login succeeded with direct comparison for user: $username. Consider updating to password_hash/verify.");
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid username or password'
            ]);
            error_log("Password verification failed for user: $username");
        }
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'User not found'
    ]);
    error_log("User not found: $username");
}

$stmt->close();
$conn->close();
?>
