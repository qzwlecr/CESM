//#include <math.h>
#include <mathimf.h>
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/shm.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/file.h>

#define MAX(a,b) ((a) > (b) ? a : b)
#define MIN(a,b) ((a) < (b) ? a : b)

#define tboil 373.16
//models/atm/cam/src/control/physconst.F90
//models/csm_share/shr/shr_const_mod.F90 
#define cpwv 1810.0
#define cpliq 4188.0//SHR_CONST_CPFW
//tfreez = tmelt = shr_const_tkfrz
#define tfreez 273.15
//rl=latvap=shr_const_latvap = 2.501e6_R8   
#define rl 2501000.0
//shr_const_rwv = SHR_CONST_RGAS/SHR_CONST_MWWV   
//= SHR_CONST_AVOGAD*SHR_CONST_BOLTZ/18.016
//=6.02214e26_R8* 1.38065e-23_R8 / 18.016
#define rh2o (6022.14*1.38065/18.016)
//rgas   = rair=shr_const_rdair = SHR_CONST_RGAS/SHR_CONST_MWDAIR 
//= SHR_CONST_AVOGAD*SHR_CONST_BOLTZ/28.966
//=6.02214e26_R8* 1.38065e-23_R8 / 28.966
#define rgas (6022.14*1.38065/28.966)
//   eps1   = epsilo  = shr_const_mwwv/shr_const_mwdair
#define eps1 (18.016/28.966)
//cpres  = cpair =shr_const_cpdair= 1.00464e3_R8  
#define cpres 1004.64
#define pref 1000.0
#define omeps     (1-eps1)

#define USE_EXP10


#define PRECICE  1000000
#define TABLE_SIZE PRECICE*(350-160+1) // the fortran start from 1

#define GffgchCompile(i) exp10(-7.90298*(tboil/(double)(i)-1.0)+ \
      5.02808*log10(tboil/(double)(i))- \
      0.00000013816*(exp10(11.344*(1.0-(double)(i)/tboil))-1.0)+\
      0.0081328*(exp10(-3.49149*(tboil/(double)(i)-1.0))-1.0)+\
      log10(1013.246))*100.0

#define GffgchIndex(i)  GffgchCompile(((i)/PRECICE-160))

//static double test=GffgchIndex(10);

//1000          1.4MB
//10000         14MB 
        
static double* gffgchTable;
static bool volatile ifGffgchInit=false;

void error() {
  printf("%d:%s",errno,strerror(errno));
  exit(-1);
}
//https://stackoverflow.com/questions/6182877/file-locks-for-linux
int acquireLock (char *fileSpec) {
    int lockFd;
    if ((lockFd = open (fileSpec, O_CREAT | O_RDWR, 0666))  < 0)
        return -1;

    if (flock (lockFd, LOCK_EX | LOCK_NB) < 0) {
        close (lockFd);
        return -1;
    }

    return lockFd;
}

void releaseLock (int lockFd) {
    flock (lockFd, LOCK_UN);
    close (lockFd);
}
void readData(char* fileName) {

  // Generate a key for memory sharing
  key_t key = ftok("/tmp",'r');
  if(key<1) perror("ftok");
  // Get the size of data file
  struct stat data_stat;
  stat(fileName,&data_stat);
  int size = data_stat.st_size;
  char* shmem_ptr;

  if (acquireLock("/tmp/CESM.lock") != -1) {
    // we got the lock !
    // Create a shared memory block.
    printf("[ASC debug] Y00: Master ...\n");

    int mem_id = shmget(key,size+1,IPC_CREAT | IPC_EXCL | 0666);
    if (mem_id<0) error();
      shmem_ptr = (char*)shmat(mem_id,NULL,0);
    if (shmem_ptr<0) error();
    // Open the data file
    printf("[ASC debug] Y00: Master mem init\n");

    FILE* data = fopen(fileName,"r");
    if (!data) error();
    // Read the data file into the shared memory block.
    int i = 0;
    char c;
    while (i<size) {
      shmem_ptr[i] = fgetc(data);
      i++;
    }
    shmem_ptr[i] = EOF;
    fclose(data);
    printf("[ASC debug] Y00: master finished reading, with size %d\n",size);
    //releaseLock (fd);

  } else {
  // Other processes have read the data.
    printf("[ASC debug] Y00: get the table with shm ...\n");
    sleep(100);//just wait for the master 
    // int fd;
    //  if ((fd = acquireLock ("/tmp/CESM.lock")) < 0) {
    //      fprintf (stderr, "[ASC debug] Y00: waiting for master to read the table.\n");
    //      sleep(10);
    //  }
    //  releaseLock (fd);

    int mem_id = shmget(key,size+1,IPC_CREAT);
    if (mem_id<0) error();
      shmem_ptr = (char*)shmat(mem_id,NULL,0);
    if (shmem_ptr<0) error();
    // Print the data.
    //int i = 0;
   //  while(shmem_ptr[i] != EOF) {
   //    printf("%c",shmem_ptr[i]);
   //    sleep(0.1);
   //    i++;
   //  }
  }
  gffgchTable=(double* )shmem_ptr;
}

