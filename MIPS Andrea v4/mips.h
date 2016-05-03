#ifndef mips_h
#define mips_h

#include <stdint.h>

class mips_state_t{

	// everything is private, mips_state_t can only be changed by friend functions and not by the user

    uint32_t pc; // Address of current instruction
    uint32_t npc; // Address of the next instruction to execute
    unsigned sizeMem; // size of memory
    uint8_t *pMem; // pointer to memory
    uint32_t *registers; // pointer to the 32-bit registers
    uint32_t *hilo; // pointer to the registers HI and LO (where hi is hilo[0] and lo is hilo[1])

	int mips_r_type (); // list of r instructions
	int mips_j_type (); // list of j instructions
	int mips_i_type (); // list of i instructions

	uint8_t get_s(); // 0000 00ss sss0 0000 0000 0000 0000 0000; returns source 1
	uint8_t get_t(); // 0000 0000 000t tttt 0000 0000 0000 0000; returns source 2
	uint8_t get_dest(); // 0000 0000 0000 0000 dddd d000 0000 0000; returns destination
	uint16_t get_immediate(); // 0000 0000 0000 0000 iiii iiii iiii iiii; returns immediate (for I type instructions)

	void advance_pc (int32_t offset); // advances the pc a signed offset

	// Declared as friends so that they can change mips_state_t's fields
    friend int mips_step(struct mips_state_t *state);
    friend void mips_reset(struct mips_state_t *state, uint32_t pc);
    friend struct mips_state_t *mips_create(uint32_t pc, unsigned sizeMem, uint8_t *pMem);
    friend uint32_t mips_get_register(struct mips_state_t *state, unsigned index);
	friend void mips_set_register(struct mips_state_t *state, unsigned index, uint32_t value);
	friend void mips_free(struct mips_state_t *state);
};

/*! Initialises state so that the addressable memory is bound
	to pMem, the processor has just been reset, and the next
	instruction to be executed is located at pc. The memory
	pointer to by pMem is guaranteed to remain valid until
	the corresponding call to mips_free.
*/
struct mips_state_t *mips_create(
	uint32_t pc,      //! Address of first instruction
	unsigned sizeMem, //! Number of addressable bytes
	uint8_t *pMem	  //! Pointer to sizeMem bytes
);

/*! Takes an existing state, and resets the registers.
	Should be equivalent to a state just returned from
	mips_create */
void mips_reset(struct mips_state_t *state, uint32_t pc);

/*! Returns the current value of one of the 32 general
	purpose MIPS registers.*/
uint32_t mips_get_register(struct mips_state_t *state, unsigned index);

/*! Modifies one of the 32 general purpose MIPS registers. */
void mips_set_register(struct mips_state_t *state, unsigned index, uint32_t value);

/*! Advances the processor by one instruction. If no error
	occured, then return zero. For anything
	which stops execution, return non-zero. */
int mips_step(struct mips_state_t *state);

/*! Free all resources associated with state. */
void mips_free(struct mips_state_t *state);

#endif
