
<form method="POST" enctype="multipart/form-data">
	<input type="text" name="text">
	<input type="file" name="file">
	<input type="submit">
</form>

<?php

if(array_key_exists('text',$_POST)){
	if($_POST['text']){//is nothing else
		$file='text.txt';
		echo($file."<br>");
		$fp = fopen($file, 'w');//must create,chmod__w the file first
		fwrite($fp, $_POST['text']);
		fclose($fp);
	}
}
if(array_key_exists('file',$_FILES)){
	$file=$_FILES['file']['tmp_name'];
	//if(is_uploaded_file($file))
	echo($file);
	rename($file,'file'); //move_uploaded_file
}

?>
