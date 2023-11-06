
<?php
$curl = curl_init();
$url="https://wondrous-thankfully-swift.ngrok-free.app/remote.php";
curl_setopt_array($curl, array(
    CURLOPT_URL => $url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => '',
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 0,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_CUSTOMREQUEST => 'GET',
//CURLOPT_HTTPHEADER => [
//    'ngrok-skip-browser-warning: 2'
//]//or 'User-Agent: custom/non-standard' or like curl is sending the agent
));

$response = curl_exec($curl);

curl_close($curl);
echo($response);
?>
