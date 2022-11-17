#include "./my_random.h"
#include <stdlib.h>
#include <limits.h>

uint myRandom(uint max){
    uint random = 1;
    if (max == 0){
        max = UINT_MAX;
    }
    for (size_t i = 0; i <= (max/RAND_MAX); i++)
    {
        random *= rand();
        i <<= 15;
    }
    return random % max;
}