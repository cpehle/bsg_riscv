//see LICENSE for license
// The following is a RISC-V program to test the functionality of the
// sha3 RoCC accelerator.
// Compile with riscv-gcc sha3-rocc.c
// Run with spike --extension=sha3 pk a.out

#include <assert.h>
#include <stdio.h>
#include <stdint.h>
#include "sha3.h"

int main() {

  do {

  uint64_t x = 123, y = 456, z = 0;
  printf("z=%d\n",z);
  // load x into accumulator 2 (funct=0)
  asm volatile ("custom1 x0, %0, 2, 0" : : "r"(x));
  // read it back into z (funct=1) to verify it
  asm volatile ("custom1 %0, x0, 2, 1" : "=r"(z));
  printf("z=%d\n",z);
  assert(z == x);
  // accumulate 456 into it (funct=3)
  asm volatile ("custom1 x0, %0, 2, 3" : : "r"(y));
  // verify it
  asm volatile ("custom1 %0, x0, 2, 1" : "=r"(z));
  printf("z=%d\n",z);
  assert(z == x+y);
  // do it all again, but initialize acc2 via memory this time (funct=2)
  asm volatile ("custom1 x0, %0, 2, 2" : : "r"(&x));
  asm volatile ("custom1 x0, %0, 2, 3" : : "r"(y));
  asm volatile ("custom1 %0, x0, 2, 1" : "=r"(z));
  assert(z == x+y);

  printf("Accumulator success!\n");

    printf("start basic test 1.\n");
    // BASIC TEST 1 - 150 zero bytes

    // Setup some test data
    unsigned int ilen = 150;
    unsigned char input[150] = "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000";
    unsigned char output[SHA3_256_DIGEST_SIZE];

    asm volatile ("fence");
    // Invoke the acclerator and check responses

    // setup accelerator with addresses of input and output
    //              opcode rd rs1          rs2          funct   
    asm volatile ("custom0 0, %[msg_addr], %[hash_addr], 0" : : [msg_addr]"r"(&input), [hash_addr]"r"(&output));

    // Set length and compute hash
    //              opcode rd rs1      rs2 funct   
    asm volatile ("custom0 0, %[length], 0, 1" : : [length]"r"(ilen));
    asm volatile ("fence");
    // Check result
    int i = 0;
    unsigned char result[SHA3_256_DIGEST_SIZE] =
    {221,204,157,217,67,211,86,31,54,168,44,245,97,194,193,26,234,42,135,166,66,134,39,174,184,61,3,149,137,42,57,238};
    //sha3ONE(input, ilen, result);
    for(i = 0; i < SHA3_256_DIGEST_SIZE; i++){
      printf("output[%d]:%d ==? results[%d]:%d \n",i,output[i],i,result[i]);
      assert(output[i]==result[i]);
    }

  }while(0);

  
  printf("Sha3 success!\n");
  return 0;
}
