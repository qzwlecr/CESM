#include <stdio.h>
#include <vector>
#include <fstream>
#include <iostream>
#include <string>
#include <unordered_map>
#include <cstring>
#include <assert.h>
#include <chrono>
#include "fftw3_mkl.h"
using namespace std::chrono;
#define DOG_BUGGY 0


extern "C" void needle_(                      //
    double* a_,                               // inout, elements[lot][N+2]
    int* batch_size_, int* batch_distance_    // distance
) {
    static int counter = 0;
    printf("[needle at %p, size=%d, dist=%d]\n", a_, *batch_size_, *batch_distance_);
    ++counter;
    auto current_time = system_clock::now();
    auto path = "./fft100";
    auto filename = path + std::to_string(system_clock::to_time_t(current_time)) + "-" +
                    std::to_string(counter) + ".dat";
    int data_byte = *batch_distance_ * (*batch_size_) * sizeof(double);
    std::ofstream fout(filename, std::ios::binary);
    fout.write((char*)a_, data_byte);
}

// blocks: y_dim
// threads: x_dim
constexpr int MAX_S_SIZE = 128 + 16;
struct PftRecord {
    // here is the wtf
    int s_size;
    int s_offset;
    int x_dim;
    double s_rev[MAX_S_SIZE];
    int fft_count;
    int encode_ids[MAX_S_SIZE];
    int decode_ids[MAX_S_SIZE];
    fftw_plan fwd_plan, bck_plan;
    double* dev_damp;                // of fft_count * (x_dim + 2), keep it in memory
    double* dev_origin;     // of fft_count * (x_dim), keep it in memory
    fftw_complex* dev_freq; //complex   // of fft_count * (x_dim + 2), keep it in memory
    //double* dev_inout;               // of s_size * x_dim
};

thread_local PftRecord pft_records[4] = {};
static PftRecord dev_pft_records[4];

