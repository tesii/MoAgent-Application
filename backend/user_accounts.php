
<?php
require 'db.php';      


try {

    
    // Prepare and execute the SQL statement
    $stmt = $pdo->prepare("SELECT * FROM user_accounts");
    $stmt->execute();
    
    // Fetch all results as an associative array
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Set the header to indicate JSON response
    header('Content-Type: application/json');
    
    // Return the results in JSON format
    echo json_encode($users);
    
} catch (PDOException $e) {
    // Handle any errors
    echo json_encode(["error" => $e->getMessage()]);
}
?>
