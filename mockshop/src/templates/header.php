<?php
// Shared page header with simple styling and navigation.
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?php echo e($title ?? ($appConfig['name'] ?? 'MockShop')); ?></title>
    <style>
        body { font-family: Arial, sans-serif; margin:0; padding:0; background:#f7f7f7; color:#222; }
        header { background:#1f3c88; color:#fff; padding:12px 16px; display:flex; align-items:center; justify-content:space-between; }
        header a { color:#fff; text-decoration:none; margin-right:12px; font-weight:bold; }
        nav a:last-child { margin-right:0; }
        .container { max-width:960px; margin:20px auto; background:#fff; padding:16px; box-shadow:0 2px 6px rgba(0,0,0,0.05); }
        .products { display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr)); gap:12px; }
        .card { border:1px solid #e1e1e1; border-radius:6px; padding:12px; background:#fafafa; }
        .card h3 { margin-top:0; }
        .price { font-weight:bold; color:#1f3c88; }
        .btn { display:inline-block; padding:8px 12px; background:#1f3c88; color:#fff; text-decoration:none; border-radius:4px; border:none; cursor:pointer; }
        .btn.secondary { background:#555; }
        .flash { padding:10px 12px; margin:10px 0; border-radius:4px; }
        .flash.success { background:#e7f6ed; color:#1d6b3f; border:1px solid #b4e0c3; }
        .flash.error { background:#fdecea; color:#a1260f; border:1px solid #f5c6c0; }
        .flash.info { background:#eef3ff; color:#1f3c88; border:1px solid #c6d4ff; }
        form { margin:0; }
        table { width:100%; border-collapse:collapse; }
        th, td { padding:8px; border-bottom:1px solid #e1e1e1; text-align:left; }
    </style>
</head>
<body>
<header>
    <div>
        <a href="/index.php"><?php echo e($appConfig['name'] ?? 'MockShop'); ?></a>
    </div>
    <nav>
        <a href="/index.php">Home</a>
        <a href="/cart.php">Cart</a>
        <?php if (current_user()): ?>
            <a href="/profile.php">Profile</a>
            <a href="/logout.php">Logout</a>
        <?php else: ?>
            <a href="/login.php">Login</a>
        <?php endif; ?>
        <?php if (is_admin()): ?>
            <a href="/admin/products.php">Admin Panel</a>
        <?php endif; ?>
    </nav>
</header>
<div class="container">
    <?php foreach (['success', 'error', 'info'] as $type): ?>
        <?php if ($msg = get_flash($type)): ?>
            <div class="flash <?php echo e($type); ?>"><?php echo e($msg); ?></div>
        <?php endif; ?>
    <?php endforeach; ?>
