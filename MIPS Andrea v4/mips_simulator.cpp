/* 
 * File:   mips_simulator.cpp
 * Author: Andrea
 *
 * Created on 07 November 2013, 20:18
 */

#include <stdint.h>
#include "mips.h"


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
){
    mips_state_t* state = new mips_state_t(); // Create a new object of class mips_state_t with dynamic memory
    state->registers = new uint32_t[32]();   // Creates the 32 registers dinamically (they are by default set to 0)
    state->hilo = new uint32_t[2](); // Creates HI and LO dinamically

    // Sets the fields of the class to the values specified by the arguments
    state->pc = pc;
    state->npc = pc + 4; // next instruction to execute is just set to the word just after pc
    state->pMem = pMem;
    state->sizeMem = sizeMem;

    return state; // returns a pointer to the object created
}

/*! Takes an existing state, and resets the registers.
	Should be equivalent to a state just returned from
	mips_create */
void mips_reset(struct mips_state_t *state, uint32_t pc){

    // sets all registers to 0
    for (int i =0; i<32; i++){
        state->registers[i] = 0;
    }
    
    // sets pc to the value specified by the argument, and npc to the word after it
    state->pc = pc;
    state->npc = pc + 4;
}

/*! Returns the current value of one of the 32 general
	purpose MIPS registers.*/
uint32_t mips_get_register(struct mips_state_t *state, unsigned index){
    return state->registers[index];
}

/*! Modifies one of the 32 general purpose MIPS registers. */
void mips_set_register(struct mips_state_t *state, unsigned index, uint32_t value){
    // Register 0 is by default 0 and can't be changed
    // if the register we want to change is not 0, then we change it
    if (index != 0 && index < 32){
        state->registers[index] = value;
    }
}

/*! Advances the processor by one instruction. If no error
	occured, then return zero. For anything
	which stops execution, return non-zero. */
int mips_step(struct mips_state_t *state){

    // if the current PC is bigger or equal than the size of the memory 
    //then there are no more instructions to execute and we just return an error
    if (state->pc >= state->sizeMem){
        return 1;
    }
    
    // We use shifts and ANDs to select the right bits from memory
    // where pMem[0] is byte 0 of word 0 (memory is byte addressable)
    uint8_t opcode = (state->pMem[state->pc] >> 2) & 0x3F; // the opcode is the first 6 bits of the word (we're using big endian)
    
    // if the opcode is 0, then it's an R-type instruction
    if (opcode == 0x0){
        // we return whatever the function we're calling returns (0 if not error, non-zero if error)
        return state->mips_r_type();
    }
    
    // if the opcode is 2 or 3, then it's a J-type instruction
    if (opcode == 0x2 || opcode == 0x3){
        return state->mips_j_type();
    }

    // any other opcode is I-type
    return state->mips_i_type(); 
}

/*! Free all resources associated with state. */
void mips_free(struct mips_state_t *state){
    // deletes the registers that we created dinamically
    delete[] state->registers;
    delete[] state->hilo;

    // deletes the object we created dinamically
    delete state;
}   

