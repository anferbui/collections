#include <stdint.h>

using namespace std;

uint64_t t10_F(uint32_t a, uint32_t b, uint32_t c, uint32_t d)
{
	int16_t imm = 0x8c;

	int32_t reg1 = a;
    int32_t reg2 = b;
    int32_t result = reg1 + reg2;

    if ( result > 0){
            if (reg1 < 0  && reg2 < 0){
                return 0;
            }
        } else if (result < 0){
            if (reg1 > 0  && reg2 > 0){
                return 0;
            }
    }

	reg1 = result;
	reg2 = (int32_t)imm;
	result = reg1 + reg2;

    if ( result > 0){
            if (reg1 < 0  && reg2 < 0){
                return 0;
            }
        } else if (result < 0){
            if (reg1 > 0  && reg2 > 0){
                return 0;
            }
    }

	reg1 = result;
	reg2 = -c;
	result = reg1 + reg2;

    if ( result > 0){
            if (reg1 < 0  && reg2 < 0){
                return 0;
            }
        } else if (result < 0){
            if (reg1 > 0  && reg2 > 0){
                return 0;
            }
    }

	result = result - d;

	return result;
}
