#include <stdint.h>

uint32_t t12_F(uint32_t a, uint32_t b, uint32_t c)
{
	uint32_t result = (a << 3);
	result = ((int32_t) result) >> 3;
	result = result >> 3;
	result = (result << b) >> c;

	return result;
}
