
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(){
	FILE*f=fopen("q","rb");
	fseek(f,0,SEEK_END);
	size_t s=ftell(f);
	char*z=malloc(s);
	rewind(f);
	fread(z,s,1,f);
	fclose(f);
	char*zz=z+s;
	char*a=malloc(s);char*start=a;
	char*z2=z;

	while(true){
		z++;
		if(*z=='\t')break;
	}
	z++;
	s=z-z2;memcpy(a,z2,s);a+=s;z2=z;
	while(true){
		while(*z!='\t'){
			if(*z=='\n'){
				s=z-z2;memcpy(a,z2,s);a+=s;
				z++;
				z2=z;
			}else z++;
		}
		z++;
		s=z-z2;memcpy(a,z2,s);a+=s;z2=z;

		while(z!=zz){
			if(*z=='\n'){
				s=z-z2;memcpy(a,z2,s);a+=s;
				z++;
				z2=z;
			}else z++;
			if(*z=='\t')break;
		}
		if(z==zz){
			s=z-z2;memcpy(a,z2,s);a+=s;z2=z;
			break;
		}
		*a='\n';a++;
		z++;
		s=z-z2;memcpy(a,z2,s);a+=s;z2=z;
	}

	s=a-start;
	f=fopen("q","wb");
	fwrite(start,s,1,f);
	return 0;
}
