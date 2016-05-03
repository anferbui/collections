#include <stdint.h>

uint32_t t8_F(uint32_t a, uint32_t b)
{
	if ((signed) b <= 0){
		return 0;
	} else {
		return a+b;
	}
}
