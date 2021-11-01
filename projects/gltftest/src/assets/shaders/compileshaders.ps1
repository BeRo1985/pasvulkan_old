
$compileshaderarguments = @(
  '-V lightclustergridbuild.comp -o lightclustergridbuild_comp.spv',
  '-V mesh.vert -o mesh_vert.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -o mesh_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DALPHATEST -o mesh_masked_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -o mesh_oit_spinlock_reversedz_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DALPHATEST -o mesh_oit_spinlock_reversedz_masked_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -o mesh_oit_spinlock_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DALPHATEST -o mesh_oit_spinlock_masked_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DINTERLOCK -o mesh_oit_interlock_reversedz_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DINTERLOCK -DMASKED -o mesh_oit_interlock_reversedz_masked_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DINTERLOCK -o mesh_oit_interlock_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DINTERLOCK -DMASKED -o mesh_oit_interlock_masked_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DOIT_SIMPLE -o mesh_oit_simple_reversedz_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DOIT_SIMPLE -DMASKED -o mesh_oit_simple_reversedz_masked_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DOIT_SIMPLE -o mesh_oit_simple_frag.spv',
  '-V mesh.frag -DLIGHTS -DSHADOWS -DOIT -DOIT_SIMPLE -DMASKED -o mesh_oit_simple_masked_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -o mesh_oit_msaa_spinlock_reversedz_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DALPHATEST -o mesh_oit_msaa_spinlock_reversedz_masked_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -o mesh_oit_msaa_spinlock_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DALPHATEST -o mesh_oit_msaa_spinlock_masked_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DINTERLOCK -o mesh_oit_msaa_interlock_reversedz_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DINTERLOCK -DMASKED -o mesh_oit_msaa_interlock_reversedz_masked_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DINTERLOCK -o mesh_oit_msaa_interlock_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DINTERLOCK -DMASKED -o mesh_oit_msaa_interlock_masked_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DOIT_SIMPLE -o mesh_oit_msaa_simple_reversedz_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DREVERSEDZ -DOIT_SIMPLE -DMASKED -o mesh_oit_msaa_simple_reversedz_masked_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DOIT_SIMPLE -o mesh_oit_msaa_simple_frag.spv',
  '-V mesh.frag -DMSAA -DLIGHTS -DSHADOWS -DOIT -DOIT_SIMPLE -DMASKED -o mesh_oit_msaa_simple_masked_frag.spv',
  '-V mesh.frag -DDEPTHONLY -o mesh_depth_frag.spv',
  '-V mesh.frag -DDEPTHONLY -DALPHATEST -o mesh_depth_masked_frag.spv',
  '-V oit_resolve.frag -o oit_resolve_frag.spv',
  '-V oit_resolve.frag -DREVERSEDZ -o oit_resolve_reversedz_frag.spv',
  '-V oit_resolve.frag -DMSAA -o oit_resolve_msaa_frag.spv',
  '-V oit_resolve.frag -DMSAA -DREVERSEDZ -o oit_resolve_msaa_reversedz_frag.spv',
  '-V brdf_charlie.frag -o brdf_charlie_frag.spv',
  '-V brdf_ggx.frag -o brdf_ggx_frag.spv',
  '-V fullscreen.vert -o fullscreen_vert.spv',
  '-V cubemap.vert -o cubemap_vert.spv',
  '-V cubemap_sky.frag -o cubemap_sky_frag.spv',
  '-V cubemap_sky.frag -DFAST -o cubemap_sky_fast_frag.spv',
  '-V cubemap_charlie_filter.comp -o cubemap_charlie_filter_comp.spv',
  '-V cubemap_ggx_filter.comp -o cubemap_ggx_filter_comp.spv',
  '-V cubemap_lambertian_filter.comp -o cubemap_lambertian_filter_comp.spv',
  '-V passthrough.vert -o passthrough_vert.spv',
  '-V dummy.frag -o dummy_frag.spv',
  '-V skybox.vert -o skybox_vert.spv',
  '-V skybox.frag -o skybox_frag.spv',
  '-V skybox_realtime.frag -o skybox_realtime_frag.spv',
  '-V tonemapping.frag -o tonemapping_frag.spv',
  '-V antialiasing.frag -o antialiasing_frag.spv',
  '-V blit.frag -o blit_frag.spv',
  '-V msm_blur.frag -o msm_blur_frag.spv',
  '-V msm_blur.vert -o msm_blur_vert.spv',
  '-V msm_resolve.frag -o msm_resolve_frag.spv',
  '-V msm_resolve.frag -DMSAA -o msm_resolve_msaa_frag.spv',
  '-V msm_resolve.vert -o msm_resolve_vert.spv'
)

$MaxThreads = (Get-CIMInstance -Class 'CIM_Processor').NumberOfLogicalProcessors

$curDir = Get-Location

$exepath = "$env:VULKAN_SDK/Bin32/glslangValidator.exe"

Write-Host "Current Working Directory: $curDir"
Write-Host "Count of CPU logical threads: $MaxThreads"

Get-Job | Remove-Job

ForEach ($arguments in $compileshaderarguments) {
  $running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
  if ($running.Count -ge $MaxThreads) {
    $running | Wait-Job -Any | Out-Null
  }
  Start-Job { 
    #Start-Process -FilePath $args[0] -WorkingDirectory $args[1] -ArgumentList $args[2] -NoNewWindow -PassThru -Wait 
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $args[0]
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.WindowStyle = 'Hidden'
    $pinfo.CreateNoWindow = $True
    $pinfo.WorkingDirectory = $args[1]
    $pinfo.Arguments = $args[2]
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null   
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $exitcode = $p.ExitCode
    $p.WaitForExit()     
    return "($exitcode): $stdout $stderr"
  } -ArgumentList "$exepath", "$curDir", "$arguments" | Out-Null 
}

Wait-Job * | Out-Null

foreach ($job in Get-Job) {
  $result = Receive-Job $job
  Write-Host $result
}

Remove-Job -State Completed
