#include "Logger.h"
#include "header/lava_header.h"
#include "lava_kernel.h"
#include "util.h"
#include "TackerConfig.h"

extern Logger logger;

extern "C" __global__ void ori_lava(par_str d_par_gpu,
								dim_str d_dim_gpu,
								box_str* d_box_gpu,
								FOUR_VECTOR* d_rv_gpu,
								float* d_qv_gpu,
								FOUR_VECTOR* d_fv_gpu)
{

	int bx = blockIdx.x;
	int tx = threadIdx.x;
	int wtx = tx;

	if(bx<d_dim_gpu.number_boxes){
		// parameters
		float a2 = 2.0*d_par_gpu.alpha*d_par_gpu.alpha;

		// home box
		int first_i;
		FOUR_VECTOR* rA;
		FOUR_VECTOR* fA;
		__shared__ FOUR_VECTOR rA_shared[100];

		// nei box
		int pointer;
		int k = 0;
		int first_j;
		FOUR_VECTOR* rB;
		float* qB;
		int j = 0;
		__shared__ FOUR_VECTOR rB_shared[100];
		__shared__ double qB_shared[100];

		// common
		float r2;
		float u2;
		float vij;
		float fs;
		float fxij;
		float fyij;
		float fzij;
		THREE_VECTOR d;

		// home box - box parameters
		first_i = d_box_gpu[bx].offset;

		// home box - distance, force, charge and type parameters
		rA = &d_rv_gpu[first_i];
		fA = &d_fv_gpu[first_i];

		// home box - shared memory
		while(wtx<NUMBER_PAR_PER_BOX){
			rA_shared[wtx] = rA[wtx];
			wtx = wtx + NUMBER_THREADS;
		}
		wtx = tx;

		// synchronize threads  - not needed, but just to be safe
		__syncthreads();

		// loop over neiing boxes of home box
		for (k=0; k<(1+d_box_gpu[bx].nn); k++){

			if(k==0){
				pointer = bx; // set first box to be processed to home box
			}
			else{
				pointer = d_box_gpu[bx].nei[k-1].number; 
				// remaining boxes are nei boxes
			}

			// nei box - box parameters
			first_j = d_box_gpu[pointer].offset;

			// nei box - distance, (force), charge and (type) parameters
			rB = &d_rv_gpu[first_j];
			qB = &d_qv_gpu[first_j];

			// nei box - shared memory
			while(wtx<NUMBER_PAR_PER_BOX){
				rB_shared[wtx] = rB[wtx];
				qB_shared[wtx] = qB[wtx];
				wtx = wtx + NUMBER_THREADS;
			}
			wtx = tx;

			// synchronize threads because in next section each thread accesses data brought in by different threads here
			__syncthreads();

			// loop for the number of particles in the home box
			while(wtx<NUMBER_PAR_PER_BOX){

				// loop for the number of particles in the current nei box
				for (j=0; j<NUMBER_PAR_PER_BOX; j++){

					r2 = (float)rA_shared[wtx].v + (float)rB_shared[j].v - DOT((float)rA_shared[wtx],(float)rB_shared[j]); 
					u2 = a2*r2;
					vij= exp(-u2);
					fs = 2*vij;

					d.x = (float)rA_shared[wtx].x  - (float)rB_shared[j].x;
					fxij=fs*d.x;
					d.y = (float)rA_shared[wtx].y  - (float)rB_shared[j].y;
					fyij=fs*d.y;
					d.z = (float)rA_shared[wtx].z  - (float)rB_shared[j].z;
					fzij=fs*d.z;

					fA[wtx].v +=  (double)((float)qB_shared[j]*vij);
					fA[wtx].x +=  (double)((float)qB_shared[j]*fxij);
					fA[wtx].y +=  (double)((float)qB_shared[j]*fyij);
					fA[wtx].z +=  (double)((float)qB_shared[j]*fzij);

				}

				// increment work thread index
				wtx = wtx + NUMBER_THREADS;

			}

			// reset work index
			wtx = tx;

			// synchronize after finishing force contributions from current nei box not to cause conflicts when starting next box
			__syncthreads();

		}

	}

}

OriLAVAKernel::OriLAVAKernel(int id) {
    this->Id = id;
    this->kernelName = "lava";
    initParams();
}

