import pandas as pd
import re
import sys
import argparse
from pathlib import Path


def merge_snr_targets(pdmp_file, targets_file):
    with open(pdmp_file, "r") as file:
        data = file.read()

    data_cleaned = re.sub(r'\b0+(\d+)', r'\1', data)
    data_list = eval(data_cleaned)

    pdmp = pd.DataFrame(data_list, columns=["target_name", "snr"])
    targets = pd.read_csv(targets_file)
    targets['beam_name'] = targets['name'].str.split('_').str[1].astype(int)
    result = pd.merge(targets, pdmp, left_on='beam_name', right_on='target_name')
    result = result[['name', 'ra', 'dec', 'x', 'y', 'angle', 'snr']]
    output_filename = Path(targets_file).stem + "_pdmp_snr.csv"
    result.to_csv(output_filename, index=False)

#argparse stuff
parser = argparse.ArgumentParser(description='Merge SNR targets')
parser.add_argument('-p', '--pdmp_file', type=str, help='PDMP string file')
parser.add_argument('-t', '--targets_file', type=str, help='Input targets file')

args = parser.parse_args()

merge_snr_targets(args.pdmp_file, args.targets_file)
