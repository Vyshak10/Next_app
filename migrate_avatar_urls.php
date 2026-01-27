<?php
/**
 * Migration Script: Update Supabase Avatar URLs
 * 
 * This script updates all avatar URLs from the old Supabase project
 * to the new one, and converts SVG avatars to PNG format.
 * 
 * IMPORTANT: Upload this to your server at:
 * https://indianrupeeservices.in/NEXT/backend/migrate_avatar_urls.php
 * 
 * Then visit it in your browser ONCE to run the migration.
 */

// Database configuration (update these with your actual credentials)
$host = 'localhost';  // Usually 'localhost'
$dbname = 'your_database_name';  // Your database name
$username = 'your_db_username';  // Your database username
$password = 'your_db_password';  // Your database password

// Old and new Supabase URLs
$oldUrl = 'https://mcwngfebeexcugypioey.supabase.co';
$newUrl = 'https://yewsmbnnizomoedmbzhh.supabase.co';

try {
    // Connect to database
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>🔄 Starting Avatar URL Migration</h2>";
    echo "<pre>";
    
    // List of tables that might have avatar_url column
    $tables = ['users', 'startups', 'profiles'];
    
    foreach ($tables as $table) {
        echo "\n📋 Checking table: $table\n";
        echo str_repeat("-", 50) . "\n";
        
        // Check if table exists
        $checkTable = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($checkTable->rowCount() == 0) {
            echo "⚠️  Table '$table' does not exist. Skipping...\n";
            continue;
        }
        
        // Check if avatar_url column exists
        $checkColumn = $pdo->query("SHOW COLUMNS FROM $table LIKE 'avatar_url'");
        if ($checkColumn->rowCount() == 0) {
            echo "⚠️  Column 'avatar_url' does not exist in '$table'. Skipping...\n";
            continue;
        }
        
        // Update old Supabase URLs
        $stmt1 = $pdo->prepare("
            UPDATE $table 
            SET avatar_url = REPLACE(avatar_url, ?, ?)
            WHERE avatar_url LIKE ?
        ");
        $stmt1->execute([$oldUrl, $newUrl, "%$oldUrl%"]);
        $updated1 = $stmt1->rowCount();
        echo "✅ Updated $updated1 old Supabase URLs\n";
        
        // Convert SVG to PNG for dicebear avatars
        $stmt2 = $pdo->prepare("
            UPDATE $table 
            SET avatar_url = REPLACE(avatar_url, '/svg?', '/png?')
            WHERE avatar_url LIKE '%dicebear.com%/svg?%'
        ");
        $stmt2->execute();
        $updated2 = $stmt2->rowCount();
        echo "✅ Converted $updated2 SVG avatars to PNG\n";
        
        // Show sample of updated URLs
        $sample = $pdo->query("SELECT id, avatar_url FROM $table WHERE avatar_url IS NOT NULL LIMIT 3");
        echo "\n📸 Sample avatar URLs:\n";
        foreach ($sample as $row) {
            echo "  ID {$row['id']}: {$row['avatar_url']}\n";
        }
    }
    
    echo "\n" . str_repeat("=", 50) . "\n";
    echo "🎉 Migration Complete!\n";
    echo str_repeat("=", 50) . "\n";
    echo "</pre>";
    
    echo "<p><strong>✅ All avatar URLs have been updated!</strong></p>";
    echo "<p>⚠️ <strong>IMPORTANT:</strong> Delete this file from your server for security!</p>";
    
} catch (PDOException $e) {
    echo "<h2>❌ Error</h2>";
    echo "<pre>";
    echo "Database Error: " . $e->getMessage() . "\n";
    echo "\nPlease check your database credentials in this file.";
    echo "</pre>";
}
?>
