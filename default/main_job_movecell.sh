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
#SBATCH --account= # Your Account Here
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

export PATH="/expanse/lustre/scratch/${USER}/temp_project/CASTEP_24.1/linux_x86_64_gfortran10--mpi/:$PATH"
cp ${SLURM_JOB_NAME}* "$NEW_DIR"/ # change to your current working directory
cp ${SLURM_JOB_NAME}* ${DATA}

# Move to the new directory
cd "$NEW_DIR"

# Disable OpenMP multi-threading
export OMP_NUM_THREADS=1

ELEMENT="Ti"            # <-- CHANGE THIS to the element for warpping!!
MAXIMUM_WARPX=0.06428   # <-- CHANGE THIS to the maximum warp (fraction of 0.25 angstrom)!!
MAXIMUM_WARPY=0.00000   # <-- CHANGE THIS to the maximum warp (fraction of 0.25 angstrom)!!
MAXIMUM_WARPZ=0.00000   # <-- CHANGE THIS to the maximum warp (fraction of 0.25 angstrom)!!

for i in {00..25..1} 
do
    WARPX=`echo "scale=7; ${MAXIMUM_WARPX} / 25 * $i" | bc -l` 
    WARPY=`echo "scale=7; ${MAXIMUM_WARPY} / 25 * $i" | bc -l` 
    WARPZ=`echo "scale=7; ${MAXIMUM_WARPZ} / 25 * $i" | bc -l` 
    sed -i 's/'${ELEMENT}'   0.\w\w\w\w\w\w\w0\+   0.\w\w\w\w\w\w\w0\+   0.\w\w\w\w\w\w\w0\+/'${ELEMENT}'   0'${WARPX}'00000000   0'${WARPY}'00000000   0'${WARPZ}'00000000/' ${SLURM_JOB_NAME}.cell
    mpirun -np 24 castep.mpi ${SLURM_JOB_NAME}
    # mpirun castep.mpi ${SLURM_JOB_NAME}
    rm ${SLURM_JOB_NAME}.check
    rm ${SLURM_JOB_NAME}.castep_bin
    rm ${SLURM_JOB_NAME}.cst_esp
    rm ${SLURM_JOB_NAME}.b*
    rm ${SLURM_JOB_NAME}.magres
    rm *.usp
done

# Optional: Post-processing steps
# cp ${SLURM_JOB_NAME}.check ${DATA} # May take hundreds of MB of space, not recommended for convergence test.
cp ${SLURM_JOB_NAME}.castep ${DATA} 
# cp ${SLURM_JOB_NAME}-out.cif ${DATA}
# cp ${SLURM_JOB_NAME}.magres ${DATA}

# Move back to the original directory
cd -
