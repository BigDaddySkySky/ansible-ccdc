<?php
// Minimal dispatcher for handling request methods inside page scripts.

function route(array $handlers, ?callable $fallback = null)
{
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    if (isset($handlers[$method]) && is_callable($handlers[$method])) {
        return $handlers[$method]();
    }

    if ($fallback) {
        return $fallback();
    }

    http_response_code(405);
    echo 'Method not allowed';
    exit;
}
