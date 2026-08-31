<?php

echo date_default_timezone_get().PHP_EOL;

$year = (int)$argv[1];
$month = (int)$argv[2];

if (isset($argv[3])) {
	$offset = (int)$argv[3];
	date_default_timezone_set('Etc/GMT' . ($offset >= 0 ? '-' : '+') . abs($offset));
}

$c=file_get_contents(getenv("HOME")."/n/pat4");
$c=preg_split('/;/',$c);

for ($day = 1; $day <= cal_days_in_month(CAL_GREGORIAN, $month, $year); $day++) {
	$t = mktime(12, 0, 0, $month, $day, $year);

	$a = date_sun_info($t, $c[0], $c[1]);

	echo date('Y-m-d', $t) . ' ' . date('H:i:s', $a['sunset']) . "\n";
}
