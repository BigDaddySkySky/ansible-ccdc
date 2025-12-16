<?php
// Admin orders page with full access and weak protections (no CSRF, broad privileges).
require __DIR__ . '/../src/bootstrap.php';
require_admin();

$orders = load_orders();

route([
    'POST' => function () use (&$orders) {
        $action = $_POST['action'] ?? '';
        $orderId = sanitize_string($_POST['order_id'] ?? '');
        $status = sanitize_string($_POST['status'] ?? 'pending');

        if ($action === 'update_status') {
            foreach ($orders as &$order) {
                if ((string) $order['id'] === (string) $orderId) {
                    $order['status'] = $status;
                    save_orders($orders);
                    set_flash('success', 'Order status updated.');
                    redirect('/admin/orders.php');
                }
            }
            set_flash('error', 'Order not found.');
            redirect('/admin/orders.php');
        }
    }
], function () {
    return null;
});

$orders = load_orders();
$title = 'Admin Orders';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Orders</h2>
<table>
    <thead>
        <tr>
            <th>ID</th>
            <th>User</th>
            <th>Total</th>
            <th>Placed</th>
            <th>Status</th>
            <th>Items</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        <?php foreach ($orders as $order): ?>
            <tr>
                <td><?php echo e($order['id']); ?></td>
                <td><?php echo e($order['user_email'] ?? 'guest'); ?></td>
                <td>$<?php echo number_format($order['total'] ?? 0, 2); ?></td>
                <td><?php echo e($order['placed_at'] ?? ''); ?></td>
                <td><?php echo e($order['status'] ?? 'pending'); ?></td>
                <td>
                    <?php if (!empty($order['items'])): ?>
                        <?php foreach ($order['items'] as $item): ?>
                            <div><?php echo e($item['name'] ?? ''); ?> x <?php echo e((string) ($item['quantity'] ?? 0)); ?></div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </td>
                <td>
                    <form method="post" action="/admin/orders.php" style="display:flex; gap:6px; align-items:center;">
                        <input type="hidden" name="action" value="update_status">
                        <input type="hidden" name="order_id" value="<?php echo e($order['id']); ?>">
                        <select name="status">
                            <?php foreach (['pending','shipped','cancelled'] as $opt): ?>
                                <option value="<?php echo e($opt); ?>" <?php echo (($order['status'] ?? 'pending') === $opt) ? 'selected' : ''; ?>>
                                    <?php echo e($opt); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                        <button class="btn secondary" type="submit">Save</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </tbody>
</table>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
