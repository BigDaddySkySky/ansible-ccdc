<?php
// Boots the mockshop: sessions, config loading, helpers, and simple autoloading.

// Base path helper for includes and data files.
if (!defined('APP_ROOT')) {
    define('APP_ROOT', dirname(__DIR__));
}

function base_path(string $path = ''): string
{
    return APP_ROOT . ($path ? '/' . ltrim($path, '/') : '');
}

function data_path(string $file): string
{
    return base_path('data/' . ltrim($file, '/'));
}

// Load configuration.
$appConfig = require base_path('config/app.php');
$databaseConfig = require base_path('config/database.php');
$securityConfig = require base_path('config/security.php');
$routesConfig = require base_path('config/routes.php');

// Autoload simple classes under src/ if added later.
spl_autoload_register(function ($class) {
    $path = __DIR__ . '/' . str_replace('\\', '/', $class) . '.php';
    if (file_exists($path)) {
        require_once $path;
    }
});

// Load helpers and data access layers in a predictable order.
$helperFiles = [
    __DIR__ . '/helpers/session.php',
    __DIR__ . '/helpers/validation.php',
    __DIR__ . '/helpers/response.php',
    __DIR__ . '/helpers/cart.php',
    __DIR__ . '/helpers/auth.php',
];

foreach ($helperFiles as $helperFile) {
    if (file_exists($helperFile)) {
        require_once $helperFile;
    }
}

// Start session after loading session helper.
if (function_exists('session_bootstrap')) {
    session_bootstrap($securityConfig);
}

foreach (glob(__DIR__ . '/data/*.php') as $dataFile) {
    require_once $dataFile;
}

require_once __DIR__ . '/router.php';
