<?php
// Cart view with quantity updates and removal.
require __DIR__ . '/../src/bootstrap.php';

route([
    'POST' => function () {
        $action = $_POST['action'] ?? '';
        $productId = sanitize_string($_POST['product_id'] ?? '');
        $quantity = (int) ($_POST['quantity'] ?? 1);

        if ($action === 'remove' && $productId) {
            remove_from_cart($productId);
            set_flash('success', 'Item removed from cart.');
        } elseif ($action === 'update' && $productId) {
            update_cart_item($productId, $quantity);
            set_flash('success', 'Cart updated.');
        } elseif ($action === 'clear') {
            clear_cart();
            set_flash('success', 'Cart cleared.');
        }

        redirect('/cart.php');
    }
], function () {
    return null;
});

$items = cart_items_detailed();
$total = cart_total($items);
$title = 'Your Cart';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Your cart</h2>

<?php if (empty($items)): ?>
    <p>Your cart is empty. <a href="/index.php">Browse products</a></p>
<?php else: ?>
    <table>
        <thead>
            <tr>
                <th>Product</th>
                <th>Price</th>
                <th>Quantity</th>
                <th>Subtotal</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($items as $item): ?>
                <tr>
                    <td><?php echo e($item['product']['name'] ?? ''); ?></td>
                    <td>$<?php echo number_format($item['product']['price'] ?? 0, 2); ?></td>
                    <td>
                        <form method="post" action="/cart.php" style="display:flex; gap:6px; align-items:center;">
                            <input type="hidden" name="product_id" value="<?php echo e($item['product']['id']); ?>">
                            <input type="hidden" name="action" value="update">
                            <input type="number" name="quantity" min="1" value="<?php echo e((string) $item['quantity']); ?>" style="width:60px;">
                            <button type="submit" class="btn secondary">Update</button>
                        </form>
                    </td>
                    <td>$<?php echo number_format($item['subtotal'], 2); ?></td>
                    <td>
                        <form method="post" action="/cart.php">
                            <input type="hidden" name="product_id" value="<?php echo e($item['product']['id']); ?>">
                            <input type="hidden" name="action" value="remove">
                            <button type="submit" class="btn secondary">Remove</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <p style="text-align:right; font-size:18px;"><strong>Total: $<?php echo number_format($total, 2); ?></strong></p>

    <div style="display:flex; justify-content:space-between; align-items:center; margin-top:12px;">
        <form method="post" action="/cart.php">
            <input type="hidden" name="action" value="clear">
            <button type="submit" class="btn secondary">Clear cart</button>
        </form>
        <a class="btn" href="/checkout.php">Proceed to checkout</a>
    </div>
<?php endif; ?>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
