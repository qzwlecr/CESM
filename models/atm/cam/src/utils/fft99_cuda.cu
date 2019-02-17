//只是放在这里，还没有研究fft的输入输出
//如果需要单独把 init 函数和 destroy 函数抽出来，我再到调用的地方加
//https://github.com/qzwlecr/CESM/issues/12
#include <cufft.h>
#include <stdio.h>
#include <fstream>
#include <thrust/transform.h>
#include <thrust/functional.h>
#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>

#include <cuda.h>
#include <assert.h>
#include <cuda_runtime_api.h>
#include <chrono>
using namespace std::chrono;

extern "C" void needle_(                      //
    double* a_,                               // inout, elements[lot][N+2]
    int* batch_size_, int* batch_distance_    // distance
) {
    static int counter = 0;
    printf("[needle at %p, size=%d, dist=%d]", a_, *batch_size_, *batch_distance_);
    ++counter;
    auto current_time = system_clock::now();
    auto path = "/home/mike/tmp/";
    auto filename = path + std::to_string(system_clock::to_time_t(current_time)) + "-" +
                    std::to_string(counter) + ".dat";
    int data_byte = *batch_distance_ * *batch_size_ * sizeof(double);
    std::ofstream fout(filename, std::ios::binary);
    fout.write((char*)a_, data_byte);
}

template <typename T, bool is_managed = false>
T* cuda_alloc(int size) {
    int bytes = sizeof(T) * size;
    T* tmp;
    if(is_managed) {
        cudaMallocManaged(&tmp, bytes);
    } else {
        cudaMalloc(&tmp, bytes);
    }
    return tmp;
}

// blocks: y_dim
// threads: x_dim
// s_ should be constant array

// need adjustment
constexpr int MAX_S_SIZE = 128 + 16;
struct PftRecord {
    // here is the wtf
    int s_size;
    int x_dim;
    double s_rev[MAX_S_SIZE];
    int fft_count;
    int encode_ids[MAX_S_SIZE];
    int decode_ids[MAX_S_SIZE];
    int fwd_plan, bck_plan;
    double* dev_damp;                // of fft_count * (x_dim + 2), keep it in memory
    cufftDoubleReal* dev_origin;     // of fft_count * (x_dim), keep it in memory
    cufftDoubleComplex* dev_freq;    // of fft_count * (x_dim + 2), keep it in memory
    double* dev_inout;               // of s_size * x_dim
};

static PftRecord pft_records[4] = {};
static __constant__ PftRecord dev_pft_records[4];

extern "C"    //
    void
    cuda_pft_cf_record_(int* plan_id_, double* s_, int* s_beg_, int* s_end_,
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
    printf("{plan_id=%d}", plan_id);
    for(int i = 0; i < s_size; ++i) {
        auto coef = s_[i];
        printf("<%ld>", coef);
        record.s_rev[i] = 1.0 / coef;
        if(coef <= 1.01) {
            // skip
            encode_ids[i] = -2;
        } else if(!force_fft && coef <= 4.0) {
            // shortcut
            encode_ids[i] = -1;
        } else {
            // real fft
            int id = fft_count;
            ++fft_count;
            encode_ids[i] = id;
            decode_ids[id] = i;
        }
    }
    printf("\n");
    record.s_size = s_size;
    if(record.x_dim == x_dim && record.fft_count == fft_count) {
        // well done
        // do nothing
    } else {
        if(record.dev_damp || record.dev_origin || record.dev_freq) {
            assert(false);
            cudaFree(record.dev_damp);
            cudaFree(record.dev_origin);
            cudaFree(record.dev_freq);
            cudaFree(record.dev_inout);
            cufftDestroy(record.fwd_plan);
            cufftDestroy(record.bck_plan);
        }
        record.x_dim = x_dim;
        record.fft_count = fft_count;
        record.dev_damp = cuda_alloc<double>(fft_count * (x_dim + 2));
        record.dev_origin = cuda_alloc<double>(fft_count * x_dim);
        record.dev_freq = cuda_alloc<cufftDoubleComplex>(fft_count * (x_dim + 2) / 2);
        record.dev_inout = cuda_alloc<double>(s_size * x_dim);

        cufftPlan1d(&record.fwd_plan, x_dim, CUFFT_R2C, fft_count);
        cufftPlan1d(&record.bck_plan, x_dim, CUFFT_C2R, fft_count);
    }
    double placeholder[4] = {1.0, 1.0, 1.0, 1.0};
    for(int id = 0; id < fft_count; id++) {
        int i = decode_ids[id];
        double* dev_damp_ptr = record.dev_damp + id * (x_dim + 2);
        double* host_damp_ptr = damp_ + i * x_dim;
        // set damp
        cudaMemcpy(dev_damp_ptr, placeholder, sizeof(placeholder),
                   cudaMemcpyHostToDevice);
        cudaMemcpy(dev_damp_ptr + 4, host_damp_ptr + 2, sizeof(double) * (x_dim - 2),
                   cudaMemcpyHostToDevice);
    }
    cudaMemcpyToSymbol(dev_pft_records, pft_records + plan_id, sizeof(PftRecord),
                       sizeof(PftRecord) * plan_id);
}