int mips_state_t::mips_r_type (){
    uint16_t instr = ((pMem[pc + 2] & 0x07) << 8) + (pMem[pc + 3]);   // selects the last 11 bits of the current word
                                                                    // these represent the instruction to execute

    // The values for source1, source2 and destination are stored into temporary variables
    uint8_t s = get_s();
    uint8_t t = get_t();
    uint8_t d = get_dest();

    // List of ifs, one for each possible instruction
    // Each of them returns 0 inside (except for possible exceptions)
    // If we reach the end of this function and we still haven't returned any value, then the instruction hasn't been recognized
    // So we return 1 and advance the pc so that the simulation is not stuck on any one instruction

    // JR jump to register
    if (instr == 0x08){
        pc = npc; // pc becomes the next instruction to execute
        npc = registers[s]; // npc becomes the value in the register
        return 0;
    }

    // ADD; add with overflow
    if (instr == 0x20){
        int32_t reg1 = registers[s];
        int32_t reg2 = registers[t];
        int32_t result = reg1 + reg2;
        
        if ( result > 0){
            if (reg1 < 0  && reg2 < 0){     
                // if both numbers are negative and the result is positive, then it is an exception
                advance_pc(4);
                return 1;
            }
        } else if (result < 0){ 
            // if both numbers are positive and the result is a negative number, then it is an exception
            if (reg1 > 0  && reg2 > 0){
                advance_pc(4);
                return 1;
            }
        }
        
        registers[d] = result; // if there's no exception, put the result in the registers

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }
    
    // ADDU; add unsigned
    if (instr == 0x21){
        registers[d] = registers[s] + registers[t];
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SUB; subtract with overflow
    if (instr == 0x22){
        // Same as ADD, but we take the 2's complement of the 2nd operand
        int32_t reg1 = registers[s];
        int32_t reg2 = - (registers[t]);
        int32_t result = reg1 - registers[t];
        if ( result > 0){
            if (reg1 < 0  && reg2 < 0){     
                // if both numbers are negative and the result is positive, then it is an exception
                advance_pc(4);
                return 1;
            }
        }else if (result < 0){ 
        // if both numbers are positive and the result is a negative number, then it is an exception
            if (reg1 > 0  && reg2 > 0){
                advance_pc(4);
                return 1;
            }
        }

        registers[d] = result; // if there's no exception, put the result in the registers

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }
    
    // SUBU; subtract unsigned
    if (instr == 0x23){
        registers[d] = registers[s] - registers[t];
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }
    
    // AND; bitwise Andrea
    if (instr == 0x24){
        registers[d] = registers[s] & registers[t];
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // OR; bitwise or
    if (instr == 0x25){
        registers[d] = registers[s] | registers[t]; 
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // XOR; bitwise exclusive or
    if ((instr & 0x3F) == 0x26){
        registers[d] = registers[s] ^ registers[t];
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SLL; shift left logical, can also be considered NOP (no operation) if 0x00000000
    if ((instr & 0x3F) == 0x0){
        uint8_t shift = (instr >> 6)& 0x1F ; // in the case SLL, SRL and SRA, the shift is specified as part of the instruction code
                                            // the first 5 bits of the code are the amount to shift

        registers[d] = registers[t] << shift;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SRL; shift right logical
    if ((instr & 0x3F) == 0x2){
        uint8_t shift = (instr >> 6) & 0x1F;
        registers[d] =  registers[t] >> shift; // shifts in 0s because it's an unsigned number

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SRA; shift right arithmetic
    if ((instr & 0x3F) == 0x3){
        uint8_t shift = (instr >> 6) & 0x1F;

        registers[d] = ((int32_t)registers[t]) >> shift; // shifts in 1s because we cast it as a signed number

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SRLV; shift right logical variable
    if (instr == 0x6){
        uint8_t shift = registers[s] & 0x1F; // the shift is the last 5 bits of the register
        registers[d] = registers[t] >> shift;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SLLV; shift left logical variable
    if ((instr & 0x3F) == 0x4){
        uint8_t shift = registers[s] & 0x1F; // the shift is the last 5 bits of the register
        registers[d] = registers[t] << shift;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // DIV; divide
    if (instr == 0x1A){
        hilo[0] = (int32_t) registers[s] % (int32_t)registers[t]; // HI constains the modulus (using signed values)
        hilo[1] = (int32_t)registers[s] / (int32_t)registers[t]; // LO contains the result of the division (using signed values)

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // DIVU; divide unsigned
    if (instr == 0x1B){
        hilo[0] = registers[s] % registers[t]; // HI contains the modulus
        hilo[1] = registers[s] / registers[t]; // LO contains the result of the division

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // MULT; multiply
    if (instr == 0x18){
        int64_t result = (int64_t) registers[s] * (int64_t)registers[t];
        hilo[0] = result >> 32; // HI contains the upper 32 bits of the result
        hilo[1] = result; // LO contains the lower 32 bits

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // MULTU; multiply unsigned
    if (instr == 0x19){
        uint64_t result = (uint64_t) registers[s] * (uint64_t) registers[t];
        hilo[0] = result >> 32;
        hilo[1] = result;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // MFHI; move from hi
    if (instr == 0x10){
        registers[d] = hilo[0];

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }
    
    // MFLO; move from lo
    if (instr == 0x12){
        registers[d] = hilo[1];

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SLTU; set on less than unsigned
    if (instr == 0x2B){
        if (registers[s] < registers[t]){
            registers[d] = 1;
        } else {
            registers[d] = 0;
        }
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SLT; set on less than signed
    if (instr == 0x2A){
        int32_t reg1 = registers[s];
        int32_t reg2 = registers[t];
        if ( reg1 < reg2){
            registers[d] = 1;
        } else {
            registers[d] = 0;
        }
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // It's the end of the function and no instruction has been recognized (if it had, the function would have returned already)
    // so we return an error and advance the pc so we're not stuck in the unrecognized instruction
    advance_pc(4);
    return 1;
}

int mips_state_t::mips_j_type (){
    uint8_t instr = pMem[pc] >> 2; // The opcode is the first 6 bits of the word

    // J; jump
    if (instr == 0x02){
        uint32_t target = ((pMem[pc] & 0x03) << 24) + (pMem[pc +1] << 16) + (pMem[pc +2] << 8) + pMem[pc +3] ; // everything in the memory word but the opcode is the address to jump to
        pc = npc; // we execute the next word before jumping
        
        //we muliply the target times 2 so that we're dealing with words and not bytes
        // this jumps to any 28 bit address in the current region of PC
        // since the target is only 26 bits (28 when we shift it to the left 2 positions)
        // but PC is 32 bits, so we still maintain bits 0-4 of the PC, changing only the 28 we can address
        npc = (pc & 0xf0000000) | (target << 2); 

        return 0; // advance the pc to the next instruction
    }

    // JAL; jump and link
    if (instr == 0x03){
        uint32_t target = ((pMem[pc] & 0x03) << 24) + (pMem[pc +1] << 16) + (pMem[pc +2] << 8) + pMem[pc +3];
        registers[31] = npc + 4; // we save the value of pc to register 31 so we can go back to it

        pc = npc;
        npc = (pc & 0xf0000000) | (target << 2);
        return 0; // advance the pc to the next instruction

    }

    advance_pc(4); // advance the pc to the next instruction
    return 1;
}

int mips_state_t::mips_i_type (){
    uint8_t instr = (pMem[pc] >> 2) & 0x3F;

    // The values for source1, source2 and immediate are stored into temporary variables
    // The same structure is used for this function as for mips_r_type()
    uint8_t s = get_s();
    uint8_t t = get_t();
    uint16_t immediate = get_immediate();
    uint32_t mAddress = registers[s] + (int32_t) immediate; // the memory address is the value in register_s plus the signed immediate
                                                            // this is for loads/stores
    
    // LBU; LOAD BYTE unsigned
    if (instr == 0x24){
        // if the address we want to load from is out of bounds, return an error
        if (mAddress >= sizeMem){
            advance_pc(4);
            return 1;
        }

        registers[t] = pMem[mAddress];

        advance_pc(4); // advance the pc to the next instruction
        return 0;

    }

    // LB; LOAD BYTE signed
    if (instr == 0x20){
        // if the address we want to load from is out of bounds, return an error
        if (mAddress >= sizeMem){
            advance_pc(4);
            return 1;
        }

        uint32_t result = pMem[mAddress];

        if ((result & 0x00000080) != 0){ // if the byte we stored was negative (first bit has value 1), we sign extend
            result += 0xFFFFFF00;
        }
        
        registers[t] = result;

        advance_pc(4);    // advance the pc to the next instruction
        return 0;
    }

    // LHU; LOAD HALFWORD unsigned
    if (instr == 0x25){
        // if the address we want to load from is out of bounds, return an error
        // there is also an error if mAddress is not poiting to the middle of a word
        if (mAddress >= sizeMem || mAddress%2 != 0){
            advance_pc(4);
            return 1;
        }

        registers[t] = (pMem[mAddress] << 8) + pMem[mAddress+1];

        advance_pc(4); // advance the pc to the next instruction
        return 0;

    }

    // LH; LOAD HALFWORD signed
    if (instr == 0x21){
        // if the address we want to load from is out of bounds, return an error
        // there is also an error if mAddress is not poiting to the middle of a word
        if (mAddress >= sizeMem || mAddress%2 != 0){
            advance_pc(4);
            return 1;
        }

        uint32_t result = (pMem[mAddress] << 8) + pMem[mAddress+1];

        if ((result & 0x00008000) != 0){ // if the halfword we stored was negative (first bit has value 1), we sign extend
            result += 0xFFFF0000;
        }

        registers[t] = result;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // LW; LOAD WORD
    if (instr == 0x23){
        // if the address we want to load from is out of bounds, return an error
        // there is also an error if mAddress is not poiting to the beginning of a word
        if (mAddress >= sizeMem || mAddress%4 != 0){
            advance_pc(4);
            return 1;
        }

        registers[t] = (pMem[mAddress] << 24) + (pMem[mAddress+1] << 16) + (pMem[mAddress+2] << 8) + pMem[mAddress+3];

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // LWL; LOAD WORD LEFT
    if (instr == 0x22){
        // if the address we want to load from is out of bounds, return an error
        if (mAddress >= sizeMem){
            advance_pc(4);
            return 1;
        }

        uint8_t* dest = (uint8_t*) &(registers[t]); // this is in order to make the register byte addressable
                                                    // we cast the address of the register as a 8 bit pointer instead of a 32 bit one
                                                    // this way of addressing is little endian, so dest[0] is the right-most byte of the register

        for (int i = mAddress%4; i<4; i++){ // we only want to copy data from the current word, so we use %4 to know where within a word we are
            *(dest + i) = pMem[mAddress + (3 - i)];
        }

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // LWR; LOAD WORD RIGHT
    if (instr == 0x26){
        // if the address we want to load from is out of bounds, return an error
        if (mAddress >= sizeMem){
            advance_pc(4);
            return 1;
        }

        uint8_t* dest = (uint8_t*) &(registers[t]); // this is in order to make the register byte addressable
                                                    // we cast the address of the register as a 8 bit pointer instead of a 32 bit one
                                                    // this way of addressing is little endian, so dest[0] is the right-most byte of the register

        for (int i = mAddress%4; i>=0; i--){ // we only want to copy data from the current word, so we use %4 to know where within a word we are
            *(dest + i) = pMem[mAddress - i];
        }

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SB; STORE BYTE
    if (instr == 0x28){
        // if the address we want to store in is out of bounds, return an error
        if (mAddress >= sizeMem){
            advance_pc(4);
            return 1;
        }

        pMem[mAddress] = (registers[t] & 0xFF);   // we only copy to mem the last byte of the source register

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SW; STORE WORD
    if (instr == 0x2B){
        // if the address we want to store in is out of bounds, return an error
        // there is also an error if mAddress is not poiting to the beginning of a word
        if (mAddress >= sizeMem || mAddress%4 != 0){
            advance_pc(4);
            return 1;
        }

        uint32_t source = registers[t];

        pMem[mAddress] = source >> 24; // less significant byte
        pMem[mAddress + 1] = source >> 16;
        pMem[mAddress + 2] = source >> 8;
        pMem[mAddress + 3] = source; // most significant byte

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SH; STORE HALF-WORD
    if (instr == 0x29){
        // if the address we want to store in is out of bounds, return an error
        // there is also an error if mAddress is not poiting to the middle of a word
        if (mAddress >= sizeMem || mAddress%2 != 0){
            advance_pc(4);
            return 1;
        }

        uint32_t source = registers[t];

        pMem[mAddress] = source >> 8;
        pMem[mAddress + 1] = source;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }
    
    // ADDI; add immediate with overflow
    if (instr == 0x8){
        // Same as ADD but with an immediate instead of register 2
        int32_t reg1 = registers[s];
        int16_t imm = immediate;
        int32_t result = reg1 + (int32_t)imm;
        if ( result > 0){
            if (reg1 < 0  && imm < 0){     
                // if both numbers are signed and the result is positive, then it is an exception
                advance_pc(4);
                return 1;
            }
        } else if (result < 0){ 
        // if both numbers are unsigned and the result is a signed number, then it is an exception
            if (reg1 > 0  && imm > 0){
                advance_pc(4);
                return 1;
            }
        }
        
        registers[t] = result; // if there's no exception, put the result in the registers
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }
    
    // ADDIU; add immediate unsigned
    if (instr == 0x9){
        registers[t] = registers[s] + (int32_t) immediate;
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }
    
    //ANDI; bitwise and immediate
    if (instr == 0x0C){
        registers[t] = registers[s] & immediate;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    //ORI; bitwise or immediate
    if (instr == 0x0D){ 
        registers[t] = registers[s] | immediate;

        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    //XORI; bitwise exclusive or immediate
    if (instr == 0x0E){
        registers[t] = registers[s] ^ immediate;

        advance_pc(4); // advance the pc to the next instruction
        return 0;   
    }

    // BEQ; branch on equal
    if (instr == 0x04){
        int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word
        if (registers[s] == registers[t]){
            advance_pc(offset); // if they are equal, advance the pc a signed offset
        } else {
            advance_pc(4); // if not, advance to next word
        }

        return 0;
    }

    // multiple branches possible with this code
    if (instr == 0x01){
        int32_t reg1 = registers[s];

        // BGEZ; branch on greater than or equal to 0
        if (t == 0x01){
            int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word
            if (reg1 >= 0){
                advance_pc(offset); // if bigger/equal to 0, advance the pc a signed offset
            } else {
                advance_pc(4); // if not, advance to next word
            }
            return 0;
        }

        // BGEZAL; branch on greater than or equal to 0 and link
        if (t == 0x11){
            int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word

            if (reg1 >= 0){
                registers[31] = npc + 4; // since npc is going to be executed in the next cycle, we save the address of the instruction after it in reg31
                advance_pc(offset); // if bigger/equal to 0, advance the pc a signed offset
            } else {
                advance_pc(4); // if not, advance to next word
            }
            return 0;
        }

        // BLTZ; branch on less than zero
        if (t == 0x00){
            int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word
            if (reg1 < 0){
                advance_pc(offset); // if smaller than 0, advance the pc a signed offset
            } else {
                advance_pc(4); // if not, advance to next word
            }
            return 0;
        }

        // BLTZAL; branch on less than 0 and link
        if (t == 0x10){
            int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word
            if (reg1 < 0){
                registers[31] = npc + 4;
                advance_pc(offset); // if smaller than 0, advance the pc a signed offset
            } else {
                advance_pc(4); // if not, advance to next word
            }
            return 0;
        }
    }
 
    if (instr == 0x06){
        int32_t reg1 = registers[s];

        // BLEZ; branch on less than or equal to 0 
        if (t == 0x00){
            int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word
            if (reg1 <= 0){
                advance_pc(offset); // if smaller/equal to 0, advance the pc a signed offset
            } else {
                advance_pc(4); // if not, advance to next word
            }
            return 0;
        }
    }


    // BGTZ; branch on greater than 0
    if (instr == 0x07){
        int32_t reg1 = registers[s];

        if (t == 0x00){
            int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word
            if (reg1 > 0){
                advance_pc(offset); // if greater than 0, advance the pc a signed offset
            } else {
                advance_pc(4); // if not, advance to next word
            }
            return 0;
        }
    }

    // BNE; branch on not equal
    if (instr == 0x05){
        int16_t offset= immediate << 2; // we multiply by 4 so that we can only jump to the beginning of a word
        if (registers[s] != registers[t]){
            advance_pc(offset); // if not equal, advance the pc a signed offset
        } else {
            advance_pc(4); // if not, advance to next word
        }

        return 0;
    }

    // LUI; load upper immediate
    if (instr == 0x0F){
        registers[t] = immediate << 16; // loads the immediate into the upper 16 bits of a word
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SLTIU; set on less than immediate unsigned
    if (instr == 0x0B){
        if (registers[s] < immediate){
            registers[t] = 1; // if s smaller than the unsigned immediate, t = 1
        } else {
            registers[t] = 0; // else t = 0
        }
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // SLTI; set on less than immediate signed
    if (instr == 0x0A){
        int32_t reg1 = registers[s];
        int16_t imm = immediate;
        if ( reg1 < imm){
            registers[t] = 1; // if s smaller than the signed immediate, t = 1
        } else {
            registers[t] = 0; // else t = 0
        }
        
        advance_pc(4); // advance the pc to the next instruction
        return 0;
    }

    // It's the end of the function and no instruction has been recognized (if it had, the function would have returned already)
    // so we return an error and advance the pc so we're not stuck in the unrecognized instruction
    advance_pc(4);
    return 1;
}

// Takes bits 7-11 of the instruction (source 1)
uint8_t mips_state_t::get_s(){
     return (((pMem[pc] & 0x03) << 3) + (pMem[pc + 1] >> 5));
}

// Takes bits 12-17 of the instruction (source 2)
uint8_t mips_state_t::get_t(){
     return (pMem[pc + 1] & 0x1F);
}

// Takes bits 18-22 of the instruction (destination)
uint8_t mips_state_t::get_dest(){
     return ((pMem[pc + 2] >>  3) & 0x1F);
}

// Takes the lower 2 bytes of the instruction
uint16_t mips_state_t::get_immediate(){
     return ((pMem[pc + 2] << 8) + pMem[pc + 3]);
}

// Advances the pc a signed offset
void mips_state_t::advance_pc (int32_t offset){
    pc = npc; // pc becomes the next word
    npc += offset; // npc increases by the offset
}
