#ifndef driver_helper_hpp
#define driver_helper_hpp

#include <stdlib.h>
#include <stdio.h>

#ifdef _WIN32
#include <winsock2.h>
#else
#include <arpa/inet.h>
#endif


enum{
	R_at=1,
	R_v0,	R_v1,
	R_a0,	R_a1,	R_a2,	R_a3,
	R_t0,	R_t1,	R_t2,	R_t3,	R_t4,	R_t5,	R_t6,	R_t7,
	R_s0,	R_s1,	R_s2,	R_s3,	R_s4,	R_s5,	R_s6,	R_s7,
	R_t8, 	R_t9,
	R_kt0,	R_kt1,
	R_gp,
	R_sp,
	R_s8,
	R_ra	
};

unsigned Driver_LoadInstructions(
	const char *srcName,
	uint32_t *pInstructionMem
){
	unsigned cInstructions=0;
	
	FILE *f=stdin;
	if(srcName){
		//fprintf(stderr, "Driver: reading from file '%s'.\n", srcName);
		f=fopen(srcName, "rb");
		if(NULL==f){
			fprintf(stderr, "Driver: couldn't open file '%s' for reading.\n", srcName);
			exit(1);
		}
	}
	
	while(1==fread(pInstructionMem, 4, 1, f)){
		++cInstructions;
		++pInstructionMem;
	}
	//fprintf(stderr, "Driver: read %d instructions.\n", cInstructions);
	
	if(f!=stdin){
		fclose(f);
	}
	
	return cInstructions;
}

#endif
