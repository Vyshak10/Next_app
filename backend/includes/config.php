<?php
class Config {
    private static $config = [];

    /**
     * Load configuration from file
     * 
     * @param string $file Configuration file path
     * @return void
     */
    public static function load($file) {
        if (file_exists($file)) {
            self::$config = require $file;
        } else {
            throw new Exception("Configuration file not found: {$file}");
        }
    }

    /**
     * Get configuration value
     * 
     * @param string $key Dot notation key (e.g., 'app.name')
     * @param mixed $default Default value if key not found
     * @return mixed
     */
    public static function get($key, $default = null) {
        $keys = explode('.', $key);
        $config = self::$config;

        foreach ($keys as $segment) {
            if (!is_array($config) || !array_key_exists($segment, $config)) {
                return $default;
            }
            $config = $config[$segment];
        }

        return $config;
    }

    /**
     * Set configuration value
     * 
     * @param string $key Dot notation key
     * @param mixed $value Value to set
     * @return void
     */
    public static function set($key, $value) {
        $keys = explode('.', $key);
        $config = &self::$config;

        while (count($keys) > 1) {
            $key = array_shift($keys);
            if (!isset($config[$key]) || !is_array($config[$key])) {
                $config[$key] = [];
            }
            $config = &$config[$key];
        }

        $config[array_shift($keys)] = $value;
    }

    /**
     * Check if configuration key exists
     * 
     * @param string $key Dot notation key
     * @return bool
     */
    public static function has($key) {
        return self::get($key) !== null;
    }

    /**
     * Get all configuration
     * 
     * @return array
     */
    public static function all() {
        return self::$config;
    }
}

// Load default configuration
Config::load(__DIR__ . '/../config/app.php');
?> 