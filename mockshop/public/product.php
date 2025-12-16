<?php
// Product detail view with add-to-cart form.
require __DIR__ . '/../src/bootstrap.php';

$productId = sanitize_string($_GET['id'] ?? '');
$product = $productId ? get_product_by_id($productId) : null;

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

$title = $product ? ($product['name'] ?? 'Product') : 'Product not found';
require __DIR__ . '/../src/templates/header.php';
?>

<?php if (!$product): ?>
    <p>Product not found. <a href="/index.php">Go back to catalog</a>.</p>
<?php else: ?>
    <h2><?php echo e($product['name'] ?? ''); ?></h2>
    <?php if (!empty($product['image'])): ?>
        <div style="margin:10px 0;">
            <img src="<?php echo e($product['image']); ?>" alt="<?php echo e($product['name']); ?>" style="max-width:100%; height:auto; border:1px solid #e1e1e1; border-radius:6px;">
        </div>
    <?php endif; ?>
    <p><?php echo e($product['description'] ?? ''); ?></p>
    <p class="price">$<?php echo number_format($product['price'] ?? 0, 2); ?></p>
    <form method="post" action="/product.php?id=<?php echo urlencode($productId); ?>" style="margin-top:12px;">
        <input type="hidden" name="product_id" value="<?php echo e($productId); ?>">
        <label for="quantity">Quantity:</label>
        <input type="number" id="quantity" name="quantity" value="1" min="1" style="width:60px; margin-right:8px;">
        <button class="btn" type="submit">Add to cart</button>
    </form>
    <p style="margin-top:12px;"><a href="/index.php">Back to catalog</a></p>
<?php endif; ?>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
