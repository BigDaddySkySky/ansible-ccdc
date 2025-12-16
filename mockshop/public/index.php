<?php
// Product catalog landing page with quick add-to-cart.
require __DIR__ . '/../src/bootstrap.php';

route([
    'POST' => function () {
        $productId = sanitize_string($_POST['product_id'] ?? '');
        $quantity = (int) ($_POST['quantity'] ?? 1);
        $product = $productId ? get_product_by_id($productId) : null;

        if (!$product) {
            set_flash('error', 'Product not found.');
            redirect('/index.php');
        }

        add_to_cart($productId, $quantity);
        set_flash('success', 'Added to cart.');
        redirect('/cart.php');
    }
], function () {
    return null;
});

$products = load_products();
$title = 'Welcome';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Featured products</h2>
<div class="products">
    <?php foreach ($products as $product): ?>
        <div class="card">
            <h3><?php echo e($product['name'] ?? ''); ?></h3>
            <p><?php echo e($product['description'] ?? ''); ?></p>
            <div class="price">$<?php echo number_format($product['price'] ?? 0, 2); ?></div>
            <div style="margin-top:8px;">
                <a class="btn secondary" href="/product.php?id=<?php echo urlencode((string) $product['id']); ?>">View</a>
                <form method="post" action="/index.php" style="display:inline;">
                    <input type="hidden" name="product_id" value="<?php echo e((string) $product['id']); ?>">
                    <input type="hidden" name="quantity" value="1">
                    <button class="btn" type="submit">Add to cart</button>
                </form>
            </div>
        </div>
    <?php endforeach; ?>
</div>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
