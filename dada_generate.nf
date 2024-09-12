#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process createConfig_Data_Distribution {
    label 'create_config'
    container "${params.data_distribution_image}"
    errorStrategy = 'ignore'

    input:
    tuple val(pointing_id), val(bridge_number)
    path(bvruse_metadata)
    val(input_root_dir)
    val(output_root_dir)

    output:
    path("bridge_${bridge_number}.conf")
   
    script:
    """
    #!/bin/bash
    source /workspace/python_environments/dada_generator/bin/activate
    #python /workspace/BEAMFORMER/meerkat-data-distribution/python/make_config_from_metadata.py ${bvruse_metadata} -p ${pointing_id} -b ${bridge_number} -r ${input_root_dir} -d ${output_root_dir} > bridge_${bridge_number}.conf
    python /workspace/BEAMFORMER/meerkat-data-distribution/python/make_config.py ${bvruse_metadata} -p ${pointing_id} -b ${bridge_number} -r ${input_root_dir} -d ${output_root_dir} > bridge_${bridge_number}.conf

    #Extract dest_dir from config file
    #dest_dir=\$(grep "dest_dir" bridge_${bridge_number}.conf | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    
    """
}

process CREATE_DADA {
    label 'create_dada'
    container "${params.data_distribution_image}"
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
    /workspace/BEAMFORMER/meerkat-data-distribution/distribute -c ${config_file} 
    echo "Distribution process completed"
    set +x  # Disable debugging
    """


}

workflow create_dada_workflow {
    pointing_id = Channel.from(params.pointing_id)
    bridge_number = Channel.from(params.bridge_number)
    pointing_bridge = pointing_id.combine(bridge_number)
    config_file_channel = createConfig_Data_Distribution(pointing_bridge, params.bvruse_metadata, params.input_root_dir, params.output_root_dir)
    dada_output = CREATE_DADA(config_file_channel)


    } 

workflow {
    create_dada_workflow()

}

