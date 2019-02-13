//https://software.intel.com/en-us/mkl-developer-reference-c-fft-code-examples#AC30C86F-9E01-4A5F-B086-CE7FBCE2126A

#include <mkl_dfti.h>
#include <stdbool.h>
#include <stdio.h>
bool fft_init=false;
DFTI_DESCRIPTOR_HANDLE forward_handle;
DFTI_DESCRIPTOR_HANDLE backward_handle;
MKL_LONG status, l;
void mkl_fft_(    
    double* a_,                  // inout, elements[lot][N+2]
    int* inc_,                   // data memory addr increment of elements
    int* jump_,                  // data memory addr increment of vector
    int* n_,                     // count of elements in a vector
    int* lot_,                   // count of vectors
    int* ISIGN_ // -1 => time2freq, +1 => freq2time
){

  if(!fft_init){
   //l[0] = *lot_; 
    printf ('[ASC debug] Y00: mkl_fft  n_, %d\n',  *n_);

   //puts("[ASC debug] Y00: mkl_fft init!");
   //l = *n_;
   int stride = *inc_;
   int real_dist = *jump_;
   int complex_dist = real_dist / 2;
   status = DftiCreateDescriptor( &forward_handle, DFTI_DOUBLE,
             DFTI_COMPLEX, 1, *n_);
         if (status && !DftiErrorClass(status,DFTI_NO_ERROR)){
        printf ('Error: %s\n', DftiErrorMessage(status));
     }
   status = DftiSetValue( forward_handle, DFTI_INPUT_STRIDES, stride);    
   status = DftiSetValue( forward_handle, DFTI_OUTPUT_STRIDES, stride);          
   status = DftiSetValue( forward_handle, DFTI_INPUT_DISTANCE, real_dist);          
   status = DftiSetValue( forward_handle, DFTI_OUTPUT_DISTANCE, complex_dist);          
   status = DftiCommitDescriptor( forward_handle );

   status = DftiCreateDescriptor( &backward_handle, DFTI_DOUBLE,
             DFTI_REAL, 1, *n_);
   status = DftiSetValue( backward_handle, DFTI_INPUT_STRIDES, stride);    
   status = DftiSetValue( backward_handle, DFTI_OUTPUT_STRIDES, stride);          
   status = DftiSetValue( backward_handle, DFTI_INPUT_DISTANCE, complex_dist );          
   status = DftiSetValue( backward_handle, DFTI_OUTPUT_DISTANCE, real_dist);          
   status = DftiCommitDescriptor( backward_handle);
   /* result is given by y_out in CCS format*/

     fft_init=true;
  puts("[ASC debug] Y00: mkl_fft init done!");
  }
  int count=  *lot_;
  if(*ISIGN_ == -1) {
      while(count>0){

        printf ('[ASC debug] Y00: mkl_fft  %d\n', count);
        status = DftiComputeForward( forward_handle,a_);
        a_++;
        count--;
          }  
  } else {
     while(count>0){

       printf ('[ASC debug] Y00: mkl_fft  %d\n', count);
       status = DftiComputeForward( backward_handle,a_);
       a_++;
       count--;
         } 
      }

    if (status && !DftiErrorClass(status,DFTI_NO_ERROR)){
        printf ('Error: %s\n', DftiErrorMessage(status));
    }
}

void mkl_fft_init_(    
    int* inc_,                   // data memory addr increment of elements
    int* jump_,                  // data memory addr increment of vector
    int* n_                     // count of elements in a vector
){

}
