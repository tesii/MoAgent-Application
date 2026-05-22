

<?php
// config.php - Database configuration
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'mynewdb');

// db_connection.php
class DatabaseConnection {
    private $conn;
    
    public function __construct() {
        try {
            $this->conn = new PDO(
                "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME,
                DB_USER,
                DB_PASS
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $e) {
            echo "Connection failed: " . $e->getMessage();
        }
    }
    
    public function getConnection() {
        return $this->conn;
    }
}
// insert_user.php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers, Content-Type, Access-Control-Allow-Methods, Authorization, X-Requested-With');

try {
    // Get posted data
    $data = json_decode(file_get_contents("php://input"));
    
    // Check required fields including franchise_id
    if (!isset($data->username) || !isset($data->fullname) || !isset($data->password) || !isset($data->role) || !isset($data->location) || !isset($data->franchise_id)) {
        throw new Exception("Missing required fields");
    }
    
    // Validate role
    $valid_roles = ['SRM', 'Channel', 'RM', 'TDR'];
    if (!in_array($data->role, $valid_roles)) {
        throw new Exception("Invalid role specified");
    }
    
    // Database connection
    $database = new DatabaseConnection();
    $db = $database->getConnection();
    
    // Prepare insert statement to include 'franchise_id' and 'location'
    $query = "INSERT INTO user_accounts (username, fullname, password, role, location, franchise_id, created_at) 
              VALUES (:username, :fullname, :password, :role, :location, :franchise_id, NOW())";
    
    $stmt = $db->prepare($query);
    
    // Sanitize and hash password
    $username = htmlspecialchars(strip_tags($data->username));
    $fullname = htmlspecialchars(strip_tags($data->fullname));
    $role = htmlspecialchars(strip_tags($data->role));
    $location = htmlspecialchars(strip_tags($data->location));  // Add sanitization for location
    $franchise_id = htmlspecialchars(strip_tags($data->franchise_id)); // Sanitize franchise_id
    $password = password_hash($data->password, PASSWORD_DEFAULT);
    
    // Bind parameters
    $stmt->bindParam(":username", $username);
    $stmt->bindParam(":fullname", $fullname);
    $stmt->bindParam(":password", $password);
    $stmt->bindParam(":role", $role);
    $stmt->bindParam(":location", $location);  // Bind location parameter
    $stmt->bindParam(":franchise_id", $franchise_id); // Bind franchise_id parameter
    
    // Execute query
    if($stmt->execute()) {
        echo json_encode(array("message" => "User created successfully"));
    } else {
        throw new Exception("Error creating user");
    }
    
} catch (Exception $e) {
    echo json_encode(array(
        "message" => "Error: " . $e->getMessage()
    ));
}
