<?php
// Centralized session handling and regeneration helpers.

function session_bootstrap(array $securityConfig = []): void
{
    if (session_status() !== PHP_SESSION_NONE) {
        return;
    }

    if (!empty($securityConfig['session_name'])) {
        session_name($securityConfig['session_name']);
    }

    session_set_cookie_params([
        'lifetime' => $securityConfig['session_lifetime'] ?? 0,
        'secure' => $securityConfig['session_secure'] ?? false,
        'httponly' => $securityConfig['session_httponly'] ?? true,
        'path' => '/',
        'samesite' => 'Lax',
    ]);

    session_start();
}

function session_regenerate_safe(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        session_regenerate_id(true);
    }
}