OriLAVAKernel::~OriLAVAKernel(){
    // free gpu memory
    for (auto &ptr : cudaFreeList) {
        CUDA_SAFE_CALL(cudaFree(ptr));
    }

    // free cpu heap memory
    free(this->LAVAKernelParams);
    
    // logger.INFO("id: " + std::to_string(Id) + " is destroyed!");
}

void OriLAVAKernel::initParams() {
    // counters
	int i, j, k, l, m, n;

	// system memory
	par_str par_cpu;
	dim_str dim_cpu;
	box_str* box_cpu;
	FOUR_VECTOR* rv_cpu;
	float* qv_cpu;
	FOUR_VECTOR* fv_cpu;
	int nh;

    // assing default values
	dim_cpu.boxes1d_arg = 60;

    par_cpu.alpha = 0.5;

	// total number of boxes
	dim_cpu.number_boxes = dim_cpu.boxes1d_arg * dim_cpu.boxes1d_arg * dim_cpu.boxes1d_arg;

	// how many particles space has in each direction
	dim_cpu.space_elem = dim_cpu.number_boxes * NUMBER_PAR_PER_BOX;
	dim_cpu.space_mem = dim_cpu.space_elem * sizeof(FOUR_VECTOR);
	dim_cpu.space_mem2 = dim_cpu.space_elem * sizeof(float);

	// box array
	dim_cpu.box_mem = dim_cpu.number_boxes * sizeof(box_str);

	// allocate boxes
	box_cpu = (box_str*)malloc(dim_cpu.box_mem);

	// initialize number of home boxes
	nh = 0;

	// home boxes in z direction
	for(i=0; i<dim_cpu.boxes1d_arg; i++){
		// home boxes in y direction
		for(j=0; j<dim_cpu.boxes1d_arg; j++){
			// home boxes in x direction
			for(k=0; k<dim_cpu.boxes1d_arg; k++){

				// current home box
				box_cpu[nh].x = k;
				box_cpu[nh].y = j;
				box_cpu[nh].z = i;
				box_cpu[nh].number = nh;
				box_cpu[nh].offset = nh * NUMBER_PAR_PER_BOX;

				// initialize number of neighbor boxes
				box_cpu[nh].nn = 0;

				// neighbor boxes in z direction
				for(l=-1; l<2; l++){
					// neighbor boxes in y direction
					for(m=-1; m<2; m++){
						// neighbor boxes in x direction
						for(n=-1; n<2; n++){

							// check if (this neighbor exists) and (it is not the same as home box)
							if(		(((i+l)>=0 && (j+m)>=0 && (k+n)>=0)==true && ((i+l)<dim_cpu.boxes1d_arg && (j+m)<dim_cpu.boxes1d_arg && (k+n)<dim_cpu.boxes1d_arg)==true)	&&
									(l==0 && m==0 && n==0)==false	){

								// current neighbor box
								box_cpu[nh].nei[box_cpu[nh].nn].x = (k+n);
								box_cpu[nh].nei[box_cpu[nh].nn].y = (j+m);
								box_cpu[nh].nei[box_cpu[nh].nn].z = (i+l);
								box_cpu[nh].nei[box_cpu[nh].nn].number =	(box_cpu[nh].nei[box_cpu[nh].nn].z * dim_cpu.boxes1d_arg * dim_cpu.boxes1d_arg) + 
																			(box_cpu[nh].nei[box_cpu[nh].nn].y * dim_cpu.boxes1d_arg) + 
																			 box_cpu[nh].nei[box_cpu[nh].nn].x;
								box_cpu[nh].nei[box_cpu[nh].nn].offset = box_cpu[nh].nei[box_cpu[nh].nn].number * NUMBER_PAR_PER_BOX;

								// increment neighbor box
								box_cpu[nh].nn = box_cpu[nh].nn + 1;

							}

						} // neighbor boxes in x direction
					} // neighbor boxes in y direction
				} // neighbor boxes in z direction

				// increment home box
				nh = nh + 1;

			} // home boxes in x direction
		} // home boxes in y direction
	} // home boxes in z direction

	// random generator seed set to random value - time in this case
	srand(time(NULL));

	// input (distances)
	rv_cpu = (FOUR_VECTOR*)malloc(dim_cpu.space_mem);
	for(i=0; i<dim_cpu.space_elem; i=i+1){
		rv_cpu[i].v = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
		rv_cpu[i].x = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
		rv_cpu[i].y = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
		rv_cpu[i].z = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
	}

	// input (charge)
	qv_cpu = (float*)malloc(dim_cpu.space_mem2);
	for(i=0; i<dim_cpu.space_elem; i=i+1){
		qv_cpu[i] = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
	}

	// output (forces)
	fv_cpu = (FOUR_VECTOR*)malloc(dim_cpu.space_mem);
	for(i=0; i<dim_cpu.space_elem; i=i+1){
		fv_cpu[i].v = 0;								// set to 0, because kernels keeps adding to initial value
		fv_cpu[i].x = 0;								// set to 0, because kernels keeps adding to initial value
		fv_cpu[i].y = 0;								// set to 0, because kernels keeps adding to initial value
		fv_cpu[i].z = 0;								// set to 0, because kernels keeps adding to initial value
	}

    box_str* d_box_gpu;
	FOUR_VECTOR* d_rv_gpu;
	float* d_qv_gpu;
	FOUR_VECTOR* d_fv_gpu;

	dim3 threads;
	dim3 blocks;

	blocks.x = dim_cpu.number_boxes;
	blocks.y = 1;
	threads.x = NUMBER_THREADS;											// define the number of threads in the block
	threads.y = 1;

	// printf("[ORI] block.x %d thread.x %d\n", blocks.x, threads.x);

	cudaMalloc(	(void **)&d_box_gpu, 
				dim_cpu.box_mem);
	cudaMalloc(	(void **)&d_rv_gpu, 
				dim_cpu.space_mem);
	cudaMalloc(	(void **)&d_qv_gpu, 
				dim_cpu.space_mem2);
	cudaMalloc(	(void **)&d_fv_gpu, 
				dim_cpu.space_mem);
	cudaMemcpy(	d_box_gpu, 
				box_cpu,
				dim_cpu.box_mem, 
				cudaMemcpyHostToDevice);
	cudaMemcpy(	d_rv_gpu,
				rv_cpu,
				dim_cpu.space_mem,
				cudaMemcpyHostToDevice);
	cudaMemcpy(	d_qv_gpu,
				qv_cpu,
				dim_cpu.space_mem2,
				cudaMemcpyHostToDevice);
	cudaMemcpy(	d_fv_gpu, 
				fv_cpu, 
				dim_cpu.space_mem, 
				cudaMemcpyHostToDevice);

    this->launchGridDim = blocks;
    this->launchBlockDim = threads;

    LAVAKernelParams = new OriLAVAParamsStruct();
    LAVAKernelParams->d_par_gpu = par_cpu;
    LAVAKernelParams->d_dim_gpu = dim_cpu;
    LAVAKernelParams->d_box_gpu = d_box_gpu;
    LAVAKernelParams->d_rv_gpu = d_rv_gpu;
    LAVAKernelParams->d_qv_gpu = d_qv_gpu;
    LAVAKernelParams->d_fv_gpu = d_fv_gpu;

    this->kernelParams.push_back(&(LAVAKernelParams->d_par_gpu));
    this->kernelParams.push_back(&(LAVAKernelParams->d_dim_gpu));
    this->kernelParams.push_back(&(LAVAKernelParams->d_box_gpu));
    this->kernelParams.push_back(&(LAVAKernelParams->d_rv_gpu));
    this->kernelParams.push_back(&(LAVAKernelParams->d_qv_gpu));
    this->kernelParams.push_back(&(LAVAKernelParams->d_fv_gpu));

    this->smem = 0;
    this->kernelFunc = (void*)ori_lava;

}

void OriLAVAKernel::executeImpl(cudaStream_t stream) {
    // logger.INFO("kernel name: " + kernelName + ", id: " + std::to_string(Id) + " is executing ...");
    // print dim
    // logger.INFO("-- launchGridDim: " + std::to_string(this->launchGridDim.x) + ", " + std::to_string(this->launchGridDim.y) + ", " + std::to_string(this->launchGridDim.z));
    // logger.INFO("-- launchBlockDim: " + std::to_string(this->launchBlockDim.x) + ", " + std::to_string(this->launchBlockDim.y) + ", " + std::to_string(this->launchBlockDim.z));
    
    CUDA_SAFE_CALL(cudaLaunchKernel(this->kernelFunc, 
        launchGridDim, launchBlockDim,
        (void**)this->kernelParams.data(), this->smem, 0));

    // CUDA_SAFE_CALL(cudaDeviceSynchronize());
}