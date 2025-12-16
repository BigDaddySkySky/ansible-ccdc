<?php
// Lightweight input sanitization and validation helpers.

function sanitize_string(?string $value): string
{
    return trim(strip_tags($value ?? ''));
}

function sanitize_email(?string $value): string
{
    return strtolower(trim($value ?? ''));
}

function validate_email(string $email): bool
{
    return (bool) filter_var($email, FILTER_VALIDATE_EMAIL);
}

function validate_password(string $password): bool
{
    return strlen($password) >= 6;
}
