#!/bin/bash

compileshaderarguments=(
  
  '-V downsample.comp -DR11G11B10F -DMIPMAPLEVEL=0 -o downsample_r11g11b10f_level0_comp.spv'
  '-V downsample.comp -DR11G11B10F -DMIPMAPLEVEL=1 -o downsample_r11g11b10f_level1_comp.spv'
  '-V downsample.comp -DR11G11B10F -DMIPMAPLEVEL=2 -o downsample_r11g11b10f_level2_comp.spv'
  '-V downsample.comp -DR11G11B10F -DMIPMAPLEVEL=0 -DMULTIVIEW -o downsample_r11g11b10f_multiview_level0_comp.spv'
  '-V downsample.comp -DR11G11B10F -DMIPMAPLEVEL=1 -DMULTIVIEW -o downsample_r11g11b10f_multiview_level1_comp.spv'
  '-V downsample.comp -DR11G11B10F -DMIPMAPLEVEL=2 -DMULTIVIEW -o downsample_r11g11b10f_multiview_level2_comp.spv'

  '-V downsample.comp -DRGBA16F -DMIPMAPLEVEL=0 -o downsample_rgba16f_level0_comp.spv'
  '-V downsample.comp -DRGBA16F -DMIPMAPLEVEL=1 -o downsample_rgba16f_level1_comp.spv'
  '-V downsample.comp -DRGBA16F -DMIPMAPLEVEL=2 -o downsample_rgba16f_level2_comp.spv'
  '-V downsample.comp -DRGBA16F -DMIPMAPLEVEL=0 -DMULTIVIEW -o downsample_rgba16f_multiview_level0_comp.spv'
  '-V downsample.comp -DRGBA16F -DMIPMAPLEVEL=1 -DMULTIVIEW -o downsample_rgba16f_multiview_level1_comp.spv'
  '-V downsample.comp -DRGBA16F -DMIPMAPLEVEL=2 -DMULTIVIEW -o downsample_rgba16f_multiview_level2_comp.spv'

  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -o downsample_depth_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -DREVERSEDZ -o downsample_depth_reversedz_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -DMSAA -o downsample_depth_msaa_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -DMSAA -DREVERSEDZ -o downsample_depth_msaa_reversedz_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -DMULTIVIEW -o downsample_depth_multiview_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -DMULTIVIEW -DREVERSEDZ -o downsample_depth_multiview_reversedz_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -DMULTIVIEW -DMSAA -o downsample_depth_multiview_msaa_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=0 -DMULTIVIEW -DMSAA -DREVERSEDZ -o downsample_depth_multiview_msaa_reversedz_level0_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=1 -o downsample_depth_level1_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=1 -DMULTIVIEW -o downsample_depth_multiview_level1_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=1 -DREVERSEDZ -o downsample_depth_reversedz_level1_comp.spv'
  '-V downsample_depth.comp -DMIPMAPLEVEL=1 -DMULTIVIEW -DREVERSEDZ -o downsample_depth_multiview_reversedz_level1_comp.spv'

  '-V lightclustergridbuild.comp -o lightclustergridbuild_comp.spv'
  
  '-V mesh.comp -o mesh_comp.spv'

  '-V mesh.vert -o mesh_vert.spv'

  '-V mesh.vert -DVELOCITY -o mesh_velocity_vert.spv'
  
  '-V mesh.frag -DLIGHTS -DSHADOWS -o mesh_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -o mesh_masked_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -DMSAA -o mesh_masked_msaa_frag.spv'  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -DUSEDEMOTE -o mesh_masked_demote_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -DUSEDEMOTE -DMSAA -o mesh_masked_demote_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -DNODISCARD -o mesh_masked_nodiscard_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -DNODISCARD -DMSAA -o mesh_masked_nodiscard_msaa_frag.spv'  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -DNODISCARD -DREVERSEDZ -o mesh_masked_nodiscard_reversedz_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -DNODISCARD -DREVERSEDZ -DMSAA -o mesh_masked_nodiscard_reversedz_msaa_frag.spv'
  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -o mesh_blend_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -o mesh_blend_masked_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -DMSAA -o mesh_blend_masked_msaa_frag.spv'  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -DUSEDEMOTE -o mesh_blend_masked_demote_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -DUSEDEMOTE -DMSAA -o mesh_blend_masked_demote_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -DNODISCARD -o mesh_blend_masked_nodiscard_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -DNODISCARD -DMSAA -o mesh_blend_masked_nodiscard_msaa_frag.spv'  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -DNODISCARD -DREVERSEDZ -o mesh_blend_masked_nodiscard_reversedz_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DBLEND -DALPHATEST -DNODISCARD -DREVERSEDZ -DMSAA -o mesh_blend_masked_nodiscard_reversedz_msaa_frag.spv'
  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DWBOIT -o mesh_wboit_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DWBOIT -DALPHATEST -o mesh_wboit_masked_frag.spv'
  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DMBOIT -DMBOITPASS1 -DDEPTHONLY -o mesh_mboit_pass1_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DMBOIT -DALPHATEST -DMBOITPASS1 -DDEPTHONLY -o mesh_mboit_masked_pass1_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DMBOIT -DMBOITPASS2 -o mesh_mboit_pass2_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DMBOIT -DALPHATEST -DMBOITPASS2 -o mesh_mboit_masked_pass2_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DMBOIT -DMBOITPASS2 -DMSAA -o mesh_mboit_msaa_pass2_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DMBOIT -DALPHATEST -DMBOITPASS2 -DMSAA -o mesh_mboit_masked_msaa_pass2_frag.spv'
  
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -o mesh_lockoit_spinlock_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -DALPHATEST -o mesh_lockoit_spinlock_masked_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -DREVERSEDZ -o mesh_lockoit_spinlock_reversedz_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -DREVERSEDZ -DALPHATEST -o mesh_lockoit_spinlock_reversedz_masked_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -o mesh_lockoit_interlock_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -DALPHATEST -o mesh_lockoit_interlock_masked_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -DREVERSEDZ -o mesh_lockoit_interlock_reversedz_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -DREVERSEDZ -DALPHATEST -o mesh_lockoit_interlock_reversedz_masked_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -DMSAA -o mesh_lockoit_spinlock_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -DALPHATEST -DMSAA -o mesh_lockoit_spinlock_masked_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -DREVERSEDZ -DMSAA -o mesh_lockoit_spinlock_reversedz_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DSPINLOCK -DREVERSEDZ -DALPHATEST -DMSAA -o mesh_lockoit_spinlock_reversedz_masked_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -DMSAA -o mesh_lockoit_interlock_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -DALPHATEST -DMSAA -o mesh_lockoit_interlock_masked_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -DREVERSEDZ -DMSAA -o mesh_lockoit_interlock_reversedz_msaa_frag.spv'
  '-V mesh.frag -DLIGHTS -DSHADOWS -DLOCKOIT -DINTERLOCK -DREVERSEDZ -DALPHATEST -DMSAA -o mesh_lockoit_interlock_reversedz_masked_msaa_frag.spv'

  '-V mesh.frag -DDEPTHONLY -o mesh_depth_frag.spv'
  '-V mesh.frag -DDEPTHONLY -DALPHATEST -o mesh_depth_masked_frag.spv'
  '-V mesh.frag -DDEPTHONLY -DALPHATEST -DUSEDEMOTE -o mesh_depth_masked_demote_frag.spv'  
  '-V mesh.frag -DDEPTHONLY -DALPHATEST -DNODISCARD -o mesh_depth_masked_nodiscard_frag.spv'  
  '-V mesh.frag -DDEPTHONLY -DALPHATEST -DNODISCARD -DREVERSEDZ -o mesh_depth_masked_nodiscard_reversedz_frag.spv'  

  '-V mesh.frag -DDEPTHONLY -DVELOCITY -o mesh_depth_velocity_frag.spv'
  '-V mesh.frag -DDEPTHONLY -DVELOCITY -DALPHATEST -o mesh_depth_velocity_masked_frag.spv'
  '-V mesh.frag -DDEPTHONLY -DVELOCITY -DALPHATEST -DUSEDEMOTE -o mesh_depth_velocity_masked_demote_frag.spv'  
  '-V mesh.frag -DDEPTHONLY -DVELOCITY -DALPHATEST -DNODISCARD -o mesh_depth_velocity_masked_nodiscard_frag.spv'  
  '-V mesh.frag -DDEPTHONLY -DVELOCITY -DALPHATEST -DNODISCARD -DREVERSEDZ -o mesh_depth_velocity_masked_nodiscard_reversedz_frag.spv'  

  '-V mboit_resolve.frag -o mboit_resolve_frag.spv'
  '-V mboit_resolve.frag -DMSAA -o mboit_resolve_msaa_frag.spv'
  '-V wboit_resolve.frag -o wboit_resolve_frag.spv'
  '-V wboit_resolve.frag -DMSAA -o wboit_resolve_msaa_frag.spv'
  
  '-V lockoit_resolve.frag -o lockoit_resolve_frag.spv'
  '-V lockoit_resolve.frag -DREVERSEDZ -o lockoit_resolve_reversedz_frag.spv'
  '-V lockoit_resolve.frag -DMSAA -o lockoit_resolve_msaa_frag.spv'
  '-V lockoit_resolve.frag -DMSAA -DREVERSEDZ -o lockoit_resolve_reversedz_msaa_frag.spv'

  '-V blend_resolve.frag -o blend_resolve_frag.spv'
  '-V blend_resolve.frag -DMSAA -o blend_resolve_msaa_frag.spv'  

  '-V brdf_charlie.frag -o brdf_charlie_frag.spv'
  '-V brdf_ggx.frag -o brdf_ggx_frag.spv'
  
  '-V fullscreen.vert -o fullscreen_vert.spv'
  
  '-V cubemap.vert -o cubemap_vert.spv'
  '-V cubemap_sky.comp -o cubemap_sky_comp.spv'
  '-V cubemap_sky.comp -DFAST -o cubemap_sky_fast_comp.spv'
  '-V cubemap_sky.frag -o cubemap_sky_frag.spv'
  '-V cubemap_sky.frag -DFAST -o cubemap_sky_fast_frag.spv'
  '-V cubemap_charlie_filter.comp -o cubemap_charlie_filter_comp.spv'
  '-V cubemap_ggx_filter.comp -o cubemap_ggx_filter_comp.spv'
  '-V cubemap_lambertian_filter.comp -o cubemap_lambertian_filter_comp.spv'

  '-V passthrough.vert -o passthrough_vert.spv'
  
  '-V dummy.frag -o dummy_frag.spv'

  '-V dithering.frag -o dithering_frag.spv'
  
  '-V skybox.vert -o skybox_vert.spv'
  '-V skybox.frag -o skybox_frag.spv'
  
  '-V skybox_realtime.frag -o skybox_realtime_frag.spv'
  
  '-V tonemapping.frag -o tonemapping_linear_output_frag.spv'
  '-V tonemapping.frag -DOUTPUT_MANUALLY_ENCODED_SRGB -o tonemapping_srgb_output_frag.spv'  
  
  '-V antialiasing.frag -o antialiasing_frag.spv'
  
  '-V blit.frag -o blit_frag.spv'
  
  '-V msm_blur.frag -o msm_blur_frag.spv'
  '-V msm_blur.vert -o msm_blur_vert.spv'
  
  '-V msm_resolve.frag -o msm_resolve_frag.spv'
  '-V msm_resolve.frag -DMSAA -o msm_resolve_msaa_frag.spv'
  '-V msm_resolve.vert -o msm_resolve_vert.spv'

  '-V ssao.frag -o ssao_frag.spv'
  '-V ssao.frag -DMULTIVIEW -o ssao_multiview_frag.spv'

  '-V ssao_blur.frag -o ssao_blur_frag.spv'

)

glslangValidatorPath=$(which glslangValidator)
spirvOptPath=$(which spirv-opt)

echo "Compiling . . ."

for index in ${!compileshaderarguments[@]}; do
   (
     ${glslangValidatorPath} ${compileshaderarguments[$index]} 
     #--target-env spirv1.5 
     #>/dev/null
   ) & 
done

wait 

#echo "Optimizing . . ."

#for f in *.spv; do
#  echo $f
# ${spirvOptPath} --strip-debug --unify-const --flatten-decorations --eliminate-dead-const $f -o $f
# ${spirvOptPath} --strip-debug --unify-const --flatten-decorations --eliminate-dead-const --strength-reduction --simplify-instructions --remove-duplicates -O $f -o $f
#done

echo "Copying . . ."

cp -f *.spv ../../../assets/shaders/
rm -f *.spv

echo "Done!"
