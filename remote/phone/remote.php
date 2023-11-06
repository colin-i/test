
<form method="GET">
	<input type="submit" name="a">
</form>

<?php
if(count($_GET)){
	$fp = fopen('remote.txt', 'w');//must create,chmod__w the file first
	fwrite($fp, "a");
	fclose($fp);

	$f='remote2.txt';
	do{
		sleep(5);
	}while(filesize($f)==0);//same
	$fp = fopen($f, 'r');
	$a=fread($fp,20);
	//$fp=freopen(NULL, "w", $fp);//undefined
	//ftruncate($fp, 0);//not working (working only at php -f)
	fclose($fp);
	$fp = fopen($f, 'w');
	fclose($fp);
	echo($a);
}
?>
