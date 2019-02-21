module ASCHACK
use iso_c_binding
integer,parameter :: r8 = selected_real_kind(12) 
   public asc_gffgch_init,asc_gffgch_table,PRECISION

   real(r8), pointer :: asc_gffgch_table(:)
   type(c_ptr) :: Cptr
   integer,parameter :: PRECISION = 1000000 ! important, you need to change it at the c and this file!
   integer,parameter,  public :: TABL_SIZE = PRECISION* (350-160)
   !real(r8)   :: asc_gffgch_table(TABL_SIZE)

CONTAINS
subroutine asc_gffgch_init()  
   print *, '[ASC debug] Y00: asc_gffgch_init !'
   call asc_gffgch_init_table
   call asc_gffgch_init_ptr(Cptr)
   CALL C_F_POINTER(Cptr, asc_gffgch_table,[TABL_SIZE])
   !print *, '[ASC debug] Y00: asc_gffgch_init_ptr !',asc_gffgch_table
   ! for debuging!!
   !call init_qmmr_table()
end subroutine asc_gffgch_init

subroutine init_qmmr_table()
   real(r8),parameter  :: tboil = 373.16_r8 
   real(r8)  :: es
   integer i,j
   do i=160,350
      es = 10._r8**(-7.90298_r8*(tboil/t-1._r8)+ &
      5.02808_r8*log10(tboil/t)- &
      1.3816e-7_r8*(10._r8**(11.344_r8*(1._r8-t/tboil))-1._r8)+ &
      8.1328e-3_r8*(10._r8**(-3.49149_r8*(tboil/t-1._r8))-1._r8)+ &
      log10(1013.246_r8))*100._r8
      !print *,'[ASC debug] Y00: cal qmmr',i
      do j = 1,PRECISION
         asc_gffgch_table((i-160)*PRECISION+j)=es
      enddo
   enddo
end subroutine init_qmmr_table
end module ASCHACK