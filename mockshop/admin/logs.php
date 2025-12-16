<?php
// Admin log viewer with weak sanitization (basename only) and no access controls beyond admin flag.
require __DIR__ . '/../src/bootstrap.php';
require_admin();

$logDir = base_path('data/logs');
$files = array_values(array_filter(scandir($logDir), function ($file) {
    return $file !== '.' && $file !== '..' && is_file($GLOBALS['logDir'] . '/' . $file);
}));

$selected = sanitize_string($_GET['file'] ?? '');
$content = '';

if ($selected) {
    $filePath = $logDir . '/' . basename($selected); // intentionally weak
    if (file_exists($filePath)) {
        $content = file_get_contents($filePath);
    } else {
        set_flash('error', 'Log file not found.');
    }
}

$title = 'Admin Logs';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Logs</h2>
<form method="get" action="/admin/logs.php" style="margin-bottom:12px;">
    <label>Select log file:</label>
    <select name="file">
        <option value="">-- choose --</option>
        <?php foreach ($files as $file): ?>
            <option value="<?php echo e($file); ?>" <?php echo ($file === $selected) ? 'selected' : ''; ?>>
                <?php echo e($file); ?>
            </option>
        <?php endforeach; ?>
    </select>
    <button class="btn secondary" type="submit">View</button>
</form>

<?php if ($selected): ?>
    <h3>Viewing: <?php echo e($selected); ?></h3>
    <pre style="background:#111; color:#0f0; padding:12px; max-height:400px; overflow:auto;"><?php echo htmlspecialchars($content); ?></pre>
<?php endif; ?>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
