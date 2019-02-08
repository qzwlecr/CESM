extern "C" void cuda_fft991_batch_host_(       //
    int* batch_size_, int* batch_distance_,    //
    double* a_,                                // inout, elements[lot][N+2]
    int* inc_,                                 // data memory addr increment of elements
    int* jump_,                                // data memory addr increment of vector
    int* n_,                                   // count of elements in a vector
    int* lot_,                                 // count of vectors
    int* ISIGN_                                // -1 => time2freq, +1 => freq2time
);

extern "C" void cuda_fft991_(double* a,    // inout, elements[lot][N+2]
                        int* inc,     // data memory addr increment of elements
                        int* jump,    // data memory addr increment of vector
                        int* n,       // count of elements in a vector
                        int* lot,     // count of vectors
                        int* ISIGN    // -1 => time2freq, +1 => freq2time
);
extern "C" void needle_(                        //
    double* a_,                                 // inout, elements[lot][N+2]
    int* batch_size_, int* batch_distance_    // distance
);