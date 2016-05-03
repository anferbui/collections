#include <stdint.h>

uint32_t t7_F(uint32_t a, uint32_t b, uint32_t c)
{
	uint32_t res = 0;
	while ((signed) b > 0){
		res += a;
		b = b - c;
	}
	return res;
}
