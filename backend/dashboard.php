<?php
// Step 1: Database connection
$servername = "localhost"; // Your server name
$username = "root"; // Your username
$password = ""; // Your password
$dbname = "mynewdb"; // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Step 2: Prepare and execute the SQL query
// Assuming you have the user's Franchise_Name after login. For demonstration, we are using a hardcoded example.
// Replace this with the actual Franchise_Name variable depending on your login system.
$userFranchiseName = 'Specific Franchise Name'; // Get this from the session or context

$sql = "
   SELECT 
    s.Franchise_Name,
    s.Province, 
    s.District, 
    s.Sector,
    u.location
FROM 
    sales_data_mart_copy_partitioned s
JOIN 
    user_accounts u 
    ON (
        (CONCAT(s.Province, ', ', s.District, ', ', s.Sector) = u.location) -- Default full match
        OR 
        (u.role IN ('SRM', 'RM') AND CONCAT(s.Province, ', ', s.District) = u.location) -- SRM/RM: Province, District
        OR 
        (u.role = 'Channel' AND CONCAT(s.District, ', ', s.Sector) = u.location) -- Channel: District, Sector
        OR 
        (u.role = 'TDR' AND s.Sector = u.location) -- TDR: Sector only
    )
WHERE 
    s.Franchise_Name = ?
LIMIT 50;

";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $userFranchiseName); // Assuming Franchise_Name is a string
$stmt->execute();
$result = $stmt->get_result();

// Step 3: Display the data
if ($result->num_rows > 0) {
    // Output header
    echo "<h1>Dashboard</h1>";
    echo "<table border='1'>";
    echo "<tr><th>Franchise Name</th><th>Province</th><th>District</th><th>Sector</th><th>Location</th></tr>";

    // Output data for each row
    while ($row = $result->fetch_assoc()) {
        echo "<tr>
                <td>" . htmlspecialchars($row['Franchise_Name']) . "</td>
                <td>" . htmlspecialchars($row['province']) . "</td>
                <td>" . htmlspecialchars($row['district']) . "</td>
                <td>" . htmlspecialchars($row['sector']) . "</td>
                <td>" . htmlspecialchars($row['location']) . "</td>
              </tr>";
    }
    echo "</table>";
} else {
    echo "No results found.";
}

// Close the statement and connection
$stmt->close();
$conn->close();
?>
