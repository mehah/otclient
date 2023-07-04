<?php
// CONFIG
$files_dir = "C:/UniServerZ/www/files";
$files_url = "http://localhost/files";
$files_and_dirs = array("init.lua", "data", "modules", "layouts");
$checksum_file = "checksums.txt";
$checksum_update_interval = 60; // seconds
$binaries = array(
    "WIN32-WGL" => "otclient_x64.exe",
    "WIN32-EGL" => "otclient_x64.exe",
    "WIN32-WGL-GCC" => "otclient_x64.exe",
    "WIN32-EGL-GCC" => "otclient_x64.exe",
    "X11-GLX" => "otclient_linux",
    "X11-EGL" => "otclient_linux",
    "ANDROID-EGL" => "", // we can't update android binary
    "ANDROID64-EGL" => "" // we can't update android binary
);
// CONFIG END

function sendError($error) {
    echo(json_encode(array("error" => $error)));
    die();    
}

$data = json_decode(file_get_contents("php://input"));
//if(!$data) {
//    sendError("Invalid input data");
//}

$version = $data->version ?: 0; // APP_VERSION from init.lua
$build = $data->build ?: ""; // 2.4, 2.4.1, 2.5, etc
$os = $data->os ?: "unknown"; // android, windows, mac, linux, unknown
$platform = $data->platform ?: ""; // WIN32-WGL, X11-GLX, ANDROID-EGL, etc
$args = $data->args; // custom args when calling Updater.check()
$binary = $binaries[$platform] ?: "";

$cache = null;
$cache_file = sys_get_temp_dir() . DIRECTORY_SEPARATOR . $checksum_file;
if (file_exists($cache_file) && (filemtime($cache_file) + $checksum_update_interval > time())) {
    $cache = json_decode(file_get_contents($cache_file), true);
}
if(!$cache) { // update cache
    $dir = realpath($files_dir);
    $rii = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir));
    $cache = array(); 
    foreach ($rii as $file) {
        if (!$file->isFile())
            continue;
        $path = str_replace($dir, '', $file->getPathname());
        $path = str_replace(DIRECTORY_SEPARATOR, '/', $path);
        $checksum = hash_file("crc32b", $file->getPathname());

        if ($checksum === true) {
            $parsed_checksum = ltrim($checksum, '0');
            if ($parsed_checksum === '') {
                $parsed_checksum = '0';
            }
            $cache[$path] = $parsed_checksum;
        }
    }
    file_put_contents($cache_file . ".tmp", json_encode($cache));
    rename($cache_file . ".tmp", $cache_file);
}
$ret = array("url" => $files_url, "files" => array(), "keepFiles" => false);
foreach($cache as $file => $checksum) {
    $base = trim(explode("/", ltrim($file, "/"))[0]); 
    if(in_array($base, $files_and_dirs)) {
        $ret["files"][$file] = $checksum;
    }
    if($base == $binary && !empty($binary)) {
        $ret["binary"] = array("file" => $file, "checksum" => $checksum);
    }
}

$body = json_encode($ret, JSON_PRETTY_PRINT);
header("Content-length: " . strlen($body));
echo($body);

?>