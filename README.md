# cif2cellplus
Data processing script for large amount of cif files for CASTEP calculation.

## Usage
1. Install cif2cell. The fastest way to do it is\
```pip install cif2cell```
2. Change the account of allocation in both `./default/main_job_convergence.sh` and `./default/main_job.sh` at \
```#SBATCH --account= #YOUR_ACCOUNT```\
section.
3. Create ./cifs/ folder parallel with `cif2cellplus.py`.
5. Put cif files in ./cifs/ folder, and rename it as needed. The name of the cif file would be used throughout as an identification, so names such as `EntryWithCollCode*.cif` are not recommended.
6. Run `python cif2cellplus.py`.
7. Change directory to each generated folder and run\
`sbatch main_job.sh`

## Examples
2 cif files are given in the `./examples/` folder. copy and paste it to `./cifs/` folder and run the `cif2cellplus.py`.
## Developing
Batch editing from geo-opt to NMR.\
A script that runs all the generated main_job.sh.
