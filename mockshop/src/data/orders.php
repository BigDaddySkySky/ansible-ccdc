<?php
// Order storage and retrieval using JSON files.

function orders_file(): string
{
    return data_path('orders.json');
}

function ensure_orders_file(): void
{
    if (!file_exists(orders_file())) {
        file_put_contents(orders_file(), json_encode([], JSON_PRETTY_PRINT));
    }
}

function load_orders(): array
{
    ensure_orders_file();
    $raw = file_get_contents(orders_file());
    $orders = json_decode($raw, true);
    return is_array($orders) ? $orders : [];
}

function save_orders(array $orders): void
{
    file_put_contents(orders_file(), json_encode(array_values($orders), JSON_PRETTY_PRINT));
}

function add_order(?string $userEmail, array $items, float $total): array
{
    $orders = load_orders();
    $newOrder = [
        'id' => 'ord-' . bin2hex(random_bytes(3)),
        'user_email' => $userEmail,
        'items' => $items,
        'total' => round($total, 2),
        'placed_at' => date('c'),
    ];

    $orders[] = $newOrder;
    save_orders($orders);
    return $newOrder;
}

function get_orders_for_user(string $email): array
{
    $results = [];
    foreach (load_orders() as $order) {
        if (strtolower($order['user_email'] ?? '') === strtolower($email)) {
            $results[] = $order;
        }
    }
    return $results;
}