extern "C" void cuda_pft_cf_record_(int* plan_id_, double* s_, int* s_beg_, int* s_end_,
                                    double* damp_, int* im_, int* fft_flt_) {
    // initalize this region for further call
    int plan_id = *plan_id_;
    assert(plan_id >= 0 && plan_id < 4);
    int s_size = *s_end_ - *s_beg_ + 1;
    assert(s_size < MAX_S_SIZE);
    int x_dim = *im_;
    auto& record = pft_records[plan_id];
    auto* encode_ids = record.encode_ids;
    auto* decode_ids = record.decode_ids;

    int fft_count = 0;
    bool force_fft = (bool)*fft_flt_;
    //std::cout<<plan_id<<" "<<s_size<<" "<<*damp_<<" "<<x_dim<<" "<<force_fft;
    //          0             94            1           144         1
    //exit(1);
    int s_beg = 0;
    int s_end = 0;
    for(int i = 0; i < s_size; ++i) {
        auto coef = s_[i];
        record.s_rev[i] = 1.0 / coef;
        if(coef <= 1.01) {
            // skip
            if(s_beg == i) {
                assert(s_beg == s_end);
                s_beg += 1;
                s_end += 1;
            } else {
                encode_ids[i - s_beg] = -2;
            }
        } else if(!force_fft && coef <= 4.0) {
            // shortcut
            assert(false);
            encode_ids[i - s_beg] = -1;
            s_end = i + 1;
        } else {
            // real fft
            int id = fft_count;
            ++fft_count;
            encode_ids[i - s_beg] = id;
            decode_ids[id] = i - s_beg;
            s_end = i + 1;
        }
    }

    s_size = s_end - s_beg;
    record.s_size = s_size;
    int s_offset = s_beg * x_dim;
    record.s_offset = s_offset;
    s_ += s_offset;
    damp_ += s_offset; 

    if(record.x_dim == x_dim && record.fft_count == fft_count) {
        // well done
        // do nothing
    } else {
        if(record.dev_damp || record.dev_origin || record.dev_freq) {
            assert(false);
            free(record.dev_damp);
            free(record.dev_origin);
            free(record.dev_freq);
            //free(record.dev_inout);
            //cufftDestroy(record.fwd_plan);
            //cufftDestroy(record.bck_plan);
        }
        record.x_dim = x_dim;
        record.fft_count = fft_count;
        record.dev_damp = (double*)malloc(fft_count * (x_dim + 2)*sizeof(double));
        record.dev_origin = (double*) malloc(fft_count * x_dim*sizeof(double));
        record.dev_freq = (fftw_complex*) malloc(fft_count * (x_dim + 2)*sizeof(double) );
        //record.dev_inout = (double*) malloc(s_size * x_dim*sizeof(double));
//         fftw_plan fftw_plan_many_dft_r2c(int rank, const int *n, int howmany,
//                                double *in, const int *inembed,
//                                int istride, int idist,
//                                fftw_complex *out, const int *onembed,
//                                int ostride, int odist,
//                                unsigned flags);
// fftw_plan fftw_plan_many_dft_c2r(int rank, const int *n, int howmany,
//                                 fftw_complex *in, const int *inembed,
//                                 int istride, int idist,
//                                 double *out, const int *onembed,
//                                 int ostride, int odist,
//                                 unsigned flags);
//1.fwd r2c (-1) 2.bck c2r (+1)
        const int N=x_dim;
        const int foo=N/2+1;
        int jump=N;
        std::cout<<jump<<"\n ";
        int lot=fft_count;
        int inc=1;
        record.fwd_plan=fftw_plan_many_dft_r2c(1,&N,lot,
                           record.dev_origin    ,&N,
                              inc,jump,
                           record.dev_freq,&foo,
                           1,N/2+1,
                           FFTW_ESTIMATE);
        record.bck_plan=fftw_plan_many_dft_c2r(1,&N,lot,record.dev_freq,&foo,1, \
                             foo,record.dev_origin,  & N,   inc,jump, FFTW_ESTIMATE);              
         //cufftPlan1d(&record.fwd_plan, x_dim, CUFFT_D2Z, fft_count);
        //  cufftPlan1d(&record.bck_plan, x_dim, CUFFT_Z2D, fft_count);
    }
    // double placeholder[4] = {1.0, 1.0, 1.0, 1.0};
    for(int id = 0; id < fft_count; id++) {
        std::vector<double> buffer(x_dim + 2);
        int i = decode_ids[id];
        buffer[0] = buffer[1] = buffer[2] = buffer[3] = 1.0 / x_dim;
        double* host_damp_ptr = damp_ + i * x_dim;
        for(int i = 4; i < x_dim + 2; ++i) {
            buffer[i] = host_damp_ptr[i - 2] / x_dim;
        }
        double* dev_damp_ptr = record.dev_damp + id * (x_dim + 2);
        // set damp
        //std::cout<<"the x_dim"<<x_dim<<"\n";
         memcpy(dev_damp_ptr, buffer.data(), sizeof(double) * (x_dim + 2));
    }
    //  memcpyToSymbol(dev_pft_records, pft_records, 4 * sizeof(PftRecord));
     dev_pft_records[0]=pft_records[0];
     dev_pft_records[1]=pft_records[1];
     dev_pft_records[2]=pft_records[2];
     dev_pft_records[3]=pft_records[3];

}

 void pft_prepare(double*  p_inout, int plan_id,int s_size,int x_dim_Id) {
    for(int s_index=0; s_index<s_size;  s_index++){
        auto& record = pft_records[plan_id];
        int x_dim = record.x_dim;
        int id = record.encode_ids[s_index];
        double* raw_p = p_inout + s_index * x_dim;
        
        for(int x_id=0;x_id<x_dim_Id; x_id++){
          if(id == -2 || x_id >= x_dim) {
              // do nothing
          } else if(id == -1) {
              // inplace filter
              double s_rev = record.s_rev[s_index];
              double mid = raw_p[x_id];
              double left = x_id - 1 >= 0 ? raw_p[x_id - 1] : raw_p[x_dim];
              double right = x_id + 1 < x_dim ? raw_p[x_id + 1] : raw_p[0];
              double result = mid * s_rev + (1 - s_rev) * 0.5 * (left + right);
              raw_p[x_id] = result;
          } else {
              // fft
              int fft_id = id;
              // fill into destination
              double* dest = record.dev_origin + fft_id * x_dim;
              dest[x_id] = raw_p[x_id];
          }
        }
    }
  
}

 void pft_finish(double*  p_inout, int plan_id,int fft_count,int x_dim_Id) {
     for(int fft_id=0; fft_id<fft_count ;fft_id++){
        auto& record = dev_pft_records[plan_id];
        int x_dim = record.x_dim;
        int s_index = record.decode_ids[fft_id];
        double* src = record.dev_origin + fft_id * x_dim;
        double* dest = p_inout + s_index * x_dim;
         for(int x_id=0;x_id<x_dim_Id;x_id++ ){
            if(x_id < x_dim) {
                dest[x_id] = src[x_id];
            }
         }
     }
}

