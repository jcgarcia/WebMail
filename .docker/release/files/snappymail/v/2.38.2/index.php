<?php

// SnappyMail Entry Point Bootstrap
// This replaces the empty index.php from the release

// Determine the root path
define('APP_VERSION_ROOT_PATH', __DIR__ . DIRECTORY_SEPARATOR);

// Load SnappyMail's include.php
if (is_file(APP_VERSION_ROOT_PATH . 'include.php')) {
	include APP_VERSION_ROOT_PATH . 'include.php';
} else {
	die('[105] Missing include.php at ' . APP_VERSION_ROOT_PATH);
}

