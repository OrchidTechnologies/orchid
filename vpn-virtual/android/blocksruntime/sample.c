/*
   Test your installation by running:

     clang -o sample -fblocks sample.c -lBlocksRuntime && ./sample

   The above line should result in:

     Hello world 2

   If you have everything correctly installed.
*/

#ifndef __BLOCKS__
#error must be compiled with -fblocks option enabled
#endif

#include <stdio.h>
#include <Block.h>

int main()
{
  __block int i;
  i = 0;
  void (^block)() = ^{
    printf("Hello world %d\n", i);
  };
  ++i;
  void (^block2)() = Block_copy(block);
  ++i;
  block2();
  Block_release(block2);
  return 0;
}
