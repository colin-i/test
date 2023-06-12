
<form method="GET">
	<input type="text" name="text">
</form>

<?php

if(array_key_exists('text',$_GET)){
	$fp = fopen('text.txt', 'w');
	fwrite($fp, $_GET['text']);
	fclose($fp);
}

?>
