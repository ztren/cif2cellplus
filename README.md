# cif2cellplus
Data processing script for large amount of cif files for CASTEP calculation.

## Usage
1. Install cif2cell. The fastest way to do it is\
```pip install cif2cell```
2. Change the account of allocation in both `./default/main_job_convergence.sh` and `./default/main_job.sh` at \
```#SBATCH --account= #YOUR_ACCOUNT```\
section.\
3. Put cif files in ./cif/ folder.
4. Run `python cif2cellplus.py`.
5. Change directory to each generated folder and run\
`sbatch main_job.sh`

## Examples
2 cif files are given in the `./examples/` folder. copy and paste it to `./cifs` folder and run the `cif2cellplus.py`.
## Developing
Batch editing from geo-opt to NMR.\
A script that runs all the generated main_job.sh.
