/* +AMDG */

#include<unistd.h>
#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<string.h>
#include "conv.h"
#include "process_date.h"

#define SIZE 256
#define MAXNUM 1000

int padding(char *s, int numpad, char charpad);

int main(int argc, char *argv[])
{
	char c;
	int opterr = 0;
	char *date = NULL; char *format = NULL;
	char seps[SIZE][SIZE];
	char buffer[SIZE];
	char finans[MAXNUM] = "";
	struct tm *thetime;
	time_t curtime;
	
	curtime = time(NULL);
	thetime = localtime(&curtime);

	while ((c = getopt(argc,argv,"vud:f:")) != -1) {
		switch (c) {
		case 'u':
			thetime = gmtime(&curtime);
			break;
		case 'd':
			date = optarg;
			process_date(date,thetime);
			break;
		case 'f':
			format = optarg;
			break;
		case 'v':
			printf("dozdate v3.1\n");
			printf("Copyright (C) 2011  Donald P. Goodman III\n");
			printf("License GPLv3+:  GNU GPL version 3 or "
			"later <http://gnu.org/licenses/gpl.html>\n");
			printf("This is free software:  you are free "
			"to change and redistribute it.  There is NO "
			"WARRANTY, to the extent permitted by law.\n");
			return 0;
			break;
		case '?':
			return 1;
			break;
		default:
			break;
		}
	}
	if (argv[optind] != NULL)
		format = argv[optind];
	else
		format = "@c";

/*	strftime(buffer,SIZE,format,thetime);*/
	printf("%s\n",format);
	tgmify(format,thetime);
	breakup(format,thetime);
	printf("%s\n",format);
	return 0;
}

int breakup(char *s, struct tm *thetime)
{
	int i, j, k;
	char tmp[SIZE];
	char tmp2[SIZE];

	for (i=0; s[i] != '\0'; ++i) {
		if (s[i] == '%') {
			k = i;
			for (j=0; !isalpha(s[i]); ++j, ++i)
				tmp[j] = s[i];
			tmp[j++] = s[i];
			tmp[j] = '\0';
			strftime(tmp2,SIZE,tmp,thetime);
			tokenize(tmp2);
			dateinsert(s,tmp2,j-1);
		}
	}
	return 0;
}

dateinsert(char *s, char *t, int pos)
{
	int i;
	size_t len, len2;

	len = strlen(t);
	len2 = strlen(s);
	for (i=0; s[i] != '%'; ++i);
	memmove(s+i+len-pos,s+i+1,len2-i);
	memcpy(s+i,t,len);

	return 0;
}

int tokenize(char *s)
{
	char *tok = NULL;
	int i; int j = 0;
	char *tokchars = " ,.:;\t\n\'\"!#$%^&*()%";
	char number[MAXNUM];
	char num[MAXNUM];

	strcpy(num,s);
	tok = strtok(num,tokchars);
	while (tok != NULL) {
		for (i=0; *(tok+i) != '\0'; ++i)
			number[i] = *(tok+i);
		number[i] = '\0';
		for (i=0; number[i] == '0'; ++i);
		if (isdigit(number[i]))
			dectodoz(number+i,(double) atoi(number));
		convert(number,s,tok);
		number[0] = '\0';
		tok = strtok(NULL,tokchars);
	}
	return 0;
}

int convert(char *number, char *theans, char *tok)
{
	int i,j;
	size_t len1, len2;
	char *spot;
	int newspot;

	len1 = strlen(tok);
	len2 = strlen(number);
	spot = strstr(theans,tok);
	newspot = theans - spot;
	if (len1 > len2) {
		memmove(number+(len1-len2),number,len2+1);
		for(i=0; i<(len1-len2); ++i)
			number[i] = '0';
		len2 = strlen(number);
	}
	memcpy(spot,number,len2);
	return 0;
}

int sectotim(char *s, struct tm *thetime)
{
	int tim;
	char tmp[SIZE];
	char tmp2[SIZE];
	int minutes;
	int seconds;

	strftime(tmp,SIZE,"%S",thetime);
	strftime(tmp2,SIZE,"%M",thetime);
	minutes = atoi(tmp2) * 60;
	seconds = atoi(tmp);
	tim = (minutes + seconds) * 5.76;
	dectodoz(s,(double)tim);
	return 0;
}

