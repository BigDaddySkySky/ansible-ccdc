<?php
// Authenticated user profile and order history.
require __DIR__ . '/../src/bootstrap.php';

require_login('/login.php');

$user = current_user();
$orders = $user ? get_orders_for_user($user['email']) : [];
$title = 'Your Profile';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Account</h2>
<p><strong>Name:</strong> <?php echo e($user['name'] ?? ''); ?><br>
<strong>Email:</strong> <?php echo e($user['email'] ?? ''); ?></p>

<h3>Orders</h3>
<?php if (empty($orders)): ?>
    <p>No orders yet. <a href="/index.php">Shop now</a></p>
<?php else: ?>
    <table>
        <thead>
            <tr>
                <th>Order ID</th>
                <th>Date</th>
                <th>Total</th>
                <th>Items</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($orders as $order): ?>
                <tr>
                    <td><?php echo e($order['id']); ?></td>
                    <td><?php echo e(date('Y-m-d H:i', strtotime($order['placed_at']))); ?></td>
                    <td>$<?php echo number_format($order['total'], 2); ?></td>
                    <td>
                        <?php if (!empty($order['items'])): ?>
                            <?php foreach ($order['items'] as $item): ?>
                                <div><?php echo e($item['name']); ?> x <?php echo e((string) $item['quantity']); ?></div>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
<?php endif; ?>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
