
process known_pulsar_folding {
    label 'known_pulsar_folder'
    container "${params.apptainer_images.pulsar_folder_image}"
    input:
        tuple val(groupKey), val(dirname), val(beam_name), path(filterbank_files), path(par_file)

   
    output:
    tuple val(groupKey), val(dirname), val(beam_name), env(psrname), path("*.ar")

    //publishDir "${params.known_pulsar_folder.dspsr_out_root}/${params.source_name}/${groupKey}/${par_file.baseName.replaceFirst(/\\.[^.]+$/, '')}/", mode: 'copy'
    publishDir "${params.known_pulsar_folder.dspsr_out_root}/${params.source_name}/${params.skycleaver.utc}/${params.skycleaver.stream_id}/${dirname}/${par_file.baseName.replaceFirst(/\\.[^.]+$/, '')}/", mode: 'copy'

    // script:
    """
    #!/bin/bash
    dspsr ${params.known_pulsar_folder.dspsr_flags} -E ${par_file} -t ${params.known_pulsar_folder.dspsr_nthreads} ${filterbank_files}
    psrname=\$(basename ${par_file} .par)
    """
}

process pdmp {

    label 'pdmp_runner'
    container "${params.apptainer_images.pulsar_folder_image}"


    input:
        tuple val(groupKey), val(dirname), val(beam_name), val(psrname), path(archive)

    output:
        tuple path("*.png"), val(beam_name), env('ra'), env('dec'), env('snr')

    //publishDir "${params.known_pulsar_folder.dspsr_out_root}/${params.source_name}/${groupKey}/${par_file.baseName.replaceFirst(/\\.[^.]+$/, '')}/", mode: 'copy'
    publishDir "${params.known_pulsar_folder.dspsr_out_root}/${params.source_name}/${params.skycleaver.utc}/${params.skycleaver.stream_id}/${dirname}/${psrname}/", mode: 'copy'

    script:
    """
    #!/bin/bash
    #psrname is par_file name without extension
    png_name="${psrname}.png/PNG"
    pdmp ${params.known_pulsar_folder.pdmp_flags} -g \$png_name ${archive}
    output=\$(psrstat -c coord ${archive})
    ra=\$(echo "\$output" | awk -F 'coord=' '{print \$2}' | awk '{split(\$1, a, "-"); print a[1]}')
    dec=\$(echo "\$output" | awk -F 'coord=' '{print \$2}' | awk '{split(\$1, a, "-"); print "-" a[2]}')
    echo "RA: \$ra"
    echo "DEC: \$dec"
    snr=\$(awk '{print \$7}' pdmp.per)
    #beam_name=\$(echo "${groupKey}" | cut -d'_' -f2)
    
    """
}

process updateSNRTargets {
    container "${params.apptainer_images.skyweaverpy_image}"


    input:
    val pdmp_results
    path targets_file

    output:
    path '*pdmp_snr.csv'

    publishDir "${params.beamformer.output_root_dir}/${params.source_name}", pattern: "*pdmp_snr.csv", mode: 'copy'

  
    script:
    """
    #!/usr/bin/env bash
    echo ${pdmp_results} > pdmp_results.txt
    python ${baseDir}/scripts/merge_snr_targets.py -p pdmp_results.txt -t ${targets_file}
    """
}

process plot_pdmp_beam_map {
    container "${params.apptainer_images.skyweaverpy_image}"
    input:
    path(pdmp_snr_file)
    output:
    path "*.png"

    publishDir "${params.beamformer.output_root_dir}/${params.source_name}", mode: 'copy'
    
    script:
    """
    python ${baseDir}/scripts/plot_tiling_snr.py --tiling ${pdmp_snr_file} --source ${params.source_name}
    """

}


workflow {
    // Collect all filterbank files into a channel
    filterbanks = Channel.fromPath("${params.skycleaver.output_root}/${params.skycleaver.utc}/${params.source_name}/${params.skycleaver.stream_id}/*.fil")

    // Group filterbanks by unique names
    filterbank_groups = filterbanks
        .map { file ->
            def filename = file.getName()
            def groupKey = filename.split('_').init().join('_')
            def dirname = groupKey.replaceAll(/_\d{4}-\d{2}-\d{2}-\d{2}:\d{2}:\d{2}_\d+/, '')
            def beam_name = dirname.split('_')[1]
            tuple(groupKey, dirname, beam_name, file)
        }
        //.groupTuple()
    par_files = Channel.fromPath("${params.known_pulsar_folder.ephem_dir}/*.par")
    combined_files = filterbank_groups.combine(par_files)
    archives = known_pulsar_folding(combined_files)
    pngs = pdmp(archives)
    
    // Collect results into a list
    pdmpResults = pngs.map { filename, beam_name, ra, dec, snr ->
        tuple(beam_name, snr)
    }.collect(flat: false)
    
    updated_snr_file = updateSNRTargets(pdmpResults, "/b/PROCESSING/01_BEAMFORMED/J0437-4715/swdelays_J0437-4715_1716133181_to_1716133306_ba3d22.targets")
    plot_pdmp_beam_map(updated_snr_file)
    
}

