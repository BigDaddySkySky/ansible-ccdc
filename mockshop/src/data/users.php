<?php
// Data access for user accounts stored in JSON.

function users_file(): string
{
    return data_path('users.json');
}

function ensure_users_file(): void
{
    if (!file_exists(users_file())) {
        $seedUser = [
            'id' => 1,
            'name' => 'Demo User',
            'email' => 'demo@example.com',
            'password' => password_hash('password123', PASSWORD_DEFAULT),
            'created_at' => date('c'),
        ];
        file_put_contents(users_file(), json_encode([$seedUser], JSON_PRETTY_PRINT));
    }
}

function load_users(): array
{
    ensure_users_file();
    $raw = file_get_contents(users_file());
    $users = json_decode($raw, true);
    return is_array($users) ? $users : [];
}

function save_users(array $users): void
{
    file_put_contents(users_file(), json_encode(array_values($users), JSON_PRETTY_PRINT));
}

function find_user_by_email(string $email): ?array
{
    foreach (load_users() as $user) {
        if (strtolower($user['email']) === strtolower($email)) {
            return $user;
        }
    }
    return null;
}

function add_user(string $name, string $email, string $password): array
{
    $users = load_users();
    $nextId = 1;
    foreach ($users as $user) {
        $nextId = max($nextId, (int) ($user['id'] ?? 0) + 1);
    }

    $newUser = [
        'id' => $nextId,
        'name' => $name,
        'email' => strtolower($email),
        'password' => password_hash($password, PASSWORD_DEFAULT),
        'created_at' => date('c'),
    ];

    $users[] = $newUser;
    save_users($users);
    return $newUser;
}
