#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH -t 12:00:00
#SBATCH --mem=80G
#SBATCH -o ../Data/kpointconv_%j/out.%j
#SBATCH -e ../Data/kpointconv_%j/err.%j
#SBATCH -J #DONT_MODIFY_THIS
#SBATCH -p shared
#SBATCH --constraint="lustre"
#SBATCH --account= #MODIFY_THIS
#SBATCH --export=ALL
#SBATCH --signal=B:USR1@180



#write DESCRIPTIVE notes here
notes=""








timeout(){
    echo Timed out at `date`
    email "Job has timed out"
    #copies timed out castep file and its check file into data
    cp ${SLURM_JOB_NAME}.{castep,check} ${DATA}/
    #copies original param and cell into data
    cp ${DATA}/../../System/${SLURM_JOB_NAME}.{param,cell} ${DATA}/
    #copies and renamed orginal slurm script into data
    cp ${DATA}/../../System/main_job_kpoint.sh ${DATA}/main_job_kpoint_restarted.sh
    #adjests paths accordingly
    sed -i 's/\.\/Data/\./g' ${DATA}/main_job_kpoint_restarted.sh 
    #changes starting cuttoff value to interupted value
    sed -i "s/for i in .\{1,\}${i}/for i in ${i}/" ${DATA}/main_job_kpoint_restarted.sh 
    #adds "restarted" to notes
    sed -i "s/notes=\"/notes=\"restarted\\n/" ${DATA}/main_job_kpoint_restarted.sh 
    cp *.err ${DATA}
    exit 1
}
trap 'timeout' USR1

# email "${SLURM_JOB_NAME}_kpointconv_${SLURM_JOB_ID} has started!\n"


# Create new scratch directory and add a variable for the new directory name
NEW_DIR="/expanse/lustre/scratch/${USER}/temp_project/castep/${SLURM_JOB_NAME}/${SLURM_JOB_NAME}_kpointconv_${SLURM_JOB_ID}"
#DATA="/home/${USER}/project/${SLURM_JOB_NAME}/"
DATA=$(pwd)/../Data/kpointconv_${SLURM_JOB_ID}/

# Create the new directory
mkdir -p "$NEW_DIR"
[ -d ${DATA} ] || mkdir -p ${DATA}

# Load necessary modules
module reset 
module load cpu/0.15.4 
module load gcc
module load openmpi
module load fftw
module load intel-mkl


export PATH="/expanse/lustre/scratch/${USER}/temp_project/CASTEP_25.1/linux_x86_64_gfortran10--mpi/:$PATH"

cp ${SLURM_JOB_NAME}* "$NEW_DIR"/ # change to your current working directory
#cp ${SLURM_JOB_NAME}* ${DATA}

cp "/home/${USER}/project/1cif2cellplus/convergence_plot.py" "$NEW_DIR"
cp "/home/${USER}/project/1cif2cellplus/convergence_plot.py" "$DATA"

echo Cutoff energy: $(sed -n 's/cut_off_energy  *= *\(.*\)eV.*/\1/p' ${SLURM_JOB_NAME}.param) >> ${DATA}/notes.txt
echo Functional:  $(sed -n 's/xc_functional : *\(.*\)/\1/p' ${SLURM_JOB_NAME}.param )>> ${DATA}/notes.txt
echo Number of taks: $SLURM_NTASKS_PER_NODE >> ${DATA}/notes.txt
echo Memory: $(($SLURM_MEM_PER_NODE / 1000)) >> ${DATA}/notes.txt

echo -e ${notes} >> ${DATA}/notes.txt

# Move to the new directory
cd "$NEW_DIR"

echo -e ${notes} >> notes.txt

# Disable OpenMP multi-threading
export OMP_NUM_THREADS=1

# Uncomment NMR, Comment GeoOpt
sed -i '0,/task : geometryoptimisation/s//#task : geometryoptimisation/' ${SLURM_JOB_NAME}.param
sed -i ':a;s/#task : magres/task : magres/g;ta' ${SLURM_JOB_NAME}.param
sed -i ':a;s/#magres_task : NMR/magres_task : NMR/g;ta' ${SLURM_JOB_NAME}.param



#for i in {10..04..-2} 
for i in 100 060 045 040
do
    echo Starting k-point spacing 0."$i" at `date`    
    sed -i 's/kpoints_mp_spacing : 0.[0-9]\+/kpoints_mp_spacing : 0.'$i'/' ${SLURM_JOB_NAME}.cell
    sed -i "s/comment = .*/comment = kpoint spacing: ${i} /" ${SLURM_JOB_NAME}.param
    
    if ! mpirun -np $SLURM_NTASKS_PER_NODE castep.mpi ${SLURM_JOB_NAME} ; then

        if grep -Fq "MPI_ABORT was invoked" ${DATA}/err.${SLURM_JOB_ID}; then 
            error_mssg="CASTEP"
        elif grep -Fq "signal 9 (Killed)" ${DATA}/err.${SLURM_JOB_ID}; then
            error_mssg="Out of memory"
        else
            error_mssg="Unknown"
        fi

        echo $error_mssg error at `date`
        # email "$error_mssg error"

    fi &
    wait

    if grep -Fq "error at" ${DATA}/out.${SLURM_JOB_ID}; then
        exit 1
    fi

    rm ${SLURM_JOB_NAME}.check
    rm ${SLURM_JOB_NAME}-out.cif
    rm ${SLURM_JOB_NAME}.castep_bin
    rm ${SLURM_JOB_NAME}.cst_esp
    rm ${SLURM_JOB_NAME}.b*
    rm ${SLURM_JOB_NAME}.magres
    rm *.usp

    cp ${SLURM_JOB_NAME}.castep ${DATA}/

done

#cp ${SLURM_JOB_NAME}.castep ${DATA}/
#cp "/home/${USER}/project/1cif2cellplus/convergence_plot.py" ${DATA}
cp *.err ${DATA}

# Move back to the original directory
cd -

#email that the job has finished
# email "${SLURM_JOB_NAME}_kpointconv_${SLURM_JOB_ID} has finished\n"
echo Finished at `date`