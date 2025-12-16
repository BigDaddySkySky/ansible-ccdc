<?php
// Basic security toggles and session settings for the mock environment.
return [
    'session_name' => 'mockshop_session',
    'session_lifetime' => 0,
    'session_secure' => false,
    'session_httponly' => true,
    // Intentionally weak admin password (plaintext) for training scenarios.
    'admin_password' => 'admin123',
];
