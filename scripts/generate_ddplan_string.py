import numpy as np

# Define constants
coherent_dm = 120.0
#coherent_dm = 100.0

dm_search_range = 10  # coherent_dm ± dm_search_range
coherent_dm_step = 0.5
incoherent_dm_interval = coherent_dm_step / 2
incoherent_ddplan_step = 0.05
tscrunch = 1
compact_incoherent_ddplan_step = 1
# Calculate DM ranges
low_cdm = coherent_dm - dm_search_range
high_cdm = coherent_dm + dm_search_range + coherent_dm_step  # Include the last value

# Generate trial DMs
cdm_trials = np.arange(low_cdm, high_cdm, coherent_dm_step)
incoherent_dm_start = cdm_trials - incoherent_dm_interval
incoherent_dm_end = cdm_trials + incoherent_dm_interval - incoherent_ddplan_step

# Print the results in the desired format
def colin_use_case(cdm_trials):
    print("ddplan:")
    for i in range(len(cdm_trials)):
        print(f'  - "{cdm_trials[i]:.2f}:{incoherent_dm_start[i]:.2f}:{incoherent_dm_end[i]:.2f}:{incoherent_ddplan_step:.2f}:{tscrunch}"')

def compact_use_case(cdm_trials):
    print("ddplan:")
    for i in range(len(cdm_trials)):
        print(f'  - "{cdm_trials[i]:.2f}:{cdm_trials[i]:.2f}:{cdm_trials[i]:.2f}:{compact_incoherent_ddplan_step}:{tscrunch}"')

# Print the results
compact_use_case(cdm_trials)