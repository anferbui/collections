#include <stdint.h>

uint64_t t6_F1(uint32_t a, uint32_t b)
{
	// signed multiplication
	return (int64_t)a * (int64_t) b;
}

uint64_t t6_F2(uint32_t a, uint32_t b)
{
	// unsigned multiplication
	return a*b;
}

uint64_t t6_F3(uint32_t a, uint32_t b)
{
	// signed division
	int64_t result = (int32_t) a % (int32_t) b;
	result = (result << 32) + (((int32_t)a / (int32_t)b) & 0xFFFFFFFF);
	return result; // result is 0xmmmmmmmmdddddddd, where 'm' stands for modulus and 'd' for division
}

uint64_t t6_F4(uint32_t a, uint32_t b)
{
	// unsigned division
	int64_t result = a % b;
	result = (result << 32) + (a / b);
	return result; // result is 0xmmmmmmmmdddddddd, where 'm' stands for modulus and 'd' for division
}
