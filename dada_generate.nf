#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process createConfig_Data_Distribution {
    label 'create_config'
    container "${params.apptainer_images.data_distribution_image}"
    errorStrategy = 'ignore'

    input:
    tuple val(pointing_id), val(bridge_number)
    path(bvruse_metadata)
    val(input_root_dir)
    val(output_root_dir)

    output:
    path("bridge_${bridge_number}.conf")


    script:
    def skipTime = params.dada_generate.skip_first_n_seconds ? params.dada_generate.skip_first_n_seconds : 0

    """
    #!/bin/bash
    source /workspace/python_environments/dada_generator/bin/activate
    python /workspace/BEAMFORMER/meerkat-data-distribution/python/generate_bridge_source_dest_dir.py ${bvruse_metadata} -p ${pointing_id} -b ${bridge_number} -r ${input_root_dir} -d ${output_root_dir} > dirnames.conf
    source_dir=\$(grep "source_dir" dirnames.conf | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    dada_dir=\$(grep "dada_dir" dirnames.conf | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    src_tag=\$(grep "tag" dirnames.conf | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    if [ ${skipTime} -gt 0 ]; then
        echo "Skipping the first ${skipTime} seconds of the observation"
        python /workspace/BEAMFORMER/meerkat-data-distribution/python/generate_timestamp_from_duration.py ${bvruse_metadata} -p ${pointing_id} -s ${skipTime} > timestamp.info
        start_timestamp=\$(grep "Start Timestamp" timestamp.info | awk -F ':' '{print \$2}' | sed 's/[", ]//g')
        python /workspace/BEAMFORMER/meerkat-data-distribution/python/make_config_from_metadata.py ${bvruse_metadata} -p ${pointing_id} -b ${bridge_number} -s \${source_dir} -d \${dada_dir} --src_tag \${src_tag} -f \${start_timestamp} > bridge_${bridge_number}.conf
    else
    python /workspace/BEAMFORMER/meerkat-data-distribution/python/make_config_from_metadata.py ${bvruse_metadata} -p ${pointing_id} -b ${bridge_number} -s \${source_dir} -d \${dada_dir} --src_tag \${src_tag} > bridge_${bridge_number}.conf

    fi
    """
}

process CREATE_DADA {
    label 'create_dada'
    container "${params.apptainer_images.data_distribution_image}"
    errorStrategy = 'ignore'
     

    input:
    path(config_file)

    output:
    stdout
    


    script:
    """
    #!/bin/bash
    set -x  # Enable debugging
    export TERM=dumb
    echo "Starting the distribution process"
    time /workspace/BEAMFORMER/meerkat-data-distribution/distribute -c ${config_file} 
    echo "Distribution process completed"
    set +x  # Disable debugging
    """


}

workflow create_dada_workflow {
    pointing_id = Channel.from(params.pointing_id)
    bridge_number = Channel.from(params.bridge_number)
    pointing_bridge = pointing_id.combine(bridge_number)
    config_file_channel = createConfig_Data_Distribution(pointing_bridge, params.bvruse_metadata, params.dada_generate.input_root_dir, params.dada_generate.output_root_dir)
    dada_output = CREATE_DADA(config_file_channel)

    } 

workflow {
    create_dada_workflow()

}

