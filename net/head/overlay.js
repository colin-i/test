javascript:(function(){
	/* "use strict"; debugger; let overlay1; */
	let overlay2=null; /* placeholder for bottom overlay */
	function getSuffix(v){
		return v==1 ? '' : '_v'+v;
	}

	let label1 = document.createElement('div');
	label1.style.position = 'absolute';
	label1.style.top = '5px';
	label1.style.left = '5px';
	label1.style.color = 'white';
	label1.style.fontSize = '14px';
	label1.style.fontFamily = 'monospace';
	let widthPx, overlayTop, overlayBottom;
	function loadOverlay1(){
		let suffix = getSuffix(overlay1Variant);
		widthPx=parseInt(localStorage.getItem('overlayWidth'+suffix))||Math.floor(window.innerWidth/2); /* overlay width */
		overlayTop=parseInt(localStorage.getItem('overlayTop'+suffix))||0; /* solo top */
		overlayBottom=parseInt(localStorage.getItem('overlayBottom'+suffix))||0; /* solo bottom */
		label1.textContent = 'A' + overlay1Variant;
	}
	let overlay1Variant=parseInt(localStorage.getItem('overlay1Variant'))||1;
	loadOverlay1();

	let label2 = document.createElement('div');
	label2.style.position = 'absolute';
	label2.style.top = '5px';
	label2.style.left = '5px';
	label2.style.color = 'white';
	label2.style.fontSize = '14px';
	label2.style.fontFamily = 'monospace';
	let heightPx, overlay2Left, overlay2Right;
	function loadOverlay2(){
		let suffix = getSuffix(overlay2Variant);
		heightPx=parseInt(localStorage.getItem('overlayHeight'+suffix))||Math.floor(window.innerHeight/2); /* overlay2 height */
		overlay2Left=parseInt(localStorage.getItem('overlay2Left'+suffix))||0; /* solo left */
		overlay2Right=parseInt(localStorage.getItem('overlay2Right'+suffix))||0; /* solo right */
		label2.textContent = 'B' + overlay2Variant;
	}
	let overlay2Variant=parseInt(localStorage.getItem('overlay2Variant'))||1;
	loadOverlay2();

	let enterMode=false; /* toggle mode for solo edge adjustments */
	let a=false; /* save mode toggle */

	let overlay1a=document.createElement('div');
	overlay1a.style.position='fixed';
	overlay1a.style.top=overlayTop+'px';
	overlay1a.style.bottom=overlayBottom+'px';
	overlay1a.style.right='0';
	overlay1a.style.width=widthPx+'px';
	overlay1a.style.backgroundColor='black';
	overlay1a.style.zIndex='9999';
	overlay1a.addEventListener('click',overlayClick);
	overlay1a.appendChild(label1);

	let overlay2b=document.createElement('div'); /* create bottom overlay */
	overlay2b.style.position='fixed';
	overlay2b.style.bottom='0';
	overlay2b.style.left=overlay2Left+'px';
	overlay2b.style.right=overlay2Right+'px';
	overlay2b.style.height=heightPx+'px';
	overlay2b.style.backgroundColor='black';
	overlay2b.style.zIndex='9998';
	overlay2b.addEventListener('click',overlayClick);
	overlay2b.appendChild(label2);

	function add1(){
		overlay1=overlay1a;
		document.body.appendChild(overlay1);
	}
	function add2(){
		overlay2=overlay2b;
		document.body.appendChild(overlay2);
	}

	function overlayClick(e){
		if(a){
			if(e.currentTarget==overlay1){
				let suffix = getSuffix(overlay1Variant);
				localStorage.setItem('overlayWidth'+suffix,widthPx); /* save width */
				localStorage.setItem('overlayTop'+suffix,overlayTop); /* save top */
				localStorage.setItem('overlayBottom'+suffix,overlayBottom); /* save bottom */
				alert('saved overlay1 ' + overlay1Variant);
			}else{
				let suffix = getSuffix(overlay2Variant);
				localStorage.setItem('overlayHeight'+suffix,heightPx); /* save height */
				localStorage.setItem('overlay2Left'+suffix,overlay2Left); /* save left */
				localStorage.setItem('overlay2Right'+suffix,overlay2Right); /* save right */
				alert('saved overlay2 ' + overlay2Variant);
			}
		}else{
			if(e.currentTarget==overlay1){
				overlay1=null;
			}else{
				overlay2=null;
			}
			e.currentTarget.remove(); /* remove overlay on click */
		}
	}

	function keyHandler(e){
		e.preventDefault();

		let soloOverlay=overlay1 && !overlay2; /* right overlay solo */
		let soloOverlay2=overlay2 && !overlay1; /* bottom overlay solo */

		if(e.key=='ArrowLeft'){
			if(soloOverlay2){
				if(enterMode){ /* move left edge */
					overlay2Left--;
					overlay2.style.left=overlay2Left+'px';
				}else{ /* move right edge */
					overlay2Right++;
					overlay2.style.right=overlay2Right+'px';
				}
			}else if(overlay1){
				widthPx++;
				overlay1.style.width = widthPx + 'px';
			}
		}

		else if(e.key=='ArrowRight'){
			if(soloOverlay2){
				if(enterMode){ /* move left edge */
					overlay2Left++;
					overlay2.style.left=overlay2Left+'px';
				}else{ /* move right edge */
					overlay2Right--;
					overlay2.style.right=overlay2Right+'px';
				}
			}else if(overlay1){
				widthPx--;
				overlay1.style.width=widthPx+'px';
			}
		}

		else if(e.key=='ArrowUp'){
			if(soloOverlay){
				if(enterMode){ /* move top edge */
					overlayTop--;
					overlay1.style.top=overlayTop+'px';
				}else{ /* move bottom edge */
					overlayBottom++;
					overlay1.style.bottom=overlayBottom+'px';
				}
			}else if(overlay2){
				heightPx++;
				overlay2.style.height=heightPx+'px';
			}
		}

		else if(e.key=='ArrowDown'){
			if(soloOverlay){
				if(enterMode){ /* move top edge */
					overlayTop++;
					overlay1.style.top=overlayTop+'px';
				}else{ /* move bottom edge */
					overlayBottom--;
					overlay1.style.bottom=overlayBottom+'px';
				}
			}else if(overlay2){
				heightPx--;
				overlay2.style.height=heightPx+'px';
			}
		}

		else if(e.key==' '){
			if(!overlay2)add2();
		}

		else if(e.key=='Alt'){ /* ensure overlay is on DOM */
			if(!overlay1)add1();
		}

		else if(e.key=='Shift'){ /* save mode */
			a=true;
			alert('save mode');
		}

		else if(e.key=='Control'){ /* remove mode */
			a=false;
			alert('rem mode');
		}

		else if(e.key=='Enter'){ /* toggle enter mode */
			enterMode=!enterMode;
		}

		else if(e.key=='w'){
			overlayTop=0;
			overlay1.style.top='0px';
		}
		else if(e.key=='s'){
			overlayBottom=0;
			overlay1.style.bottom='0px';
		}
		else if(e.key=='a'){
			overlay2Left=0;
			overlay2.style.left='0px';
		}
		else if(e.key=='d'){
			overlay2Right=0;
			overlay2.style.right='0px';
		}

		else if (e.key == 'q'){
			document.removeEventListener('keydown', keyHandler);
			document.addEventListener('keydown', restoreHandler);
		}

		else if(e.key=='z'){
			overlay1Variant = overlay1Variant==3 ? 1 : overlay1Variant+1;
			localStorage.setItem('overlay1Variant',overlay1Variant);
			loadOverlay1();

			if(overlay1){
				overlay1.style.width=widthPx+'px';
				overlay1.style.top=overlayTop+'px';
				overlay1.style.bottom=overlayBottom+'px';
			}
		}
		else if(e.key=='x'){
			overlay2Variant = overlay2Variant==3 ? 1 : overlay2Variant+1;
			localStorage.setItem('overlay2Variant',overlay2Variant);
			loadOverlay2();

			if(overlay2){
				overlay2.style.height=heightPx+'px';
				overlay2.style.left=overlay2Left+'px';
				overlay2.style.right=overlay2Right+'px';
			}
		}
	}
	function restoreHandler(e){
		if (e.key == 'e'){
			document.removeEventListener('keydown', restoreHandler);
			document.addEventListener('keydown', keyHandler);
		}
	}
	document.addEventListener('keydown',keyHandler);
	add1();
})();
