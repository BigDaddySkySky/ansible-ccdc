<?php
// Admin user management with deletion and weak protections (no CSRF, no audit).
require __DIR__ . '/../src/bootstrap.php';
require_admin();

$users = load_users();

route([
    'POST' => function () use (&$users) {
        $action = $_POST['action'] ?? '';
        $id = (int) ($_POST['id'] ?? 0);

        if ($action === 'delete') {
            $users = array_values(array_filter($users, function ($u) use ($id) {
                return (int) ($u['id'] ?? 0) !== $id;
            }));
            save_users($users);
            set_flash('success', 'User deleted.');
            redirect('/admin/users.php');
        }
    }
], function () {
    return null;
});

$users = load_users();
$title = 'Admin Users';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Users</h2>
<table>
    <thead>
        <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Email</th>
            <th>Joined</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        <?php foreach ($users as $user): ?>
            <tr>
                <td><?php echo e((string) $user['id']); ?></td>
                <td><?php echo e($user['name'] ?? ''); ?></td>
                <td><?php echo e($user['email'] ?? ''); ?></td>
                <td><?php echo e($user['created_at'] ?? ''); ?></td>
                <td>
                    <form method="post" action="/admin/users.php" style="display:inline-block;">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<?php echo e((string) $user['id']); ?>">
                        <button class="btn secondary" type="submit">Delete</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </tbody>
</table>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
