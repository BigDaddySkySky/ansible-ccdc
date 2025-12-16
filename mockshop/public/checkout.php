<?php
// Checkout flow that creates an order from the current cart.
require __DIR__ . '/../src/bootstrap.php';

require_login('/login.php');

route([
    'POST' => function () {
        $items = cart_items_detailed();
        if (empty($items)) {
            set_flash('error', 'Your cart is empty.');
            redirect('/cart.php');
        }

        $user = current_user();
        $total = cart_total($items);
        $orderItems = [];

        foreach ($items as $item) {
            $orderItems[] = [
                'id' => $item['product']['id'],
                'name' => $item['product']['name'],
                'price' => $item['product']['price'],
                'quantity' => $item['quantity'],
                'subtotal' => $item['subtotal'],
            ];
        }

        $order = add_order($user['email'], $orderItems, $total);
        clear_cart();
        set_flash('success', 'Order placed: ' . $order['id']);
        redirect('/profile.php');
    }
], function () {
    return null;
});

$items = cart_items_detailed();
$total = cart_total($items);
$title = 'Checkout';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Checkout</h2>

<?php if (empty($items)): ?>
    <p>Your cart is empty. <a href="/index.php">Add some products</a></p>
<?php else: ?>
    <p>Review your order below and confirm purchase.</p>
    <table>
        <thead>
            <tr>
                <th>Product</th>
                <th>Qty</th>
                <th>Price</th>
                <th>Subtotal</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($items as $item): ?>
                <tr>
                    <td><?php echo e($item['product']['name']); ?></td>
                    <td><?php echo e((string) $item['quantity']); ?></td>
                    <td>$<?php echo number_format($item['product']['price'], 2); ?></td>
                    <td>$<?php echo number_format($item['subtotal'], 2); ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <p style="text-align:right; font-size:18px;"><strong>Total: $<?php echo number_format($total, 2); ?></strong></p>

    <form method="post" action="/checkout.php" style="margin-top:12px;">
        <button type="submit" class="btn">Place order</button>
    </form>
<?php endif; ?>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
