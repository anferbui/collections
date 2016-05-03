#include <stdint.h>

uint32_t t9_F(uint32_t a, uint32_t b, uint32_t c, uint32_t d)
{
	uint16_t imm = 0x8C;
	uint32_t result = (((((a | b) & c) ^ d) & imm) | imm) ^ imm;
	return result;
}
