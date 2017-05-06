//NOTE - Ensure pk version has memset as 1 on page fault (L216 & L219).
//Helps diff corrupt actual value 0 from intended value hex 0x01010101 
//ie. dec 16843009

#include <assert.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

int main() {
  uint64_t *x;
//  uint64_t *buff;
  uint64_t *z;

x=(uint64_t*)malloc(sizeof(uint64_t));
z=(uint64_t*)calloc(1,sizeof(uint64_t));

//// Guarantee that the middle of the buffer would end up on an unused page
//  buff = (uint64_t*)malloc(3 * 512 * sizeof(uint64_t)); 
//  x    = (uint64_t*)&buff[3 * 512 / 2];
////  printf("x = %d\n", *x); //Always success if rocket touches pages by reading x
//
////Accel reads from memory address x. Depending of version of pk, 2 cases: 
////1. With lazy allocation x reads random value (happens to be 0)
////2. Without lazy allocation x reads true value
//  asm volatile ("custom0 x0, %0, 2, 2" : : "r"(x));
//
////Rocket reads value from accel into z 
//  asm volatile ("custom0 %0, x0, 2, 1" : "=r"(z)); 
//
//  printf("z = %d\n",z); //Actual value
  printf("Malloc'ed x = %d\n", *x); //Intended value
  printf("Calloc'ed z = %d\n", *z); //Intended value
//
////If intended value is same as actual, it means rocket did NOT do lazy allocation
//  assert(z == *x);
//  printf("Success!\n");
}

