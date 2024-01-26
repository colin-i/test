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
if($a['sunrise']<=$t && $t<=$a['sunset']){  //daylight
	$remaining=$a['sunset']-$t;  //positive
	$passed=$t-$a['sunrise'];    //positive
}else{  //nightime
	$remaining=$t-$a['sunrise'];
	if($a['sunset']<$t){   //after evening, positive
		$remaining=-(3600*24-$remaining);  //turned to negative, the opposite value of the period
		$passed=$a['sunset']-$t;  //to keep sign tradition
	}else{   //until the morning
		$passed=-(3600*24-($a['sunset']-$a['sunrise'])-$remaining);  //same
	}
}
echo((int)($remaining/60)."_".(int)($passed/60));
?>
