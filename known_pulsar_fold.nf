process known_pulsar_folder {
    label 'known_pulsar_folder'
    container "${params.apptainer_images.pulsar_folder_image}"

    input:
        tuple val(groupKey), path(filterbank_files)

    output:
        path("${groupKey}")



    script:
    """
    #!/bin/bash
    ulimit -n 1000000

    ephem_flag=""

    # Build ephemeris flags
    for i in \$(ls ${params.known_pulsar_folder.ephem_dir}/*.par); do
        ephem_flag="\$ephem_flag -E \$i"
    done
    work_dir=\$(pwd)

    # Create the output directory within the process working directory
    mkdir -p "${params.known_pulsar_folder.dspsr_out_root}/${groupKey}"
    cd "${params.known_pulsar_folder.dspsr_out_root}/${groupKey}"

    # Build the list of filterbank files with absolute paths
    filstr=""
    for i in ${filterbank_files}; do
        filstr="\$filstr \${work_dir}/\${i}"
    done

    # Run dspsr from within the output directory
    dspsr ${params.known_pulsar_folder.dspsr_flags} \$ephem_flag \\
          -t ${params.known_pulsar_folder.dspsr_nthreads} \$filstr

    ln -s ${params.known_pulsar_folder.dspsr_out_root}/${groupKey} \$work_dir/${groupKey}
    """
}

process pdmp_runner {

    label 'pdmp_runner'
    container "${params.apptainer_images.pulsar_folder_image}"

    input:
        val(input_dir)

    output:
        stdout


    script:
    """
    #!/bin/bash
    set -e
    ulimit -n 1000000
    input_dir=\$(basename "${input_dir}")
    cd ${params.known_pulsar_folder.dspsr_out_root}/\${input_dir}
    rm -rf pdmp.per pdmp.posn
    # Run pdmp on each pulsar directory
    for i in \$(ls -1d */); do
        psrname=\$(basename "\$i")
        png_name="\${psrname}.png/PNG"
        echo "Running pdmp on \$psrname"
        pdmp ${params.known_pulsar_folder.pdmp_flags} -g \${psrname}/\$png_name  \${psrname}/*.ar
    done
    """
}


workflow {
    // Collect all filterbank files into a channel
    filterbanks = Channel.fromPath("${params.skycleaver.output_root}/${params.skycleaver.utc}/${params.skycleaver.stream_id}/idm_*.fil")

    // Group filterbanks by unique names
    filterbank_groups = filterbanks
        .map { file ->
            def filename = file.getName()
            def groupKey = filename.split('_').init().join('_')
            tuple(groupKey, file)
        }
        .groupTuple()

    // Pass the filterbank groups to the known_pulsar_folder process
    filterbank_groups | known_pulsar_folder | pdmp_runner
}

