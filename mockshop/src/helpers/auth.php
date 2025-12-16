<?php
// Authentication helpers: registration, login, logout, session state, and flash.

function set_flash(string $key, string $message): void
{
    $_SESSION['flash'][$key] = $message;
}

function get_flash(string $key): ?string
{
    if (isset($_SESSION['flash'][$key])) {
        $message = $_SESSION['flash'][$key];
        unset($_SESSION['flash'][$key]);
        return $message;
    }

    return null;
}

function current_user(): ?array
{
    return $_SESSION['user'] ?? null;
}

function register_user(string $name, string $email, string $password): array
{
    $cleanName = sanitize_string($name);
    $cleanEmail = sanitize_email($email);

    if ($cleanName === '') {
        return ['success' => false, 'error' => 'Name is required.'];
    }

    if (!validate_email($cleanEmail)) {
        return ['success' => false, 'error' => 'Enter a valid email address.'];
    }

    if (!validate_password($password)) {
        return ['success' => false, 'error' => 'Password must be at least 6 characters.'];
    }

    if (find_user_by_email($cleanEmail)) {
        return ['success' => false, 'error' => 'An account already exists for that email.'];
    }

    $user = add_user($cleanName, $cleanEmail, $password);
    session_regenerate_safe();
    $_SESSION['user'] = $user;

    return ['success' => true, 'user' => $user];
}

function login_user(string $email, string $password): array
{
    $cleanEmail = sanitize_email($email);

    if (!validate_email($cleanEmail)) {
        return ['success' => false, 'error' => 'Enter a valid email address.'];
    }

    $user = find_user_by_email($cleanEmail);

    if (!$user || !password_verify($password, $user['password'])) {
        return ['success' => false, 'error' => 'Invalid email or password.'];
    }

    session_regenerate_safe();
    $_SESSION['user'] = $user;

    return ['success' => true, 'user' => $user];
}

function logout_user(): void
{
    unset($_SESSION['user']);
    session_regenerate_safe();
}

function require_login(string $redirectPath = '/login.php'): void
{
    if (current_user()) {
        return;
    }

    set_flash('info', 'Please log in to continue.');
    $target = $_SERVER['REQUEST_URI'] ?? '/profile.php';
    redirect($redirectPath . '?redirect=' . urlencode($target));
}

function is_admin(): bool
{
    return !empty($_SESSION['admin']);
}

function require_admin(string $redirectPath = '/admin/index.php'): void
{
    if (is_admin()) {
        return;
    }

    set_flash('info', 'Admin login required.');
    $target = $_SERVER['REQUEST_URI'] ?? '/admin/products.php';
    redirect($redirectPath . '?redirect=' . urlencode($target));
}
