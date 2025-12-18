<?php

if (!defined('APP_VERSION'))
{
	define('APP_VERSION', '2.38.2');
	define('APP_INDEX_ROOT_PATH', __DIR__ . DIRECTORY_SEPARATOR);
}

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
