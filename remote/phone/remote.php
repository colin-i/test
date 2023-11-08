<body>
<?php

$fp = fopen('remote.txt', 'w');//must create,chmod__w the file first
fwrite($fp, "a");
fclose($fp);

$f='remote2.txt';//same
while(stat($f)['size']==0){
	sleep(1);
	clearstatcache();
}
$fp = fopen($f, 'r');
$a=fread($fp,20);
//$fp=freopen(NULL, "w", $fp);//undefined
//ftruncate($fp, 0);//not working (working only at php -f)
fclose($fp);
echo($a);

$fp = fopen($f, 'w');
fclose($fp);

$image = imagecreatefromjpeg('a.jpg');
ob_start();
imagepng($image);
$imgData=ob_get_clean();
imagedestroy($image);
echo '<img src="data:image/png;base64,'.base64_encode($imgData).'" />';

$fp = fopen('remote.txt', 'w');
fwrite($fp, "a");
fclose($fp);

?>
</body>
