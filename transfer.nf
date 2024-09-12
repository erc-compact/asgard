process transfer_spead_packets{
    label 'transfer_spead_packets'
    errorStrategy = 'ignore'

    input:
    path rsync_command_file
    val number_of_jobs

    output:
    stdout

    script:
    """
    #!/bin/bash
    source /homes/vishnu/.bashrc
    parallel --jobs ${number_of_jobs} < ${rsync_command_file}
    """
}


workflow {
    rsync_command_file = Channel.fromPath(params.rsync_command_file)
    transfer_spead_packets(rsync_command_file, params.number_of_rsync_jobs)

}