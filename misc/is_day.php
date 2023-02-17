<?php
$c=file_get_contents("/home/bc/n/pat4");
$c=preg_split('/;/',$c);
$t=time();
$a=date_sun_info($t,$c[0],$c[1]);//is fatal if , instead of .
if($argc==2){
	foreach ($a as $key => $val) {
		echo "$key: " . date("H:i:s", $val) . "\n";
	}
}
if($a['sunrise']<=$t && $t<=$a['sunset'])echo "1";
?>