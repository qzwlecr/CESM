//直接把那个循环里的openmp移除？ 这样方便cuda计算？？

__global__
void cudaCal(double* pk,double pe,double akap){
   *pk=pow(pe,akap);
}
//akap 每轮计算一直是一个固定的，考虑stream一下？

extern "C" //方便gcc/g++ fortran链接
void calpk_(double* pk,double* pe,double* akap){
   cudaCal<<<1,1>>>(pk,*pe,*akap);
   cudaDeviceSynchronize();
}

//必须小写！！！
void calpkCuda_(double*pk,double*pe,double*akap,int* km, int* i1, int* i2,int* j){
   for(int z=*i1;z < *i2;z++){
      for(int x=0;x<*km+1;x++){
         for(int y=0;y<*j;y++){//TODO 这个循环范围还有问题，然后fortran和c的矩阵还不一样, 我还是一个个做吧，，，
         cudaCal<<<1,1>>>(pk,*pe,*akap);
         }
      }
   }
}