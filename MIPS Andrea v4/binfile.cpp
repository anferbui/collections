/* 
 * File:   binfile.cpp
 * Author: Andrea
 *
 * Created on 07 November 2013, 20:48
 */

#include <cstdlib>
#include <stdio.h>
#include <iostream>
using namespace std;

uint32_t createR_Instr (uint16_t opcode, uint8_t s, uint8_t t, uint8_t dest); // creates an R-type instruction 
uint32_t createI_Instr (uint16_t opcode, uint8_t s, uint8_t t, uint16_t immediate); // creates an I-type instruction 
uint32_t createJ_Instr (uint16_t opcode, uint32_t address); // creates an J-type instruction 
uint32_t swapBytes(uint32_t instr); // swaps the bytes of a 32 bit variable


 // This cpp file creates the hexadecimal instructions for tests 6-12
 // And then saves them to their corresponding binary files

int main() {
    uint16_t imm = 0x8c;

    // We create arrays of 32 bit instructions

    // test_6
    // multiplication and division
    uint32_t a[13];
    a[0]= createR_Instr (0x18, 1, 3, 0); // mult reg1 and reg3
    a[1]= createR_Instr (0x12, 0, 0, 5); // mflo int reg5
    a[2]= createR_Instr (0x10, 0, 0, 4); // mfhi into reg4
    a[3]= createR_Instr (0x19, 1, 3, 0); // multu reg1 and reg3
    a[4]= createR_Instr (0x12, 0, 0, 2); // mflo into reg2
    a[5]= createR_Instr (0x1A, 1, 3, 0); // div reg1 and reg3
    a[6]= createR_Instr (0x12, 0, 0, 7); // mflo into reg7
    a[7]= createR_Instr (0x10, 0, 0, 6); // mfhi into reg6
    a[8]= createR_Instr (0x1B, 1, 3, 0); // divu reg1 and reg3
    a[9]= createR_Instr (0x12, 0, 0, 9); // mflo into reg9
    a[10]= createR_Instr (0x10, 0, 0, 8); // mfhi into reg8
    a[11]= createR_Instr (0x08,31,0,0); // jr
    a[12]= createR_Instr (0,0,0,0); // noop

    // test_7
    uint32_t b[7];
    b[0]= createR_Instr (0x21, 3, 0, 5); // addu reg3 and reg0 into reg5
    b[1]= createR_Instr (0x21, 2, 1, 2); // addu reg2 and reg1 into reg2
    b[2]= createR_Instr (0x23,5,4,5); // sub reg5 and reg4 into reg5
    b[3]= createI_Instr (0x01, 5, 1, -3); //  // b to the beginning if greater or equal to zero
    b[4]= createR_Instr (0,0,0,0); // noop
    b[5]= createR_Instr (0x08,31,0,0); // jr
    b[6]= createR_Instr (0,0,0,0); // noop

    // test 8
    uint32_t c[3];
    c[0]= createI_Instr (0x06, 3, 0, 2); //  // b to the end if less than or equal zero 
    c[1]= createR_Instr (0,0,0,0); // noop
    c[2]= createR_Instr (0x21, 3, 1, 2); // addu reg3 and reg1 into reg2

    //test 9
    // bitwise operations
    uint32_t d[8];
    d[0]= createR_Instr (0x25, 1,3,1); // or reg1 and reg3 into reg1
    d[1]= createR_Instr (0x24, 1,4,1); // and reg1 and reg4 into reg1
    d[2]= createR_Instr (0x26, 1,5,1); // xor reg1 and reg5 into reg1
    d[3]= createI_Instr (0x0C, 1, 1, imm); // andi
    d[4]= createI_Instr (0x0D, 1, 1, imm); // ori
    d[5]= createI_Instr (0x0E, 1, 2, imm); // xori
    d[6]= createR_Instr (0x08,31,0,0); // jr
    d[7]= createR_Instr (0,0,0,0); // noop

    // test 10
    // for overflow
    uint32_t g[6];
    g[0]= createR_Instr (0x20, 1,3,1); // add reg1 and reg3 into reg1
    g[1]= createI_Instr (0x8, 1,1,imm); // addi reg1 and imm into reg1
    g[2]= createR_Instr (0x22, 1,4,1); // sub reg1 and reg4 into reg1
    g[3]= createR_Instr (0x23, 1, 5, 2); // subu reg1 and reg5 into reg2
    g[4]= createR_Instr (0x08,31,0,0); // jr
    g[5]= createR_Instr (0,0,0,0); // noop


    //test 11
    // for loading/storing
    uint32_t f[8];
    f[0]= createI_Instr (0x28,1,3,-1); // sb
    f[1]= createI_Instr (0x29,1,4,-3); // sh
    f[2]= createI_Instr (0x23, 1,2, -4); // lw
    f[3]= createI_Instr (0x2B,1,3,8); // sw
    f[4]= createI_Instr (0x21, 1,5,10); // lh
    f[5]= createI_Instr (0x22, 1,6,20); // lwl
    f[6]= createR_Instr (0x08,31,0,0); // jr
    f[7]= createR_Instr (0,0,0,0); // noop


    // test 12
    // shifts
    uint32_t e[7];
    e[0]= createR_Instr (0xC0, 0,1,1); // sll
    e[1]= createR_Instr (0xC3, 0,1,1); // sra
    e[2]= createR_Instr (0xC2, 0,1,1); // srl
    e[3]= createR_Instr (0x4, 3, 1, 1); // sllv
    e[4]= createR_Instr (0x6, 4, 1, 2); // srlv
    e[5]= createR_Instr (0x08,31,0,0); // jr
    e[6]= createR_Instr (0,0,0,0); // noop


    // We now want to store these arrays into binary files

    FILE* binfile;
    binfile = fopen("t6_input-mips.bin", "w"); // open the file, write only
    fwrite(a, sizeof(uint8_t), sizeof(a), binfile); // write the array, 8 bits at a time, with a having a size of size(array), and writing it to the binfile we just opened
    fclose(binfile);

    binfile = fopen("t7_input-mips.bin", "w"); // open the file, write only
    fwrite(b, sizeof(uint8_t), sizeof(b), binfile); // write the array, 8 bits at a time, with a having a size of size(array), and writing it to the binfile we just opened
    fclose(binfile);

    binfile = fopen("t8_input-mips.bin", "w"); // open the file, write only
    fwrite(c, sizeof(uint8_t), sizeof(c), binfile); // write the array, 8 bits at a time, with a having a size of size(array), and writing it to the binfile we just opened
    fclose(binfile);

    binfile = fopen("t9_input-mips.bin", "w"); // open the file, write only
    fwrite(d, sizeof(uint8_t), sizeof(d), binfile); // write the array, 8 bits at a time, with a having a size of size(array), and writing it to the binfile we just opened
    fclose(binfile);

    binfile = fopen("t12_input-mips.bin", "w"); // open the file, write only
    fwrite(e, sizeof(uint8_t), sizeof(e), binfile); // write the array, 8 bits at a time, with a having a size of size(array), and writing it to the binfile we just opened
    fclose(binfile);

    binfile = fopen("t11_input-mips.bin", "w"); // open the file, write only
    fwrite(f, sizeof(uint8_t), sizeof(f), binfile); // write the array, 8 bits at a time, with a having a size of size(array), and writing it to the binfile we just opened
    fclose(binfile);

    binfile = fopen("t10_input-mips.bin", "w"); // open the file, write only
    fwrite(g, sizeof(uint8_t), sizeof(g), binfile); // write the array, 8 bits at a time, with a having a size of size(array), and writing it to the binfile we just opened
    fclose(binfile);



    return 0;
}

uint32_t createR_Instr (uint16_t opcode, uint8_t s, uint8_t t, uint8_t dest){
    uint32_t instr = (s << 21) + (t << 16) + (dest << 11) + opcode;
    return swapBytes(instr); // writing to a binary file is by default little endian, so we need to swap the bytes
}

uint32_t createI_Instr (uint16_t opcode, uint8_t s, uint8_t t, uint16_t immediate){
    uint32_t instr = (opcode << 26) + (s << 21) + (t << 16) + immediate;
    return swapBytes(instr); // writing to a binary file is by default little endian, so we need to swap the bytes
}

uint32_t createJ_Instr (uint16_t opcode, uint32_t address){
     uint32_t instr = (opcode << 26) + address;
     return swapBytes(instr); // writing to a binary file is by default little endian, so we need to swap the bytes
}

// Swaps the bytes of a 32 bit instruction, and returns the result
uint32_t swapBytes(uint32_t instr){
    uint32_t result;
    uint8_t * a = (uint8_t*) &result;
    uint8_t * b = (uint8_t*) &instr;

    for(int i =0; i<4; i++){
        a[i] = b[3-i];
    }

    return result;
}