void inline gffgch_core(double i){
       double tmp=(-7.90298*(tboil/i-1.0)+ \
      5.02808*log10(tboil/i)- \
      0.00000013816*(exp10(11.344*(1.0-i/tboil))-1.0)+\
      0.0081328*(exp10(-3.49149*(tboil/i-1.0))-1.0)+\
      log10(1013.246));
      unsigned long location=i*PRECICE;
      //printf("[ASC debug] Y00: gffgch_core %p\n",gffgchTable);
      gffgchTable[location]=exp10(tmp)*100.0;

}

extern "C" //init the ptr
void asc_gffgch_init_ptr_(double** Tabl_ptr){
       *Tabl_ptr=gffgchTable;
       printf("[ASC debug] Y00: Tabl_ptr %p \n",Tabl_ptr);
}
extern "C" //init the table (load it from disk / shared memory)
#define rgy_pc "/media/rgy/win-file/document/computer/HPC/cesm/data"
void asc_gffgch_init_table_(){
      readData(rgy_pc);

}




void inline qmmr_hPa_cpp_(double t, double p, double *es_out, double *qm){
    p=p*100;
    //t=t+1.0/50000 ;//POC
#ifdef USE_EXP10
    double tmp=(-7.90298*(tboil/t-1.0)+ \
      5.02808*log10(tboil/t)- \
      0.00000013816*(exp10(11.344*(1.0-t/tboil))-1.0)+\
      0.0081328*(exp10(-3.49149*(tboil/t-1.0))-1.0)+\
      log10(1013.246));
    double es=exp10(tmp)*100.0;;//exp10(tmp)*100.0;
   //printf("the es is %f\n",es);

#else

 #define X log2(10)    
    double tmp=(-7.90298*(tboil/t-1.0)*X + \
     5.02808*log2(tboil/t)  -\
     0.00000013816*(exp2(11.344*(1.0-t/tboil)*X)-1.0)*X + \
     0.0081328*(exp2(-3.49149*(tboil/t-1.0)*X)-1.0)*X+log2(1013.246));
     double es = exp2(tmp) * 100.0;
     //printf("the tmp is %f\n",tmp);
     //printf("the X is %lf\n",X);
#endif

  if ( (p - es) < DBL_MIN )
     *qm = DBL_MAX;
  else
     *qm = eps1*es / (p - es);

  //! Ensures returned es is consistent with limiters on qmmr.
  es = MIN(es, p);
  
  *es_out = es*0.01;
}

//   int main(){
//       double* es;
//           asc_gffgch_init_table_();
//           asc_gffgch_init_ptr_(&es);
//       return 0; 
//   }
extern "C" //牛顿迭代法解方程？
//现在已经不使用这段代码了，还是丢到fortran里
void ientropy_cpp_ (double* s_in,double* p_in,double* qt_in,double* T_out,double* qst_out,double* Tfg)
{
    double Ts=*Tfg;
    double s=*s_in;
    double p=*p_in;
    double qt=*qt_in;
    double qst,dTs;

    double L,fs1,fs2,est,qv,e;
    int i;

    for(i=0;i<100;i++){
        L = rl - (cpliq - cpwv)*(Ts-tfreez);
        qmmr_hPa_cpp_(Ts, p, &est, &qst);
        qv = MIN(qt,qst);
        e = qv*p / (eps1 +qv); // ! Bolton (eq. 16)
        fs1 = (cpres + qt*cpliq)*log( Ts/tfreez ) - rgas*log( (p-e)/pref ) + \
             L*qv/Ts - qv*rh2o*log(qv/qst) - s;
        
        L = rl - (cpliq - cpwv)*(Ts-1.0-tfreez);
     
        qmmr_hPa_cpp_(Ts-1, p, &est, &qst);
        qv = MIN(qt,qst);
        e = qv*p / (eps1 +qv);
        fs2 = (cpres + qt*cpliq)*log( (Ts-1)/tfreez ) - rgas*log( (p-e)/pref ) + \
             L*qv/(Ts-1) - qv*rh2o*log(qv/qst) - s;
        
        dTs = fs1/(fs2 - fs1);
        Ts  = Ts+dTs;
        if (abs(dTs)<0.001) 
           goto ientropy_cpp_done ;
    }
    *T_out = 0.0;
    puts("ientropy_cuda_ failed");
    exit(-1);
    ientropy_cpp_done: // this is solved!
    qmmr_hPa_cpp_(Ts, p, &est, &qst);
    qv = MIN(qt,qst);//                             !       /* check for saturation */
    *T_out = Ts;
    *qst_out=qst;
}

