
process skycleaver{

    label 'skycleaver'
    container "${params.apptainer_images.skyweavercpp_image}"

    input:
    val(stream_id)

    output:
    stdout

    script:
    
    def skycleaver_path = params.skycleaver.skycleaver_code_dir ? "${params.skycleaver.skycleaver_code_dir}/skycleaver" : '/usr/local/bin/skycleaver'
    """
    #!/bin/bash
    export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib
    targets_file=\$(find ${params.skycleaver.root}/${params.source_name} -name "*targets" | head -n 1)
    echo "targets file is: \$targets_file"
    ${skycleaver_path} -r ${params.skycleaver.root}/${params.source_name}/${params.skycleaver.utc} --targets_file \$targets_file --output-dir ${params.skycleaver.output_root}/${params.source_name}  --stream-id ${stream_id} --nthreads ${task.cpus}  --nsamples-per-block ${params.skycleaver.nsamples_per_block} --out-stokes ${params.skycleaver.out_stokes}  --log-level ${params.skycleaver.log_level}
    """

}


// process skycleaver{

//     label 'skycleaver'
//     container "${params.apptainer_images.skyweavercpp_image}"

//     input:
//     stdout

//     output:
//     stdout

//     script:
//     def skycleaver_path = params.skycleaver.skycleaver_code_dir ? "${params.skycleaver.skycleaver_code_dir}/skycleaver" : '/usr/local/bin/skycleaver'
//     """
//     #!/bin/bash
//     export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib
//     ${skycleaver_path} -r ${params.skycleaver.root}/${params.source_name}/${params.skycleaver.utc} --output-dir ${params.skycleaver.output_root}/${params.source_name} --nchans ${params.skycleaver.nchans} --nbeams ${params.skycleaver.nbeams} --ndms ${params.skycleaver.ndms} --stream-id ${params.skycleaver.stream_id} --nthreads ${params.skycleaver.nthreads}  --nsamples-per-block ${params.skycleaver.nsamples_per_block}
//     """

// }

workflow {
    skycleaver(params.skycleaver.stream_id)
}