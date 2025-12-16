<?php
// Storage configuration; defaults to JSON files in the data directory.
return [
    'driver' => 'json',
    'paths' => [
        'products' => __DIR__ . '/../data/products.json',
        'users' => __DIR__ . '/../data/users.json',
        'orders' => __DIR__ . '/../data/orders.json',
    ],
];
