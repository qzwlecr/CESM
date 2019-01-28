//注意r8是double精度 我的数学公式转换没错吧？ 帮我检查一下？
//所有的.cu都要用*_cuda.cu 结尾，因为我的编译脚本就是这么判断的
//0.00000013816，和 8.1328e-3_r8 小数点直接这样转换，应该没问题吧，，
#include <math.h>   
extern "C" 

//因为用了interface，注明了是c ，所以这里不用在函数名后面加上 '_'
void svp_water_cuda(double* ptboil,double* pt,double* es){
   //Y00: use cuda to do this  
   double tboil=*ptboil;
   double t=*pt;
     double tmp=(-7.90298*(tboil/t-1.0)+ \
       5.02808*log10(tboil/t)- \
       0.00000013816*(exp10(11.344*(1.0-t/tboil))-1.0)+ \
       0.0081328*(exp10(-3.49149*(tboil/t-1.0))-1.0)+ \
       log10(1013.246));
  *es= exp10(tmp)*100.0;

}