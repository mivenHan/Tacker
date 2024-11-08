
#include "Logger.h"
#include "util.h"
#include "TackerConfig.h"
#include "Recorder.h"
#include "./dnn/vgg11/vgg11.h"
#include "./dnn/vgg11/vgg11_kernel_class.h"

extern Logger logger;
extern Recorder recorder;

void VGG11::initParams() {
    vgg11_cuda_init();
    
    //input argument
    float* Parameter_0_0_host, *Parameter_0_0;
    CUDA_SAFE_CALL(cudaMallocHost((void**)&Parameter_0_0_host, sizeof(float)* 9633792));
    CUDA_SAFE_CALL(cudaMalloc((void**)&Parameter_0_0, sizeof(float) * 9633792));
    for (int i = 0; i < 9633792; ++i) Parameter_0_0_host[i] = 1.0f;
    CUDA_SAFE_CALL(cudaMemcpy(Parameter_0_0, Parameter_0_0_host, sizeof(float) * 9633792, cudaMemcpyHostToDevice));
    this->Input[0] = Parameter_0_0;
    this->InputHost[0] = Parameter_0_0_host;
    this->InputSize[0] = 9633792;

    //output arguments
    float* Result_99_0_host, *Result_99_0;
    CUDA_SAFE_CALL(cudaMallocHost((void**)&Result_99_0_host, sizeof(float) * 64064));

    this->Result = (void**)&Result_99_0;

    //fill input values
    this->gen_vector(Parameter_0_0, (float**)Result);
}