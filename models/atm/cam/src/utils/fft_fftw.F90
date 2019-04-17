!copyright: TODO
!ifort ./SC_FFT99.F90  -mkl

!include 'fftw3.f'! if you are using the Intel's ifort
module fftw_mkl
    public SC_SETUP,SC_FFT99,SC_FFT991
private    ! FFTW plans
  integer*8 :: plan_r2c = 0, plan_c2r = 0
    !complex(8) output_fft(N/2+1,lot)
  !complex(8), allocatable :: output_fft(:,:)
  !real(8), allocatable :: in(:)
  integer, parameter:: inc = 1


CONTAINS
subroutine SC_SETUP(jump,N,lot)
    complex(8) output_fft(N/2+1,lot)
    real(8)    in((N+2)*lot)
    !allocate (output_fft(N/2+1,lot))
    !allocate (in((N+2)*lot))
!set up the plan
call dfftw_plan_many_dft_r2c(plan_r2c,1,N,lot,&
                           in    ,N,   inc,jump,&
                           output_fft,N/2+1,1,N/2+1,FFTW_ESTIMATE)
call dfftw_plan_many_dft_c2r(plan_c2r,1,N,lot,output_fft,N/2+1,1, &
                             N/2+1,in,   N,   inc,jump, FFTW_ESTIMATE)                            
end subroutine SC_SETUP

subroutine SC_FFT991(in,jump,N,lot,isign)
    real(8),intent(inout) ::in((N+2)*lot)
    complex(8) output_fft(N/2+1,lot)
    integer i,j,k,l,m,inc2,temp
    inc2=inc*2;

    if (isign.EQ.-1) then
        do i=1,lot
            k=(i-1)*jump
            do j = 1,N
                l=k+(j-1)*inc+1
                in(l)=in(l+inc)    !reform the input            
            enddo
        enddo
   call dfftw_execute_dft_r2c(plan_r2c,in,output_fft)
   output_fft=output_fft/real(N)
   do i = 1,lot
     do j = 1,N+1,2
         k=(i-1)*jump+(j-1)*inc+1
         in(k)=real(output_fft(j/2+1,i)) 
         in(k+inc)=aimag(output_fft(j/2+1,i))
     enddo    
   enddo
   end if

   if (isign.EQ.1) then
   do i = 1,lot
    do j = 1,N/2+1
        k=(i-1)*jump+(j-1)*inc2+1
        output_fft(j,i)=cmplx(in(k),in(k+inc))
    enddo       
   enddo
   call dfftw_execute_dft_c2r(plan_c2r,output_fft,in)
   temp=N*inc+1
   do i = 1,lot
      k=(i-1)*jump
      l=k+temp
        do j = N+1,2,-1
            m=k+(j-2)*inc+1
            in(m+inc-1)=in(m)
        enddo
        in(l+inc)=0
        in(l+inc-1)=0
   enddo
end if
end subroutine SC_FFT991

subroutine SC_FFT99(in,jump,N,lot,isign)
    real(8) in((N+2)*lot)
    complex(8) output_fft(N/2+1,lot)
    integer i,j,k,l,m,inc2,temp
    inc2=inc*2;
    if (isign.EQ.-1) then
        do i=1,lot
            k=(i-1)*jump
            do j = 1,N
                l=k+(j-1)*inc+1
                in(l)=in(l+inc)    !reform the input            
            enddo
        enddo
   call dfftw_execute_dft_r2c(plan_r2c,in,output_fft)
   output_fft=output_fft/real(N)
   do i = 1,lot
     do j = 1,N+1,2
         k=(i-1)*jump+(j-1)*inc+1
         in(k)=real(output_fft(j/2+1,i)) 
         in(k+inc)=aimag(output_fft(j/2+1,i))
     enddo    
   enddo
   end if

   if (isign.EQ.1) then
   do i = 1,lot
    do j = 1,N/2+1
        k=(i-1)*jump+(j-1)*inc2+1
        output_fft(j,i)=cmplx(in(k),in(k+inc))
    enddo       
   enddo
   call dfftw_execute_dft_c2r(plan_c2r,output_fft,in)
   temp=N*inc+1
   do i = 1,lot
      k=(i-1)*jump
      l=k+temp
        do j = N+1,2,-1
            m=k+(j-2)*inc+1
            in(m+inc)=in(m)
        enddo
        in(k+1)=in(l)
        in(l+inc)=in(k+inc+1)!this is the 1st X(N-1)
   enddo
end if
end subroutine SC_FFT99


end module fftw_mkl
