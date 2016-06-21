#include <stdio.h>
#include <unistd.h>

 int main(void) { 
 int i=20;
 int *j;
 j=&i;
 while(*j>0)
 {	
 		if(*j>15)	sleep(2);
 		printf("Hello world %d!\n",*j); 
		(*j)--;	
 }

	return 0; 
	}
