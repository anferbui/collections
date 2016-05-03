#include <stdint.h>

uint32_t t11_F1(uint32_t a, uint32_t b, uint32_t c, unsigned sizeMem)
{
	int32_t result = 0;
	if ((a-1) >= sizeMem){
		return 0;
	} else {
		result = (b & 0xFF);
	}

	if ((a-3) >= sizeMem){
		return 0;
	} else {
		result += ((c & 0xFFFF) << 8);
	}


	return result;
}

uint32_t t11_F2(uint32_t a, uint32_t b, unsigned sizeMem)
{
	int32_t result = b & 0xFFFF;

	if ((a+10) >= sizeMem){
		return 0;
	} 

	if ((b & 0x8000) != 0){
		result += 0xFFFF0000;
	}

	return result;
}
