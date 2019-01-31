#!/bin/bash
echo 'you need to download tar cam53_f19c4aqpgro_ys.tar.gz and cam.zip from sftp first'
./cuda-build.sh

export INC_MPI=/media/rgy/win-file/document/computer/HPC/cesm/openmpi/include
export LIB_MPI=/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib
export LIB_NETCDF=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib
export INC_NETCDF=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/include
export LDFLAGS='-L/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib -L/usr/local/cuda/lib64/ -lcuda -lcudart -lstdc++'

echo "you need to build cprnc in tools/cprnc first"
./build-cprnc.sh || exit 2

export LD_LIBRARY_PATH=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib:${LD_LIBRARY_PATH}:/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib/ 

./configure -dyn fv -hgrid 1.9x2.5 -ntasks 1 -phys cam4 -ocn aquaplanet -pergro -fc gfortran
./build-namelist -s -case cam5.0_port -runtype startup  -csmdata ./\
 -namelist "&camexp stop_option='ndays', stop_n=2 nhtfrq=1 ndens=1 \
   mfilt=97 hfilename_spec='h%t.nc' empty_htapes=.true. \
   fincl1='T:I','PS:I' /"
rm -f Depends

export FC=mpifort

gmake > gmake.log

echo "now link the cam"
rm -f ./cam
mpifort -o /media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/cam \
C_interface_mod.o ESMF.o ESMF_AlarmClockMod.o ESMF_AlarmMod.o ESMF_BaseMod.o ESMF_BaseTimeMod.o ESMF_CalendarMod.o \
ESMF_ClockMod.o ESMF_FractionMod.o ESMF_ShrTimeMod.o ESMF_Stubs.o ESMF_TimeIntervalMod.o ESMF_TimeMod.o FVperf_module.o \
GPTLget_memusage.o GPTLprint_memusage.o GPTLutil.o MeatMod.o abortutils.o advect_tend.o aer_rad_props.o aer_rad_props_cuda.o \
aerodep_flx.o aerosol_intr.o aircraft_emit.o alloc_mod.o aoa_tracers.o apex_subs.o atm_comp_mct.o benergy.o bnddyi.o \
boundarydata.o box_rearrange.o buffer.o calcdecomp.o calcdisplace_mod.o cam3_aero_data.o cam3_ozone_data.o cam_comp.o \
cam_control_mod.o cam_cpl_indices.o cam_diagnostics.o cam_history.o cam_history_buffers.o cam_history_support.o cam_initfiles.o \
cam_instance.o cam_logfile.o cam_pio_utils.o cam_restart.o camsrfexch.o carma_flags_mod.o carma_intr.o carma_model_flags_mod.o \
ccsm_comp_mod.o ccsm_driver.o cd_core.o cfc11star.o charge_neutrality.o check_energy.o chem_mods.o chem_surfvals.o chemistry.o \
chlorine_loading_data.o cldwat.o cldwat2m_macro.o cloud_cover_diags.o cloud_diagnostics.o cloud_fraction.o cloud_rad_props.o \
clubb_intr.o clybry_fam.o cmparray_mod.o co2_cycle.o co2_data_flux.o commap.o comspe.o comsrf.o constituent_burden.o constituents.o \
conv_water.o convect_deep.o convect_shallow.o cosp_share.o cospsimulator_intr.o cpslec.o ctem.o d2a3dijk.o d2a3dikj.o dadadj.o \
datetime.o debugutilitiesmodule.o decompmodule.o diag_dynvar_ic.o diag_module.o diffusion_solver.o dp_coupling.o drv_input_data.o \
dryairm.o drydep_mod.o dust_intr.o dust_sediment_mod.o dycore.o dyn_comp.o dyn_grid.o dyn_internal_state.o dynamics_vars.o \
eddy_diff.o efield.o epvd.o error_messages.o euvac.o exbdrift.o f_wrappers.o fft99.o  fft99_cuda.o filenames.o \
fill_module.o flux_avg.o fv_control_mod.o fv_prints.o gas_wetdep_opts.o gauaw_mod.o geopk.o geopk_cuda.o geopotential.o ghg_data.o \
ghostmodule.o glc_comp_mct.o gptl.o gptl_papi.o gravity_waves_sources.o gw_drag.o hb_diff.o hirsbt.o hirsbtpar.o history_defaults.o history_scam.o hk_conv.o horizontal_interpolate.o hycoef.o ice_comp_mct.o infnan.o inidat.o inital.o initcom.o interp_mod.o interpolate_data.o intp_util.o ioFileMod.o iompi_mod.o iondrag.o ionf_mod.o ionosphere.o iop_surf.o lin_strat_chem.o linoz_data.o llnl_O1D_to_2OH_adj.o lnd_comp_mct.o m_sad_data.o m_spc_id.o m_types.o macrop_driver.o mag_parms.o majorsp_diffusion.o mapz_module.o marsaglia.o mct_mod.o mean_module.o memstuff.o metdata.o micro_mg1_0.o micro_mg1_5.o micro_mg_cam.o microp_aero.o microp_driver.o mo_adjrxt.o mo_aero_settling.o mo_aerosols.o mo_airglow.o mo_airmas.o mo_airplane.o mo_apex.o mo_aurora.o mo_calcoe.o mo_chem_utls.o mo_chemini.o mo_chm_diags.o mo_constants.o mo_cph.o mo_drydep.o mo_exp_sol.o mo_extfrc.o mo_flbc.o mo_fstrat.o mo_gas_phase_chemdr.o mo_ghg_chem.o mo_heatnirco2.o mo_imp_sol.o mo_indprd.o mo_inter.o mo_jeuv.o mo_jlong.o mo_jpl.o mo_jshort.o mo_lightning.o mo_lin_matrix.o mo_lu_factor.o mo_lu_solve.o mo_lymana.o mo_mass_xforms.o mo_mean_mass.o mo_msis_ubc.o mo_negtrc.o mo_neu_wetdep.o mo_nln_matrix.o mo_params.o mo_pchem.o mo_photo.o mo_photoin.o mo_phtadj.o mo_prod_loss.o mo_ps2str.o mo_rtlink.o mo_rxt_rates_conv.o mo_sad.o mo_schu.o mo_setaer.o mo_setair.o mo_setcld.o mo_setext.o mo_sethet.o mo_setinv.o mo_seto2.o mo_setozo.o mo_setrxt.o mo_setsoa.o mo_setsox.o mo_setz.o mo_snoe.o mo_solar_parms.o mo_solarproton.o mo_sphers.o mo_srf_emissions.o mo_strato_rates.o mo_strato_sad.o mo_sulf.o mo_synoz.o mo_tgcm_ubc.o mo_tracname.o mo_trislv.o mo_tuv_inti.o mo_usrrxt.o mo_util.o mo_waccm_hrates.o mo_waveall.o mo_wavelab.o mo_wavelen.o mo_waveo3.o mo_xsections.o mo_zadj.o mod_comm.o modal_aer_opt.o modal_aero_calcsize.o modal_aero_deposition.o modal_aero_wateruptake.o molec_diff.o mp_assign_to_cpu.o mpishorthand.o mrg_mod.o msise00.o mz_aerosols_intr.o namelist_utils.o ncdio_atm.o ndrop.o ndrop_bam.o nf_mod.o nucleate_ice.o ocn_comp.o ocn_comp_mct.o ocn_types.o offline_driver.o p_d_adjust.o par_vecsum.o par_xsum.o parutilitiesmodule.o pbl_utils.o perf_mod.o perf_utils.o pfixer.o pft_module.o phys_control.o phys_debug.o phys_debug_util.o phys_gmean.o phys_grid.o phys_prop.o physconst.o physics_buffer.o physics_types.o physpkg.o pio.o pio_kinds.o pio_mpi_utils.o pio_msg_callbacks.o pio_msg_getput_callbacks.o pio_msg_mod.o pio_nf_utils.o pio_spmd_utils.o pio_support.o pio_types.o pio_utils.o piodarray.o piolib_mod.o pionfatt_mod.o pionfget_mod.o pionfput_mod.o pionfread_mod.o pionfwrite_mod.o piovdc.o pkez.o pkg_cld_sediment.o pkg_cldoptics.o pmgrid.o polar_avg.o ppgrid.o prescribed_aero.o prescribed_ghg.o prescribed_ozone.o prescribed_volcaero.o progseasalts_intr.o pspect.o puminterfaces.o qneg3.o qneg4.o quicksort.o rad_constituents.o rad_solar_var.o radae.o radconstants.o radheat.o radiation.o radiation_data.o radlw.o radsw.o rate_diags.o rayleigh_friction.o readinitial.o rearrange.o redistributemodule.o ref_pres.o restart_dynamics.o restart_physics.o rgrid.o rof_comp_mct.o runtime_opts.o sat_hist.o scamMod.o scyc.o seq_avdata_mod.o seq_cdata_mod.o seq_comm_mct.o seq_diag_mct.o seq_domain_mct.o seq_drydep_mod.o seq_flds_mod.o seq_flux_mct.o seq_frac_mct.o seq_hist_mod.o seq_infodata_mod.o seq_io_mod.o seq_map_esmf.o seq_map_mod.o seq_mctext_mod.o seq_rest_mod.o seq_timemgr_mod.o set_cp.o sgexx.o short_lived_species.o shr_assert_mod.o shr_cal_mod.o shr_carma_mod.o shr_const_mod.o shr_dmodel_mod.o shr_file_mod.o shr_flux_mod.o shr_infnan_mod.o shr_isnan.o shr_jlcp.o shr_kind_mod.o shr_log_mod.o shr_map_mod.o shr_mct_mod.o shr_megan_mod.o shr_mem_mod.o shr_mpi_mod.o shr_msg_mod.o shr_ncread_mod.o shr_nl_mod.o shr_orb_mod.o shr_pcdf_mod.o shr_pio_mod.o shr_reprosum_mod.o shr_reprosumx86.o shr_scam_mod.o shr_spfn_mod.o shr_strdata_mod.o shr_stream_mod.o shr_string_mod.o shr_sys_mod.o shr_tInterp_mod.o shr_test_infnan_mod.o shr_timer_mod.o shr_vmath_fwrap.o shr_vmath_mod.o solar_data.o spedata.o spehox.o spmd_dyn.o spmd_utils.o srchutil.o sslt_rebin.o startup_initialconds.o stepon.o stratiform.o string_utils.o sulchem.o sv_decomp.o sw_core.o te_map.o tidal_diag.o time_manager.o time_utils.o topology.o tp_core.o tphysidl.o trac2d.o tracer_cnst.o tracer_data.o tracer_srcs.o tracers.o tracers_suite.o trb_mtn_stress.o tropopause.o trunc.o tsinti.o unit_driver.o units.o upper_bc.o uv3s_update.o uwshcu.o vertical_diffusion.o vrtmap.o wav_comp_mct.o wei96.o wetdep.o wrap_mpi.o wrap_nf.o wrf_error_fatal.o wrf_message.o wv_sat_methods.o wv_saturation.o xpavg_mod.o zenith.o zm_conv.o zm_conv_cuda.o zm_conv_intr.o zonal_mean.o -L/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib -lnetcdff -L/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib -lnetcdf -lnetcdf -Wl,-rpath=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib  -L/media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/mct/mct -lmct -L/media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/mct/mpeu -lmpeu  -L/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib -lmpi   \
-L/usr/local/cuda/lib64/ -lcuda -lcudart -lstdc++


mpirun ./cam
#pwd
#ls ../../../../tools/cprnc
echo "cprncdf 有bug，需要手动改"
rm -f ./RMST_f1.9_cmp_ibm_5.0
./cprncdf -X ../../../../tools/cprnc/  f19c4aqpgro_cam53_ys_intel.nc h0.nc  > RMST_f1.9_cmp_ibm_5.0
cat ./RMST_f1.9_cmp_ibm_5.0
#https://bb.cgd.ucar.edu/cesm-validation-port-validation-cam-cam4-physics-package
  # ./cprncplt -b -t -pltitle "cam5.0, FV-1.9x2.5, port validation" \
  #   -l "perturbation: cam5.0(ibm)","difference: cam5.0(ibm) - cam5.0(pc/lf95)" \
  #   RMST_f19c4aqpgro_cam53_ys_intel RMST_f1.9_cmp_ibm_5.0

