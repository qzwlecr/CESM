//只是放在这里，还没有研究fft的输入输出
//如果需要单独把 init 函数和 destroy 函数抽出来，我再到调用的地方加
//https://github.com/qzwlecr/CESM/issues/12
extern "C" 
void fft99_cuda(double *a, double *work, double *trigs,int* IFAX, int* inc, int* jump,
    int* n, int* lot,int* ISIGN){

    };

extern "C" 
void fft991_cuda(double *a, double *work, double *trigs,int* IFAX, int* inc, int* jump,
        int* n, int* lot,int* ISIGN){
            
        };