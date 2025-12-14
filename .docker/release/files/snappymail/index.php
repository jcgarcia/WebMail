<?php

// SnappyMail Bootstrap for flattened directory structure
// After flattening from snappymail/v/VERSION/ to root, this bootstraps the app

if (!defined('APP_VERSION'))
{
	define('APP_VERSION', '2.38.2');
	define('APP_INDEX_ROOT_PATH', __DIR__ . DIRECTORY_SEPARATOR);
}

// After flattening, include.php is now at root level
if (file_exists(APP_INDEX_ROOT_PATH.'include.php'))
{
	include APP_INDEX_ROOT_PATH.'include.php';
}
else
{
	echo '[105] Missing '.APP_INDEX_ROOT_PATH.'include.php';
	is_callable('opcache_invalidate') && opcache_invalidate(__FILE__, true);
	exit(105);
}
