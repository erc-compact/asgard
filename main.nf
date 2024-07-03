#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process createConfig_Data_Distribution {
    label 'create_config'
    container "${params.data_distribution_image}"
    errorStrategy = 'ignore'

    input:
    path(bvruse_metadata)
    val(pointing_id)
    val(bridge_number)
    val(input_root_dir)
    val(output_root_dir)

    output:
    tuple path("bridge_${bridge_number}.conf"), env(dest_dir)
   
    script:
    """
    #!/bin/bash
    source /workspace/python_environments/dada_generator/bin/activate
    python /workspace/BEAMFORMER/meerkat-data-distribution/python/make_config.py ${bvruse_metadata} -p ${pointing_id} -b ${bridge_number} -r ${input_root_dir} -d ${output_root_dir} > bridge_${bridge_number}.conf
    #Extract dest_dir from config file
    dest_dir=\$(grep "dest_dir" bridge_${bridge_number}.conf | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    

    """
}

process CREATE_DADA {
    label 'create_dada'
    container "${params.data_distribution_image}"
    errorStrategy = 'ignore'

    input:
    tuple path(config_file), val(destination_dir)

    output:
    stdout
    


    script:
    """
    #!/bin/bash

    /workspace/BEAMFORMER/meerkat-data-distribution/distribute -c ${config_file} -N

    """


}

workflow {
    bridge_number = Channel.from(params.bridge_number)
    config_file_channel = createConfig_Data_Distribution(params.bvruse_metadata, params.pointing_id, bridge_number, params.input_root_dir, params.output_root_dir)
    dada_output = CREATE_DADA(config_file_channel)

    dada_files = dada_output
        .flatMap { Channel.fromPath("${params.output_root_dir}/**/**/**/**/*.dada") 
        }

    // View the contents of the dada_files channel
    dada_files.view()

    } 

