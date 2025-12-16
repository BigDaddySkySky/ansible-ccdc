<?php
// Data access for products backed by JSON files.

function products_file(): string
{
    return data_path('products.json');
}

function ensure_products_file(): void
{
    if (!file_exists(products_file())) {
        file_put_contents(products_file(), json_encode([], JSON_PRETTY_PRINT));
    }
}

function load_products(): array
{
    ensure_products_file();
    $raw = file_get_contents(products_file());
    $products = json_decode($raw, true);
    return is_array($products) ? $products : [];
}

function save_products(array $products): void
{
    file_put_contents(products_file(), json_encode(array_values($products), JSON_PRETTY_PRINT));
}

function get_product_by_id(string $productId): ?array
{
    foreach (load_products() as $product) {
        if ((string) $product['id'] === (string) $productId) {
            return $product;
        }
    }
    return null;
}
