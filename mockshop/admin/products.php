<?php
// Admin product CRUD page with intentionally weak validation and no CSRF protection.
require __DIR__ . '/../src/bootstrap.php';
require_admin();

$products = load_products();

route([
    'POST' => function () use (&$products) {
        $action = $_POST['action'] ?? '';
        $id = sanitize_string($_POST['id'] ?? '');
        $name = sanitize_string($_POST['name'] ?? '');
        $description = sanitize_string($_POST['description'] ?? '');
        $price = (float) ($_POST['price'] ?? 0);
        $image = sanitize_string($_POST['image'] ?? '');

        if ($action === 'add') {
            if ($id === '' || $name === '') {
                set_flash('error', 'ID and name are required.');
                redirect('/admin/products.php');
            }
            $products[] = [
                'id' => $id,
                'name' => $name,
                'description' => $description,
                'price' => $price,
                'image' => $image,
            ];
            save_products($products);
            set_flash('success', 'Product added.');
            redirect('/admin/products.php');
        }

        if ($action === 'update') {
            foreach ($products as &$product) {
                if ((string) $product['id'] === (string) $id) {
                    $product['name'] = $name;
                    $product['description'] = $description;
                    $product['price'] = $price;
                    $product['image'] = $image;
                    save_products($products);
                    set_flash('success', 'Product updated.');
                    redirect('/admin/products.php');
                }
            }
            set_flash('error', 'Product not found.');
            redirect('/admin/products.php');
        }

        if ($action === 'delete') {
            $products = array_values(array_filter($products, function ($p) use ($id) {
                return (string) $p['id'] !== (string) $id;
            }));
            save_products($products);
            set_flash('success', 'Product deleted.');
            redirect('/admin/products.php');
        }
    }
], function () {
    return null;
});

$products = load_products();
$title = 'Admin Products';
require __DIR__ . '/../src/templates/header.php';
?>

<h2>Products</h2>

<h3>Add Product</h3>
<form method="post" action="/admin/products.php" style="margin-bottom:16px;">
    <input type="hidden" name="action" value="add">
    <div><label>ID</label><br><input type="text" name="id" required style="width:300px;"></div>
    <div><label>Name</label><br><input type="text" name="name" required style="width:300px;"></div>
    <div><label>Description</label><br><textarea name="description" rows="3" style="width:300px;"></textarea></div>
    <div><label>Price</label><br><input type="number" step="0.01" name="price" value="0" style="width:120px;"></div>
    <div><label>Image URL</label><br><input type="text" name="image" style="width:300px;"></div>
    <button class="btn" type="submit" style="margin-top:8px;">Add</button>
</form>

<h3>Existing Products</h3>
<table>
    <thead>
        <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Price</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        <?php foreach ($products as $product): ?>
            <tr>
                <td><?php echo e($product['id']); ?></td>
                <td><?php echo e($product['name']); ?></td>
                <td>$<?php echo number_format($product['price'] ?? 0, 2); ?></td>
                <td>
                    <form method="post" action="/admin/products.php" style="display:inline-block;">
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="id" value="<?php echo e($product['id']); ?>">
                        <input type="text" name="name" value="<?php echo e($product['name']); ?>" style="width:120px;">
                        <input type="text" name="description" value="<?php echo e($product['description']); ?>" style="width:150px;">
                        <input type="number" step="0.01" name="price" value="<?php echo e((string) ($product['price'] ?? 0)); ?>" style="width:90px;">
                        <input type="text" name="image" value="<?php echo e($product['image'] ?? ''); ?>" style="width:140px;">
                        <button class="btn secondary" type="submit">Save</button>
                    </form>
                    <form method="post" action="/admin/products.php" style="display:inline-block;">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<?php echo e($product['id']); ?>">
                        <button class="btn secondary" type="submit">Delete</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </tbody>
</table>

<?php require __DIR__ . '/../src/templates/footer.php'; ?>
