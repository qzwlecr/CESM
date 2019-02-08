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

#include "fft99_cuda.h"
#include <cuda.h>
#include <assert.h>
#include <cuda_runtime_api.h>
#include <chrono>
using namespace std::chrono;

#define LOG(arg) printf("%s=%d, ", #arg, (arg))

using real_t = cufftDoubleReal;
using complex_t = cufftDoubleComplex;
extern "C" void cuda_fft991_batch_host_(       //
    int* batch_size_, int* batch_distance_,    //
    double* a_,                                // inout, elements[lot][N+2]
    int* inc_,                                 // data memory addr increment of elements
    int* jump_,                                // data memory addr increment of vector

    int* n_,                                   // count of elements in a vector
    int* lot_,                                 // count of vectors
    int* ISIGN_                                // -1 => time2freq, +1 => freq2time
) {
    // to be discard
    auto batch_size = *batch_size_;
    auto batch_distance = *batch_distance_;
    double* dev_a;
    int data_byte = batch_distance * batch_size * sizeof(double);
    cudaMalloc(&dev_a, data_byte);
    cudaMemcpy(dev_a, a_, data_byte, cudaMemcpyHostToDevice);
    if(batch_distance == *jump_ * *lot_) {
        int fake_lot = *lot_ * batch_size;
        cuda_fft991_(dev_a, inc_, jump_, n_, &fake_lot, ISIGN_);
    } else {
        assert(false);
    }
    cudaMemcpy(a_, dev_a, data_byte, cudaMemcpyDeviceToHost);
    cudaFree(dev_a);
}

extern "C" void cuda_fft991_(    //
    double* a_,                  // inout, elements[lot][N+2]
    int* inc_,                   // data memory addr increment of elements
    int* jump_,                  // data memory addr increment of vector
    int* n_,                     // count of elements in a vector
    int* lot_,                   // count of vectors
    int* ISIGN_                  // -1 => time2freq, +1 => freq2time

) {
    // assume
    // thread_local cufftHandle fwd_plan, bck_plan;
    // thread_local int total_count = 0;
    // thread_local bool init_flag = false;
    // thread_local int batch_count = 0;
    // if(!init_flag || batch_count != *lot_) {
    //     if(init_flag) {
    //         cufftDestroy(fwd_plan);
    //         cufftDestroy(bck_plan);
    //         init_flag = false;
    //     }
    //     int n = *n_;
    //     int stride = *inc_;
    //     int real_dist = *jump_;
    //     int complex_dist = real_dist / 2;
    //     int ranks[] = {n};
    //     batch_count = *lot_;
    //     int new_count = batch_count * real_dist;
    //     // assert(!total_count || new_count == total_count);
    //     total_count = new_count;
    //     printf("\n<<<<");
    //     LOG(n);
    //     LOG(stride);
    //     LOG(real_dist);
    //     LOG(batch_count);
    //     printf("\n");
    //     cufftPlanMany(&fwd_plan, 1, ranks, nullptr, stride, real_dist, nullptr, stride,
    //                   complex_dist, CUFFT_D2Z, batch_count);
    //     cufftPlanMany(&bck_plan, 1, ranks, nullptr, stride, complex_dist, nullptr, stride,
    //                   real_dist, CUFFT_Z2D, batch_count);
    //     init_flag = true;
    // }
    thread_local std::unordered_map<int, std::pair<cufftHandle, cufftHandle> > record;
    int batch_count = *lot_;
    assert(*jump_ == 146);
    int total_count = 146 * batch_count;
    if(record.count(batch_count) == 0){
        auto& fwd_plan = record[batch_count].first;
        auto& bck_plan = record[batch_count].second;
        int n = *n_;
        int stride = *inc_;
        int real_dist = *jump_;
        int complex_dist = real_dist / 2;
        int ranks[] = {n};
        int new_count = batch_count * real_dist;
        // assert(!total_count || new_count == total_count);
        total_count = new_count;
        printf("\n<<<<");
        LOG(n);
        LOG(stride);
        LOG(real_dist);
        LOG(batch_count);
        printf("\n");
        cufftPlanMany(&fwd_plan, 1, ranks, nullptr, stride, real_dist, nullptr, stride,
                      complex_dist, CUFFT_D2Z, batch_count);
        cufftPlanMany(&bck_plan, 1, ranks, nullptr, stride, complex_dist, nullptr, stride,
                      real_dist, CUFFT_Z2D, batch_count);
    } 

    auto& fwd_plan = record[batch_count].first;
    auto& bck_plan = record[batch_count].second;
    if(*ISIGN_ == -1) {
        // fwd_plan
        auto status = cufftExecD2Z(fwd_plan, (real_t*)a_, (complex_t*)a_);
        // std::cout << "total_count=" << total_count << std::endl;
        // auto fn =;
        thrust::transform(thrust::system::cuda::par, a_, a_ + total_count, a_,
                          [=] __device__(double x) { return x / 144; });
        // printf("{executed=%d}", status);
    } else {
        cufftExecZ2D(bck_plan, (complex_t*)a_, (real_t*)a_);
    }
}

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
