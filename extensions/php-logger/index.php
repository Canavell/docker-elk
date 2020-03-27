<?php
require realpath(__DIR__ . "/../vendor/autoload.php");


use Monolog\Logger;
use Monolog\Handler\StreamHandler;

// create a log channel
$log = new Logger('name');
$log->pushHandler(new StreamHandler('my_app1.log', Logger::DEBUG));
// log the details of the user visit
$visitDetails = [
    'ip' => $_SERVER['REMOTE_ADDR'],
    'method' => $_SERVER['REQUEST_METHOD'],
    'uri' => $_SERVER['REQUEST_URI'],
    'agent' => $_SERVER['HTTP_USER_AGENT'],
    'referer' => $_SERVER['HTTP_REFERER'] ?? 'not set'
];

$log->error("Request", $visitDetails);