# cif2cellplus
Data processing script for large amount of cif files for CASTEP calculation.

## Usage
1. Install cif2cell. The fastest way to do it is ```pip install cif2cell```

2. Change the account of allocation in all `.sh` files in `./default/` at  ```#SBATCH --account= #YOUR_ACCOUNT``` section.

3. Put cif files in ./cifs/ folder, and rename it as needed. The name of the cif file would be used throughout as an identification, so names such as `EntryWithCollCode*.cif` are not recommended.

4. Make scripts executable by `chmod 755 *`

5. Run `python cif2cellplus.py`.

6. Change directory to each generated folder and run `sbatch main_job.sh`

Instead, you could also run `runall.sh` <- new!

## castep_plot.py
plots convergence curves from .castep file directly. Must be used with `castep_read.sh` downloaded in the same folder.
