module ASCHACK
use iso_c_binding
integer,parameter :: r8 = selected_real_kind(12) 
   public asc_gffgch_init,asc_gffgch_table,PRECISION
   real(r8), pointer :: asc_gffgch_table(:)
   type(c_ptr) :: Cptr
   integer,parameter :: PRECISION = 1000000 ! important, you need to change it at the c and this file!
   integer,parameter,  public :: TABL_SIZE = PRECISION* (350-160)

CONTAINS
subroutine asc_gffgch_init()  
   print *, '[ASC debug] Y00: asc_gffgch_init !'
   call asc_gffgch_init_table
   call asc_gffgch_init_ptr(Cptr)
   CALL C_F_POINTER(Cptr, asc_gffgch_table,[TABL_SIZE])
end subroutine asc_gffgch_init

end module ASCHACK