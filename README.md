
# ASGARD: A Nextflow Pipeline for Dedispersing and Beamforming MeerKAT Baseband Data

**ASGARD** is a [Nextflow](https://www.nextflow.io/) pipeline developed for the COMPACT project to process MeerKAT baseband data from raw SPEAD packets to dedispersed, beamformed, and folded pulsar data products.

---

## Overview of the Pipeline

ASGARD wraps together four major processing stages:

1. **DADA Generation**

   Converts raw SPEAD packets to `.dada` format using the [meerkat-data-distribution](https://github.com/erc-compact/meerkat_data_distribution) codebase.

   *Pipeline:* `dada_generate.nf`

2. **Beamforming**

   Performs offline beamforming using the [skyweaver](https://github.com/erc-compact/skyweaver) package.

   *Pipeline:* `beamformer.nf`

3. **Filterbank Generation**

   Reorders beamformer output and generates `.fil` filterbank files using `Skycleaver` (part of the skyweaver package).

   *Pipeline:* `skycleaver.nf`

4. **Known Pulsar Folding**

   Folds known pulsars using provided ephemerides and verifies beamformer performance.

   *Pipeline:* `known_pulsar_fold.nf`

> ⚠️ **Note:** meerkat-data-distribution is a private repository with access limited to the COMPACT team. If you need access, please contact the COMPACT admins.

---

## Getting Started

### Step 1: Prepare Metadata

Before generating `.dada` files, obtain a **BVRUSE metadata file** for the observation.
Example metadata files:
[Skyweaver metadata examples](https://github.com/erc-compact/skyweaver/tree/main/examples/metadata_files)

To inspect a metadata file:

```bash
apptainer exec skyweaver.sif sw metadata show $metadata_file
```

Identify the **Pointing ID** for your target.

---

### Step 2: Configure Nextflow

Copy the default configuration file and rename it for your target:

```bash
cp configs/nextflow/default.config configs/nextflow/M70.config
```

---

### Step 3: Count SPEAD Packets

Run the script `scripts/count_spead_packets.sh` to determine available bridges for a given scan:
Point it to the root directory where the SPEAD packets are stored and the name of the target. The name of the target is provided in the compressed spead packet filename: example (2025-03-28T07:06:12Z_M70_00_07_0032.zst) ->  Here M70 is the target name. 
```bash
scripts/count_spead_packets.sh /media M70
```

Extract the `bridge_number` list from the output and paste it into your config file.

---

### Step 4: Fill Nextflow Config

Copy the list of bridge numbers to your nextflow config file `configs/nextflow/M70.config`. Paste it under params.bridge_number. Additionally also fill up pointing_id, source_name and ensure your apptainer/singularity images in the configuration files exist on disk and are up-to-date.

In `configs/nextflow/M70.config`, set the following:

```groovy
bvruse_metadata = "/path/to/metadata.yaml"
pointing_id     = [2]
source_name     = "J1909-3744"
bridge_number   = [0, 1, 12] //Fill the bridge numbers from output above here

dada_generate {
    code_directory     = "/path/to/meerkat_data_distribution"
    input_root_dir     = "/media"
    output_root_dir    = "$path_to_output_dir/00_DADA_FILES"
    skip_first_n_seconds = 0  // Optional
}
```

To calculate how much time to skip at the start of an observation, see:

* `scripts/get_dada_file_start_time.sh`
* `scripts/get_correct_start_utc_time_dada_files.py`

---

### Step 5: Run DADA Generation

Launch the pipeline:

```bash
nextflow run dada_generate.nf -c configs/nextflow/M70.config -profile contra
```

Add `-resume` to continue from a previous run.

---

## Beamforming

### Prepare YAML Configuration

Use the example YAML file as a template:

```yaml
# File: example_inputs/beamformer_wrapper/J0437-4715.yaml

beamformer_config:
  total_nbeams: 800
  tscrunch: 4
  fscrunch: 1
  stokes_mode: 0
  subtract_ib: true
  coherent_dms: [0.0]

ddplan:
  - "0.00:0.00:0.00:1:1"
  - "2.64:2.64:2.64:1:1"

beam_sets:
  - name: "Rest"
    antenna_set: [...]  # list of MeerKAT antennas
    tilings:
      - nbeams: 800
        target: "J0437-4715,radec,04:37:15.896,-47:15:09.1107"
        overlap: 0.9
```

In your `.config` file:

```groovy
input_yaml_config = "${baseDir}/example_inputs/beamformer_wrapper/J0437-4715.yaml"

beamformer {
    delay_validity_time_interval = 4
    skyweavercpp_gulp_size = 32768
    skyweavercpp_log_level = "release"
    input_root_dir = "$path_to_dada_dir/00_DADA_FILES"
    output_root_dir = "$path_to_beamforming_dir/01_BEAMFORMED"
    skyweavercpp_code_dir = "/path/to/skyweaver_cpp"
    skyweaverpy_code_dir = "/path/to/skyweaver_python"
    obs_duration = ""  // Optional
}
```

Launch beamforming:

```bash
nextflow run beamformer.nf -c configs/nextflow/M70.config -profile contra
```

Output directories are created for each `ddplan` stream.

---

## Filterbank Generation

Fill in your `skycleaver` config section:

```groovy
skycleaver {
    root = "$path_to_beamformer_output/01_BEAMFORMED"
    utc = "2025-03-28T07:06:12Z"
    output_root = "$path_to_input_filterbank/02_FILTERBANKS"
    stream_id = 0  // Select ddplan stream
    nthreads = 360
    nsamples_per_block = 32768
    skycleaver_code_dir = "/path/to/skyweaver_cpp"
    out_stokes = "I"
    log_level = "warning"
}
```

Run:

```bash
nextflow run skycleaver.nf -c configs/nextflow/M70.config -profile contra
```

---

## Folding Known Pulsars

Update your config as follows:

```groovy
known_pulsar_folder {
    dspsr_flags = "-Lmin 5 -L 10 -A"
    dspsr_nthreads = 4
    dspsr_out_root = "$path_to_known_pulsar_folder/03_KNOWN_PULSAR_FOLDS"
    pdmp_flags = "-mc 32"
    ephem_dir = "/path/to/ephemeris/M70"
}
```

Each `.par` file in `ephem_dir` will be folded against all `.fil` files in the corresponding directory.

Run:

```bash
nextflow run known_pulsar_fold.nf -c configs/nextflow/M70.config -profile contra
```

---

## Contact

If you encounter bugs or wish to request features, please submit a pull request or open an issue in this repository.

