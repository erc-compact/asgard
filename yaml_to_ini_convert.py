import yaml, os
import argparse

def read_yaml(file_path):
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)
    return data

def extract_ddplan(data):
    ddplan = data.get('ddplan', [])
    return ddplan

def write_ini(file_path, ddplan, additional_settings):
    with open(file_path, 'w') as file:
        for entry in ddplan:
            file.write(f"ddplan={entry}\n")
        for key, value in additional_settings.items():
            file.write(f"{key}={value}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process YAML to INI conversion")
    parser.add_argument('-y', '--yaml-file', type=str, required=True, help="Path to the input YAML file")
    parser.add_argument('-i', '--ini-file', type=str, required=True, help="Path to the output INI file")
    parser.add_argument('-f', '--dada_file_list', type=str, required=True, help="Path to the Dada file list per bridge")
    parser.add_argument('-e', '--enable-incoherent-dedispersion', type=int, default=1, help="Enable incoherent dedispersion")
    parser.add_argument('-n', '--nthreads', type=int, default=16, help="Number of threads")
    parser.add_argument('-o', '--output-dir', type=str, default='/b/u/vishnu/01_BEAM_FORMED/', help="Output directory")
    parser.add_argument('-d', '--delay-file', type=str, required=True, help="Delay file")
    parser.add_argument('-t', '--duration', type=float, required=True, help="Duration")
    parser.add_argument('-l', '--log-level', type=str, default='warning', help="Log level")

    args = parser.parse_args()

    data = read_yaml(args.yaml_file)
    ddplan = extract_ddplan(data)

    additional_settings = {
        "input-file": args.dada_file_list,
        "enable-incoherent-dedispersion": args.enable_incoherent_dedispersion,
        "nthreads": args.nthreads,
        "output-dir": args.output_dir,
        "delay-file": args.delay_file,
        "duration": args.duration - 1.0,
        "log-level": args.log_level
    }
    os.makedirs("results", exist_ok=True)
    write_ini(f"results/{args.ini_file}", ddplan, additional_settings)
    
    print(f"INI file results/'{args.ini_file}' has been created.")