int tgmify(char *s, struct tm *thetime)
{
	int i,j,k;
	char tmp[SIZE];
	char tmp2[SIZE];
	size_t len;
	int numpad = 0;
	char charpad = ' ';

	len = strlen(s);
	for (i=0; s[i] != '\0'; ++i) {
		if (s[i] == '@') {
/*			for (j=i; !isalpha(s[j]) && (j-i) <= 4; ++j) {*/
			for (j=i; (isdigit(s[j]) || ispunct(s[j]) || s[j] ==
			'X' || s[j] == 'E') && (j-i) <= 4; ++j) {
				if (isdigit(s[j]) || s[j] == 'X' || s[j] == 'E') {
					for (j=j,k=0; isdigit(s[j]) || s[j] == 'X' ||
					s[j] == 'E'; ++j,++k)
						tmp[k] = s[j];
					tmp[k] = '\0';
					numpad = (int)doztodec(tmp);
					--j;
				} else if ((ispunct(s[j]) || s[j] == '0') && s[j] != '@') {
					charpad = s[j];
				}
			}
			switch (s[j]) {
			case 'c':
				strftime(tmp,SIZE,"%a %d %b %Y ",thetime);
				tokenize(tmp);
				strftime(tmp2,SIZE,"%H",thetime);
				tokenize(tmp2);
				padding(tmp2,numpad,charpad);
				strcat(tmp,tmp2);
				strcat(tmp,";@t");
				strftime(tmp2,SIZE," %Z",thetime);
				strcat(tmp,tmp2);
				padding(tmp,numpad,charpad);
				tgminsert(s,tmp,j-i);
				break;
			case 'C':
				strftime(tmp,SIZE,"%Y",thetime);
				tokenize(tmp);
				tmp[2] = '\0';
				padding(tmp,numpad,charpad);
				tgminsert(s,tmp,j-i);
				break;
			case 'y':
				strftime(tmp,SIZE,"%Y",thetime);
				tokenize(tmp);
				reverse(tmp);
				tmp[2] = '\0';
				reverse(tmp);
				padding(tmp,numpad,charpad);
				tgminsert(s,tmp,j-i);
				break;
			case 't':
				sectotim(tmp,thetime);
				len = strlen(tmp);
				if (numpad == 0) {
					numpad = 4;
					charpad = '0';
				}
				padding(tmp,numpad,charpad);
				tgminsert(s,tmp,j-i);
				break;
			case 'H':
				strftime(tmp,SIZE,"%H",thetime);
				tokenize(tmp);
				padding(tmp,numpad,charpad);
				tgminsert(s,tmp,j-i);
				break;
			case 'k':
				strftime(tmp,SIZE,"%H",thetime);
				dectodoz(tmp,(double)atoi(tmp));
				padding(tmp,numpad,charpad);
				tgminsert(s,tmp,j-i);
				break;
			case 'T':
				strftime(tmp,SIZE,"%H",thetime);
				tokenize(tmp);
				padding(tmp,numpad,charpad);
				strcat(tmp,";@t");
				tgminsert(s,tmp,j-i);
				break;
			default:
				fprintf(stderr,"dozdate:  no valid TGM "
				"conversion unit found\n");
				exit(1);
				break;
			}
			numpad = 0;
			charpad = ' ';
		}
	}
	return 0;
}

int padding(char *s, int numpad, char charpad)
{
	int i,j;
	size_t len;

	if (numpad == 0)
		return 0;
	len = strlen(s);
	j = numpad - len;
	if (j > 0) {
		memmove(s+j,s,len+1);
		for (i=0; i<j; ++i)
			s[i] = charpad;
	}
	return 0;
}

int tgminsert(char *full, char *insert, int inspoint)
{
	size_t len, lenfull;
	int i, j;

	len = strlen(insert);
	lenfull = strlen(full);
	for (i=0; full[i] != '@'; ++i);
	memmove(full+i+len-inspoint,full+i+1,lenfull+1);
	memcpy(full+i,insert,len);
	return 0;
}
