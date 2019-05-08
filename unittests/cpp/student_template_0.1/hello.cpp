#include <stdio.h>
#include "lib/divide.h"

int main(int argc, char const *argv[]) {
  printf("%f / %f = %f\n", 6., 3., divide(6, 3));
  return 0;
}
