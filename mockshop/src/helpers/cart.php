<?php
// Session-based cart helpers for adding, updating, and summarizing items.

function get_cart(): array
{
    return $_SESSION['cart'] ?? [];
}

function add_to_cart(string $productId, int $quantity = 1): void
{
    $cart = get_cart();
    $cart[$productId] = ($cart[$productId] ?? 0) + max(1, $quantity);
    $_SESSION['cart'] = $cart;
}

function update_cart_item(string $productId, int $quantity): void
{
    $cart = get_cart();
    if ($quantity <= 0) {
        unset($cart[$productId]);
    } else {
        $cart[$productId] = $quantity;
    }
    $_SESSION['cart'] = $cart;
}

function remove_from_cart(string $productId): void
{
    $cart = get_cart();
    unset($cart[$productId]);
    $_SESSION['cart'] = $cart;
}

function clear_cart(): void
{
    unset($_SESSION['cart']);
}

function cart_items_detailed(): array
{
    $items = [];
    foreach (get_cart() as $productId => $quantity) {
        $product = get_product_by_id($productId);
        if (!$product) {
            continue;
        }

        $items[] = [
            'product' => $product,
            'quantity' => $quantity,
            'subtotal' => round($product['price'] * $quantity, 2),
        ];
    }

    return $items;
}

function cart_total(array $detailedItems): float
{
    $total = 0.0;
    foreach ($detailedItems as $item) {
        $total += $item['subtotal'];
    }
    return round($total, 2);
}
