<?php
// Ends the user session and returns to the catalog.
require __DIR__ . '/../src/bootstrap.php';

logout_user();
clear_cart();
set_flash('info', 'You have been logged out.');
redirect('/index.php');
