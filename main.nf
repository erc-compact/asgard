#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process get_metadata_and_create_dada_file_list {
    label 'create_config'
    container "${params.apptainer_images.data_distribution_image}"
    errorStrategy = 'ignore'

    input:
    tuple path(delay_file), val(bridge_number)
    val(source_name)
    path(bvruse_metadata)
    val(beamformer_input_root_dir)

    output:
    tuple path("*.dada.list"), path(delay_file), env(obs_duration)
   
    script:
    """
    #!/bin/bash
    source /workspace/python_environments/dada_generator/bin/activate
    python ${params.dada_generate.code_directory}/python/get_pointing_id_from_source_name.py ${bvruse_metadata} -s ${source_name} -b ${bridge_number} -d ${beamformer_input_root_dir} > metadata.info
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
        val(start_utc)
        val(delay_validity_time_interval)
        path(bvruse_metadata)
        path(config_file)

        output:
        tuple path("*.bin"), path("*.mosaic"), path("*.csv"), path("*.fits"), path("*.png"), path("*.targets")

        publishDir "${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}", pattern: "*.bin", mode: 'copy'
        publishDir "${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}", pattern: "*.mosaic", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}", pattern: "*.csv", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}", pattern: "*.fits", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}", pattern: "*.png", mode: 'copy'
        publishDir  "${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}", pattern: "*.targets", mode: 'copy'
        

        script:
        """
        #!/bin/bash
        mkdir -p ${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}
        python ${params.dada_generate.code_directory}/python/get_pointing_id_from_source_name.py -s ${source_name} ${bvruse_metadata} > pointing_id.txt
        pointing_id=\$(grep "pointing_id" pointing_id.txt | awk -F '=' '{print \$2}' | sed 's/[", ]//g')
        python ${params.beamformer.skyweaverpy_code_dir}/cli.py delays create --pointing-idx \${pointing_id} --step ${delay_validity_time_interval} ${bvruse_metadata} ${config_file}
        cp ${config_file} ${params.beamformer.output_root_dir}/${params.source_name}/${start_utc}
        
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

process get_dada_start_utc_time {
    label 'create_config'
    container "${params.apptainer_images.skyweaverpy_image}"

    input:
    val(input_root_dir)
    path(bvruse_metadata)
    val(pointing_id)

    output:
    env(utc_time)

    script:
    """
    #!/bin/bash
    python ${params.dada_generate.code_directory}/python/make_config_from_metadata.py ${bvruse_metadata} -p ${pointing_id} > sample.conf
    pointing_start_utc_from_metadata_file=\$(grep "date=" sample.conf | awk -F'=' '{print \$2}' | tr -d '" ')
    source_name=\$(grep "source =" sample.conf | awk -F'=' '{print \$2}' | tr -d '" ')
    #There can be offsets between when the bvruse metadata says the observation started and when the dada files in all the bridges actually start. 
    #Now find the utc start time of the dada files
    utc_timestamp=\$($baseDir/find_start_utc_timestamp_dada_files.sh ${input_root_dir}/\$source_name/\$pointing_start_utc_from_metadata_file)
    utc_time=\$(python ${params.dada_generate.code_directory}/python/find_dada_utc_start_time_from_timestamp.py -t \${utc_timestamp})
   

    """
}


workflow {
    pointing_id = Channel.from(params.pointing_id)
    utc_start_time = get_dada_start_utc_time(params.beamformer.input_root_dir, params.bvruse_metadata, pointing_id)
    delay_file_channel = create_delay_file(params.source_name, utc_start_time, params.beamformer.delay_validity_time_interval, params.bvruse_metadata, params.input_yaml_config)

    delay_file_path = delay_file_channel.map { item ->
    def (delay_file, mosaic, csv, fits, png, targets) = item
    return delay_file
    } 
    bridge_number = Channel.from(params.bridge_number)
    delay_file_path_bridge_combined = delay_file_path.combine(bridge_number)

    metadata_channel = get_metadata_and_create_dada_file_list(delay_file_path_bridge_combined, params.source_name, params.bvruse_metadata, params.beamformer.input_root_dir)
    sw_cpp_config = create_skyweavercpp_config(params.input_yaml_config, params.skyweaver_cpp_config, metadata_channel)
    beamformer(sw_cpp_config)
    

}

