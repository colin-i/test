

<body style="background-color: #101010; color: #ffffff;">

<embed id='a'></embed>

<?php
// ?0
if(array_key_exists('hosted',$_GET)){ //&hosted
?>
<script src="/dist/ruffle.js">
</script>
<?php
}
?>

<script>
const queryString = self.location.search;
const urlParams = new URLSearchParams(queryString);
const game = urlParams.keys().next().value;
function g(a,b,c){
return {g:a,w:b,h:c};
}
const data={
0:g('universe'),
b:g('Ball_Hit',800,400),
r:g('Roulette',800,670),
n:g('Naval_War',800,470),
cf:g('Card_Flip',650,680),
f:g('Fruit_Cocktail',800,400),
rc:g('Racecourse',800,440),
l:g('Lotto',800,530),
t:g('Turret_Defence',740,560),
tf:g('Treasure_Finder',800,580),
c:g('Cubes',550,500),
1:g('Ores_for_Ship'),
2:g('Driving_the_Ship'),
3:g('Planet_Landing'),
4:g('Rocks_Fall'),
5:g('Balls_Play'),
6:g('Asteroids'),
8:g('Moving_Forward'),
9:g('Jump'),
10:g('On_the_Rail'),
11:g('Space_Trip'),
12:g('Space_Zones'),
13:g('Rooms'),
14:g('Road'),
24:g('Mahjong')
}
const ob=data[game];
if(!ob.w){
	ob.w=800;ob.h=600;
	if(game!=0)ob.g=ob.g+'/_'+ob.g;
	else ob.g=ob.g+'/'+ob.g;
}
const e=document.getElementById("a");
e.width=ob.w;
e.height=ob.h;
e.src='/a/'+ob.g+'.swf';
</script>

</body>
