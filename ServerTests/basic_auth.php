<?php
if (!isset($_SERVER['PHP_AUTH_USER'])) {
    header('WWW-Authenticate: Basic realm="Test Realm"');
    header('HTTP/1.0 401 Unauthorized');
    echo 'You hit cancel';
    exit;
} else {
	if ($_SERVER['PHP_AUTH_USER'] == 'admin' && $_SERVER['PHP_AUTH_PW'] == 'password')
	{
		echo "<p>Hello {$_SERVER['PHP_AUTH_USER']}.</p>";
		echo "<p>You entered {$_SERVER['PHP_AUTH_PW']} as your password.</p>";
	}
	else
	{
		echo "<p>Sorry, invalid credentials</p>";
	}
}
?>