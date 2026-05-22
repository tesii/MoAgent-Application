<?php
$servername = "localhost";  // Change if necessary to your IP address
$username = "root";          // Your database username
$password = "";              // Your database password
$dbname = "mynewdb";        // Your database name

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');  // Allow requests from any origin

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// SQL query to get roles
$sql = "SELECT role_id, role_name FROM roles";
$result = $conn->query($sql);

// Initialize an array to hold the role data
$roles = [];

if ($result->num_rows > 0) {
    // Loop through the results and add to the array
    while ($row = $result->fetch_assoc()) {
        $roles[] = $row;
    }
}

// Close the database connection
$conn->close();

// Output the JSON response
echo json_encode($roles);
?>
