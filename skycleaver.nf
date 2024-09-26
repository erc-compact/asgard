

process skycleaver{

    label 'skycleaver'
    container "${params.apptainer_images.skyweavercpp_image}"

    input:
    stdout

    output:
    stdout

    script:
    def skycleaver_path = params.skycleaver.skycleaver_code_dir ? "${params.skycleaver.skycleaver_code_dir}/skycleaver" : '/usr/local/bin/skycleaver'
    """
    #!/bin/bash
    ${skycleaver_path} -r ${params.skycleaver.root}/${params.skycleaver.utc} --output-dir ${params.skycleaver.output_dir} --nchans ${params.skycleaver.nchans} --nbeams ${params.skycleaver.nbeams} --ndms ${params.skycleaver.ndms} --stream-id ${params.skycleaver.stream_id} --nthreads ${params.skycleaver.nthreads}  --nsamples-per-block ${params.skycleaver.nsamples_per_block}
    """

}

workflow {
    skycleaver()
}