void log_freq(PftRecord& record, double* arr_) {
    int stride = record.x_dim + 2;
    for(int i = 0; i < 3; ++i) {
        for(int j = 0; j < stride; ++j) {
            printf("%.6lf\t", arr_[j+i*stride]);
        }
        printf("freq\n");
    }
    fflush(stdout);
}
void log_origin(PftRecord& record, double* arr_) {
    int stride = record.x_dim;
    for(int i = 0; i < 5; ++i) {
        for(int j = 0; j < stride; ++j) {
            printf("%.6lf\t", arr_[j+i*stride]);
        }
        printf("origin\n");
    }
    fflush(stdout);
}
void log_raw(PftRecord& record, double* arr_) {
    for(int i = 0; i < 3; ++i) {
        int id = i;
        for(int j = 0; j < 12; ++j) {
            printf("%.6lf\t", arr_[j+i*12]);
        }
        printf("raw[%d]\n", id);
    }
    fflush(stdout);
}

extern "C" void fftw_pft2d_(double* p_inout_,    // array filtered [y_dim][x_dim]
                            int* plan_id_       //
) {
    //puts("\ncall fftw_pft2d_");
    int plan_id = *plan_id_;
    auto& record = pft_records[plan_id];
    int s_size = record.s_size;
    int x_dim = record.x_dim;
    int fft_count = record.fft_count;
    auto* dev_damp = record.dev_damp;
    auto* dev_origin = record.dev_origin;
    auto* dev_freq =  record.dev_freq;
    auto* dev_inout = p_inout_;//record.dev_inout;
    auto s_offset = record.s_offset;
    p_inout_ += s_offset;
    //memcpy(dev_inout, p_inout_, sizeof(double) * s_size * x_dim);
    //log_origin(record,dev_inout);
    pft_prepare(dev_inout, plan_id,s_size,x_dim);
    //log_origin(record,dev_origin);
    fftw_execute_dft_r2c(record.fwd_plan, dev_origin, dev_freq);

    //log_freq(record,(double*)dev_freq);
    
    //puts("\n");
    //log_raw(record,dev_damp);
    double * freq=(double*)dev_freq;
     for(int i=0;i<fft_count * (x_dim + 2) ;i++){
         //printf("%p ",dev_freq[i]);
         //printf("%.6lf\t with ", *dev_freq[i]);
         //printf("%.6lf\t %d " , dev_damp[i],i);
         freq[i]*=(dev_damp[i]);
         //printf("%.6lf\t\n", *dev_freq[i]);
     }
    //puts("\n");

      //  printf("%d\n",fft_count * (x_dim + 2));
    //log_freq(record,(double*)dev_freq);

    fftw_execute_dft_c2r(record.bck_plan, dev_freq, dev_origin);

    pft_finish  (dev_inout, plan_id,fft_count,x_dim);
    //memcpy(p_inout_, dev_inout, sizeof(double) * s_size * x_dim);
    //puts("\nend fftw_pft2d_");

}
