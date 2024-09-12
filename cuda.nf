
process gpu_test {
    label 'beamformer'
    container "${params.skyweaverpy_image}"

    input:
    stdout

    output:
    stdout

    script:
    """
    #!/bin/bash
    
    echo "Testing GPU allocation."
    echo "CUDA_VISIBLE_DEVICES: \$CUDA_VISIBLE_DEVICES"
    
    # Run nvidia-smi to check visible GPUs
    nvidia-smi
    
    # HTCondor provides the assigned GPUs through the _CONDOR_AssignedGPUs environment variable
    echo "Assigned GPUs (from HTCondor environment): \$_CONDOR_AssignedGPUs"
    
    """
}





workflow {
    gpu_test()

}