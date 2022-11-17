#include "my_random.h"
#include <stdlib.h>

uint myRandom(uint max){
    uint random = 0;
    for (size_t i = 0; i <= (max/RAND_MAX); i++)
    {
        random += rand();
    }
    return random % max;
}