subroutine gffgch(t       ,es      ,itype   )
!----------------------------------------------------------------------- 
! 
! Purpose: 
! Computes saturation vapor pressure over water and/or over ice using
! Goff & Gratch (1946) relationships. 
! <Say what the routine does> 
! 
! Method: 
! T (temperature), and itype are input parameters, while es (saturation
! vapor pressure) is an output parameter.  The input parameter itype
! serves two purposes: a value of zero indicates that saturation vapor
! pressures over water are to be returned (regardless of temperature),
! while a value of one indicates that saturation vapor pressures over
! ice should be returned when t is less than freezing degrees.  If itype
! is negative, its absolute value is interpreted to define a temperature
! transition region below freezing in which the returned
! saturation vapor pressure is a weighted average of the respective ice
! and water value.  That is, in the temperature range 0 => -itype
! degrees c, the saturation vapor pressures are assumed to be a weighted
! average of the vapor pressure over supercooled water and ice (all
! water at 0 c; all ice at -itype c).  Maximum transition range => 40 c
! 
! Author: J. Hack
! 
!-----------------------------------------------------------------------
   use shr_kind_mod, only: r8 => shr_kind_r8
   use physconst,    only: tmelt
   use abortutils,   only: endrun
   use cam_logfile,  only: iulog
   implicit none
!------------------------------Arguments--------------------------------
!
! Input arguments
!
   real(r8), intent(in) :: t          ! Temperature
   real(r8), parameter :: tboil = 373.16_r8

!
! Output arguments
!
   integer, intent(inout) :: itype   ! Flag for ice phase and associated transition

   real(r8), intent(out) :: es         ! Saturation vapor pressure
!

  es = 10._r8**(-7.90298_r8*(tboil/t-1._r8)+ &
  5.02808_r8*log10(tboil/t)- &
  1.3816e-7_r8*(10._r8**(11.344_r8*(1._r8-t/tboil))-1._r8)+ &
  8.1328e-3_r8*(10._r8**(-3.49149_r8*(tboil/t-1._r8))-1._r8)+ &
  log10(1013.246_r8))*100._r8
!
end subroutine gffgch
