#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process get_metadata_and_create_dada_file_list {
    label 'create_config'
    container "${params.apptainer_images.data_distribution_image}"
    errorStrategy = 'ignore'

    input:
    path(delay_file)
    val(source_name)
    val(bridge_number)
    path(bvruse_metadata)
    val(beamformer_input_root_dir)

    output:
    tuple path("*.dada.list"), path(delay_file), env(obs_duration)
   
    script:
    """
    #!/bin/bash
    source /workspace/python_environments/dada_generator/bin/activate
    python /workspace/BEAMFORMER/meerkat-data-distribution/python/get_pointing_id_from_source_name.py ${bvruse_metadata} -s ${source_name} -b ${bridge_number} -d ${beamformer_input_root_dir} > metadata.info
    # Extract dada_dir from config file
    dada_dir=\$(grep "dada_dir" metadata.info | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    pointing_id=\$(grep "pointing_id" metadata.info | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    obs_duration=\$(grep "obs_duration" metadata.info | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
    output_file=${source_name}_bridge_${bridge_number}.dada.list

    find "\$dada_dir" -maxdepth 1 -type f -name "*.dada" | sort  > "\$output_file"
    """
}


process create_delay_file{
        label 'create_config'
        container "${params.apptainer_images.skyweaverpy_image}"
        
        input:
        val(source_name)
        val(delay_validity_time_interval)
        path(bvruse_metadata)
        path(config_file)

        output:
        tuple path("*.bin"), path("*.mosaic"), path("*.csv"), path("*.fits"), path("*.png"), path("*.targets")

        publishDir "${params.beamformer.output_root_dir}/${params.source_name}", pattern: "*.bin", mode: 'copy'
        publishDir "${params.beamformer.output_root_dir}/${params.source_name}", pattern: "*.mosaic", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}", pattern: "*.csv", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}", pattern: "*.fits", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}", pattern: "*.png", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}", pattern: "*.targets", mode: 'copy'
        

        script:
        """
        #!/bin/bash
        mkdir -p ${params.beamformer.output_root_dir}/${params.source_name}
        python /b/u/vishnu/BEAMFORMER/meerkat-data-distribution/python/get_pointing_id_from_source_name.py -s ${source_name} ${bvruse_metadata} > pointing_id.txt
        pointing_id=\$(grep "pointing_id" pointing_id.txt | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
        python ${params.beamformer.skyweaverpy_code_dir}/cli.py delays create --pointing-idx \${pointing_id} --step ${delay_validity_time_interval} ${bvruse_metadata} ${config_file}
        cp ${config_file} ${params.beamformer.output_root_dir}/${params.source_name}
        
        #sw delays create --pointing-idx \${pointing_id} --step ${delay_validity_time_interval} ${bvruse_metadata} ${config_file}
        """


}

process create_skyweavercpp_config{
    label 'create_config'
    container "${params.apptainer_images.skyweaverpy_image}"

    input:
    path(skyweaverpy_yaml_config)
    path(output_skyweaver_cpp_config)
    tuple path(dada_file_list), path(delay_file), val(obs_duration)

    output:
    tuple path("**/*.ini"), path(dada_file_list), path(delay_file)

    script:
    """
    #!/bin/bash
    if [ -z "${params.beamformer.obs_duration}" ] ; then
        obs_length=${obs_duration}
    else
        obs_length=${params.beamformer.obs_duration}
    fi
    python $baseDir/yaml_to_ini_convert.py -y ${skyweaverpy_yaml_config} -i ${output_skyweaver_cpp_config} -o ${params.beamformer.output_root_dir}/${params.source_name} -d ${delay_file} -t \${obs_length} -f ${dada_file_list}
    """
}


process beamformer {
    label 'beamformer'
    container "${params.apptainer_images.skyweavercpp_image}"
    errorStrategy { task.exitStatus in 2 ? 'retry' : 'ignore' }
    maxRetries 3

    input:
    tuple path(skyweaver_cpp_config), path(dada_file_list), path(delay_file)

    output:
    stdout

    script:
    def skyweavercpp_path = params.beamformer.skyweavercpp_code_dir ? "${params.beamformer.skyweavercpp_code_dir}/skyweavercpp" : '/usr/local/bin/skyweavercpp'

    """
    #!/bin/bash    
    export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib
    ${skyweavercpp_path} --gulp-size ${params.beamformer.skyweavercpp_gulp_size} -c ${skyweaver_cpp_config} --log-level ${params.beamformer.skyweavercpp_log_level}
    """
}



workflow {
    bridge_number = Channel.from(params.bridge_number)
    delay_file_channel = create_delay_file(params.source_name, params.beamformer.delay_validity_time_interval, params.bvruse_metadata, params.input_yaml_config)

    delay_file_path = delay_file_channel.map { item ->
    def (delay_file, mosaic, csv, fits, png, targets) = item
    return delay_file
    }   

    metadata_channel = get_metadata_and_create_dada_file_list(delay_file_path, params.source_name, bridge_number, params.bvruse_metadata, params.beamformer.input_root_dir)
    sw_cpp_config = create_skyweavercpp_config(params.input_yaml_config, params.skyweaver_cpp_config, metadata_channel)
    beamformer(sw_cpp_config)
    

}

