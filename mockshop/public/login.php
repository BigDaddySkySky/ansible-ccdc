<?php
// Login and registration page for shoppers.
require __DIR__ . '/../src/bootstrap.php';

if (current_user()) {
    redirect('/profile.php');
}

$redirectTarget = sanitize_string($_GET['redirect'] ?? '/profile.php');

route([
    'POST' => function () use ($redirectTarget) {
        $action = $_POST['action'] ?? 'login';
        $target = sanitize_string($_POST['redirect'] ?? $redirectTarget);

        if ($action === 'register') {
            $result = register_user(
                $_POST['name'] ?? '',
                $_POST['email'] ?? '',
                $_POST['password'] ?? ''
            );
        } else {
            $result = login_user(
                $_POST['email'] ?? '',
                $_POST['password'] ?? ''
            );
        }

        if ($result['success'] ?? false) {
            set_flash('success', $action === 'register' ? 'Account created.' : 'Welcome back.');
            redirect($target ?: '/profile.php');
        }

        set_flash('error', $result['error'] ?? 'Unable to process request.');
        redirect('/login.php' . ($target ? ('?redirect=' . urlencode($target)) : ''));
    }
], function () {
    return null;
});

$title = 'Login';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Login</h2>
<form method="post" action="/login.php" style="margin-bottom:16px;">
    <input type="hidden" name="redirect" value="<?php echo e($redirectTarget); ?>">
    <div style="margin-bottom:8px;">
        <label>Email</label><br>
        <input type="email" name="email" required style="width:100%; max-width:320px;">
    </div>
    <div style="margin-bottom:8px;">
        <label>Password</label><br>
        <input type="password" name="password" required style="width:100%; max-width:320px;">
    </div>
    <button class="btn" type="submit" name="action" value="login">Login</button>
</form>

<h3>Create an account</h3>
<form method="post" action="/login.php">
    <input type="hidden" name="redirect" value="<?php echo e($redirectTarget); ?>">
    <div style="margin-bottom:8px;">
        <label>Name</label><br>
        <input type="text" name="name" required style="width:100%; max-width:320px;">
    </div>
    <div style="margin-bottom:8px;">
        <label>Email</label><br>
        <input type="email" name="email" required style="width:100%; max-width:320px;">
    </div>
    <div style="margin-bottom:8px;">
        <label>Password</label><br>
        <input type="password" name="password" required minlength="6" style="width:100%; max-width:320px;">
    </div>
    <button class="btn" type="submit" name="action" value="register">Register</button>
</form>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
