

//https://github.com/jacketizer/libyuarel

#include <stdio.h>
#include <yuarel.h>

int main(int argc,char**argv)
{
	struct yuarel url;
	if (-1 == yuarel_parse(&url, argv[1])) {
		fprintf(stderr, "Could not parse url!\n");
		return 1;
	}
/*
	printf("Struct values:\n");
	printf("\tscheme:\t\t%s\n", url.scheme);
	printf("\thost:\t\t%s\n", url.host);
	printf("\tport:\t\t%d\n", url.port);
	printf("\tpath:\t\t%s\n", url.path);
	printf("\tquery:\t\t%s\n", url.query);
	printf("\tfragment:\t%s\n", url.fragment);
*/
//Absolute URL: scheme ":" [ "//" ] [ username ":" password "@" ] host [ ":" port ] [ "/" ] [ path ] [ "?" query ] [ "#" fragment ]

	printf("%s/%s",url.host,url.path);
	return 0;
}
