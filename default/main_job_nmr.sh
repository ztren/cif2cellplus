#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH -t 12:00:00
#SBATCH --mem=40G
#SBATCH -o out.%j
#SBATCH -e err.%j
#SBATCH -J #DONT_MODIFY_THIS
#SBATCH -p shared
#SBATCH --constraint="lustre"
#SBATCH --account= #YOUR_ACCOUNT
#SBATCH --export=ALL

# Create new scratch directory and add a variable for the new directory name
NEW_DIR="/expanse/lustre/scratch/${USER}/temp_project/castep/${SLURM_JOB_NAME}_${SLURM_JOB_ID}"
DATA="/home/${USER}/project/${SLURM_JOB_NAME}/"

# Create the new directory
mkdir -p "$NEW_DIR"
[ -d ${DATA} ] || mkdir ${DATA}

# Load necessary modules
module reset
module load cpu/0.15.4
module load gcc
module load openmpi
module load fftw
module load intel-mkl
# module load castep # CASTEP is NOT installed on sdsc expanse. Used local castep mpi instead. 
#cp -R /home/${USER}/CASTEP-24.1/bin/linux_x86_64_gfortran10--mpi/ /expanse/lustre/scratch/${USER}/temp_project/CASTEP_24.1

export PATH="/expanse/lustre/scratch/${USER}/temp_project/CASTEP_25.1/linux_x86_64_gfortran10--mpi/:$PATH"
# Copy the CASTEP input files to the new directory
cp ${SLURM_JOB_NAME}* "$NEW_DIR"/ # change to your current working directory
cp ${SLURM_JOB_NAME}* ${DATA}

# Move to the new directory
cd "$NEW_DIR"

# Uncomment NMR, Comment GeoOpt
sed -i '0,/task : geometryoptimisation/s//#task : geometryoptimisation/' ${SLURM_JOB_NAME}.param
sed -i ':a;s/#task : magres/task : magres/g;ta' ${SLURM_JOB_NAME}.param
sed -i ':a;s/#magres_task : NMR/magres_task : NMR/g;ta' ${SLURM_JOB_NAME}.param

# Disable OpenMP multi-threading
export OMP_NUM_THREADS=1

#run castep script
mpirun -np 24 castep.mpi ${SLURM_JOB_NAME}

# Optional: Post-processing steps, if required
cp ${SLURM_JOB_NAME}.check ${DATA}
cp ${SLURM_JOB_NAME}.cst_esp ${DATA}
cp ${SLURM_JOB_NAME}.castep* ${DATA}
cp ${SLURM_JOB_NAME}-out.cif ${DATA}
cp ${SLURM_JOB_NAME}.magres ${DATA}

# Move back to the original directory
cd -
