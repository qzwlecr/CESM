//#include <math.h>
#include <mathimf.h>
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
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

#define USE_EXP10

void inline qmmr_hPa_cpp_(double t, double p, double *es_out, double *qm){
    p=p*100;
#ifdef USE_EXP10
    double tmp=(-7.90298*(tboil/t-1.0)+ \
      5.02808*log10(tboil/t)- \
      0.00000013816*(exp10(11.344*(1.0-t/tboil))-1.0)+\
      0.0081328*(exp10(-3.49149*(tboil/t-1.0))-1.0)+\
      log10(1013.246));
  // printf("the tmp is %f",tmp);
    double es=exp10(tmp)*100.0;;//exp10(tmp)*100.0;
#else

 #define X log2(10)    //看来这个exp2还真的快不少23333,但是wls算错了？？
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

//  int main(){
//      double es,qm;
//      for(double i=0;i<1.0;i++){
//          qmmr_hPa_cpp_(300.0,10.0,&es,&qm);
//      }
//      return 0; 
//  }
extern "C" //牛顿迭代法解方程？
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

