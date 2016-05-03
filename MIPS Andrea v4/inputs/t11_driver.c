#include "mips.h"

#include "driver_helper.h"

// This is the function which the simulator is running
#include "t11_input.c"

using namespace std;

int main(int argc,char *argv[])
{	
	unsigned i;
	
	if(argc>2){
		fprintf(stderr, "Usage: %s [file.bin]\n", argv[0]);
		exit(1);
	}
	
	unsigned cbMem=1<<20;
	uint8_t *pMem=(uint8_t*)malloc(cbMem);
	
	Driver_LoadInstructions(argc>1 ? argv[0] : "t11_input-mips.bin", (uint32_t*)pMem);
	
	struct mips_state_t *state=mips_create(
		0,	// pc
		cbMem,
		pMem
	);
	
	int fail=0;
	
	for(i=0;i<100;i++){
		uint32_t a=rand(), b=rand(), c=rand(), d= rand(), res_correct1, res_sim1, res_correct2, res_sim2, res_correct3, res_sim3;
	

		if (a < cbMem){
			pMem[a+20] = d >> 24;
			pMem[a+21] = d >> 16;
			pMem[a+22] = d >> 8;
			pMem[a+23] = d;
		}


		// Run the program from the beginning
		mips_reset(state, 0);
		
		// Return to nothing (cause simulator to fail)
		mips_set_register(state, R_ra, 0xFFFFFFFFu);

		// This is setting up the arguments
		mips_set_register(state, R_at, a);
		mips_set_register(state, R_v1, b);
		mips_set_register(state, R_a0, c);
	
		while(!mips_step(state)){
			// Keep stepping till it attempts to return to 0xFFFFFFFF
		}
		
		// Pull the result out
		res_sim1=mips_get_register(state, R_v0);
		res_sim2=mips_get_register(state, R_a1);
		res_sim3=mips_get_register(state, R_a2);
		
		// Get the true result
		res_correct1= t11_F1(a,b, c, cbMem);
		res_correct2= t11_F2(a,b, cbMem);

		if (a < cbMem){
			res_correct3= d;
		} else{
			res_correct3= 0;
		}
	
		if(res_sim1!=res_correct1){
			fprintf(stdout, "F1(%u,%u, %u), sim=%u, correct=%u\n", a, b,c, res_sim1, res_correct1);
			fail=1;
		}
		if(res_sim2!=res_correct2){
			fprintf(stdout, "F2(%u,%u, %u), sim=%u, correct=%u\n", a, b,c, res_sim2, res_correct2);
			fail=1;
		}
		if(res_sim3!=res_correct3){
			fprintf(stdout, "F3(%u,%u, %u), sim=%u, correct=%u\n", a, b,c, res_sim3, res_correct3);
			fail=1;
		}

	}		
	
	if (fail){
		fprintf(stdout, "Sorry, you failed! :(\n");
	} else {
		fprintf(stdout, "Congrats! Test passed.\n");
	}

	mips_free(state);	
	free(pMem);
	pMem=0;
	
	return fail;
}
