<?php

// SnappyMail Bootstrap
// This file initializes the application and sets up the include path

if (!defined('APP_VERSION'))
{
	define('APP_VERSION', '2.38.2');
	define('APP_INDEX_ROOT_PATH', __DIR__ . DIRECTORY_SEPARATOR);
}

// Include the application bootstrap
if (file_exists(APP_INDEX_ROOT_PATH.'app/index.php'))
{
	require APP_INDEX_ROOT_PATH.'app/index.php';
}
else
{
	echo '[105] Missing '.APP_INDEX_ROOT_PATH.'app/index.php';
	is_callable('opcache_invalidate') && opcache_invalidate(__FILE__, true);
	exit(105);
}