__global__ void pft_prepare(double* __restrict__ p_inout, int plan_id) {
    int s_index = blockIdx.x;
    int x_id = threadIdx.x;
    auto& record = dev_pft_records[plan_id];
    int x_dim = record.x_dim;
    int id = record.encode_ids[s_index];
    double* raw_p = p_inout + s_index * x_dim;
    if(id == -2 || x_id >= x_dim) {
        // do nothing
    } else if(-1) {
        // inplace filter
        double s_rev = record.s_rev[s_index];
        double mid = raw_p[x_id];
        double left = x_id - 1 >= 0 ? raw_p[x_id - 1] : raw_p[x_dim];
        double right = x_id + 1 < x_dim ? raw_p[x_id + 1] : raw_p[0];
        double result = mid * s_rev + (1 - s_rev) * 0.5 * (left + right);
        __syncthreads();
        raw_p[x_id] = result;
    } else {
        // fft
        int fft_id = id;
        // fill into destination
        double* dest = record.dev_origin + fft_id * x_dim;
        dest[x_id] = raw_p[x_id];
    }
}

__global__ void pft_finish(double* __restrict__ p_inout, int plan_id) {
    int fft_id = blockIdx.x;
    auto& record = dev_pft_records[plan_id];
    int x_dim = record.x_dim;
    int s_index = record.decode_ids[fft_id];
    double* src = record.dev_origin + fft_id * x_dim;
    double* dest = p_inout + s_index * x_dim;

    int x_id = threadIdx.x;
    if(x_id < x_dim) {
        dest[x_id] = src[x_id];
    }
}

extern "C" void cuda_pft2d_(double* p_inout_,    // array filtered [y_dim][x_dim]
                            int* plan_id_, //
                            // raw datas
                            double* xxx_s, double* xxx_d, //
                            int* xxx_im, int* xxx_jp//
                            ) {
    int plan_id = *plan_id_;
    auto& record = pft_records[plan_id];
    int s_size = record.s_size;
    int x_dim = record.x_dim;
    int fft_count = record.fft_count;
    auto* dev_damp = record.dev_damp;
    auto* dev_origin = record.dev_origin;
    auto* dev_freq = record.dev_freq;
    auto* dev_inout = record.dev_inout;
    assert(*xxx_im == x_dim);
    assert(*xxx_jp == s_size);
    double wtf = xxx_s[14] - 1.0 / record.s_rev[14];
    assert((float)(wtf) == (float)0.0);
    // what about d?  
    cudaMemcpy(dev_inout, p_inout_, sizeof(double) * s_size * x_dim,
               cudaMemcpyHostToDevice);
    // may change to benifit the hardware
    pft_prepare<<<s_size, x_dim>>>(dev_inout, plan_id);
    cufftExecD2Z(record.fwd_plan, dev_origin, dev_freq);
    thrust::transform(thrust::system::cuda::par,
                      (double*)dev_freq,                              //
                      (double*)dev_freq + fft_count * (x_dim + 2),    //
                      dev_damp,                                       //
                      (double*)dev_freq,                              //
                      [] __device__(double a, double b) { return a * b / 144.0; });
    cufftExecZ2D(record.bck_plan, dev_freq, dev_origin);
    pft_finish<<<s_size, x_dim>>>(dev_inout, plan_id);
    cudaMemcpy(p_inout_, dev_inout, sizeof(double) * s_size * x_dim,
               cudaMemcpyDeviceToHost);
}
