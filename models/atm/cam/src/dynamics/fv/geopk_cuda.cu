//直接把那个循环里的openmp移除？ 这样方便cuda计算？？

__global__
void cudaCal(double* pk,double pe,double akap){
   *pk=pow(pe,akap);
}
//akap 每轮计算一直是一个固定的，考虑stream一下？

extern "C" 
void calpk_(double* pk,double* pe,double* akap){
   cudaCal<<<1,1>>>(pk,*pe,*akap);
   cudaDeviceSynchronize();
}

extern "C" 
void calpkCuda_(double*pk,double*pe,double*akap,int* km, int* i1, int* i2,int* jfirst,int* jp){

}