// __device__ 
// inline void qmmr_hPa_cuda_(double t, double p, double *es_out, double *qm){
//    p=p*100;
//    double tmp=(-7.90298*(tboil/t-1.0)+ \
//      5.02808*log10(tboil/t)- \
//      0.00000013816*(exp10(11.344*(1.0-t/tboil))-1.0)+\
//      0.0081328*(exp10(-3.49149*(tboil/t-1.0))-1.0)+\
//      log10(1013.246));

//    double es=exp10(tmp)*100;//exp10(tmp)*100.0;

//  if ( (p - es) < DBL_MIN )
//     *qm = DBL_MAX;
//  else
//     *qm = eps1*es / (p - es);

//  //! Ensures returned es is consistent with limiters on qmmr.
//  es = MIN(es, p);
 
//  *es_out = es*0.01;
// }

// __global__
// void ientropy_core(double* Ts_out,double* qst_out,double s, double p,double qt){
//    double qst,dTs;
//    double L,fs1,fs2,est,qv,e;
//    double Ts=*Ts_out;
//    int i;
//    for(i=0;i<100;i++){
//        L = rl - (cpliq - cpwv)*(Ts-tfreez);
//        qmmr_hPa_cuda_(Ts, p, &est, &qst);
//        qv = MIN(qt,qst);
//        e = qv*p / (eps1 +qv); // ! Bolton (eq. 16)
//        fs1 = (cpres + qt*cpliq)*log( Ts/tfreez ) - rgas*log( (p-e)/pref ) + \
//             L*qv/Ts - qv*rh2o*log(qv/qst) - s;
       
//        L = rl - (cpliq - cpwv)*(Ts-1.0-tfreez);
    
//        qmmr_hPa_cuda_(Ts-1, p, &est, &qst);
//        qv = MIN(qt,qst);
//        e = qv*p / (eps1 +qv);
//        fs2 = (cpres + qt*cpliq)*log( (Ts-1)/tfreez ) - rgas*log( (p-e)/pref ) + \
//             L*qv/(Ts-1) - qv*rh2o*log(qv/qst) - s;
       
//        dTs = fs1/(fs2 - fs1);
//        Ts  = Ts+dTs;
//        if (abs(dTs)<0.001) 
//           goto ientropy_cuda_done ;
//    }
//    *Ts_out = -1.0;
//    return; 
//    ientropy_cuda_done: // this is solved!
//    qmmr_hPa_cuda_(Ts, p, &est, &qst);
//    //qv = MIN(qt,qst);//                             !       /* check for saturation */
//    *Ts_out = Ts;
//    *qst_out=qst;
// }

// extern "C" 
// void ientropy_cuda_ (double* s_in,double* p_in,double* qt_in,double* T_out,double* qst_out,double* Tfg)
// {
//    double* Ts;
//    double* qst;

//    puts("ientropy_cuda_ start");
//    cudaMallocManaged(&Ts, sizeof(double));
//    cudaMallocManaged(&qst, sizeof(double));
//    *Ts=*Tfg;
//    double s=*s_in;
//    double p=*p_in;
//    double qt=*qt_in;
//    ientropy_core<<<1, 1>>>(Ts,qst,s,p,qt);
//    cudaDeviceSynchronize();
//    *T_out = *Ts;
//    if(*T_out==-1.0){
//    puts("ientropy_cuda_ failed");
//    exit(-1);
//    }
//    *qst_out=*qst;
//    cudaFree(Ts);
//    cudaFree(qst);
//    puts("ientropy_cuda_ done");

// }

