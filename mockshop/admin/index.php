<?php
// Admin login page with intentionally weak plaintext password checking.
// Weaknesses: plaintext password in config, no rate limiting, no hashing.
require __DIR__ . '/../src/bootstrap.php';

if (is_admin()) {
    redirect('/admin/products.php');
}

$redirectTarget = sanitize_string($_GET['redirect'] ?? '/admin/products.php');

route([
    'POST' => function () use ($securityConfig, $redirectTarget) {
        $password = $_POST['password'] ?? '';
        if ($password === ($securityConfig['admin_password'] ?? '')) {
            $_SESSION['admin'] = true;
            session_regenerate_safe();
            set_flash('success', 'Admin access granted.');
            $target = sanitize_string($_POST['redirect'] ?? $redirectTarget);
            redirect($target ?: '/admin/products.php');
        }

        set_flash('error', 'Incorrect admin password.');
        redirect('/admin/index.php' . ($redirectTarget ? ('?redirect=' . urlencode($redirectTarget)) : ''));
    }
], function () {
    return null;
});

$title = 'Admin Login';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Admin Login</h2>
<form method="post" action="/admin/index.php">
    <input type="hidden" name="redirect" value="<?php echo e($redirectTarget); ?>">
    <div style="margin-bottom:8px;">
        <label>Password</label><br>
        <input type="password" name="password" required style="width:100%; max-width:320px;">
    </div>
    <button class="btn" type="submit">Login</button>
</form>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
