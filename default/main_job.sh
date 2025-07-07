#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH -t 24:00:00
#SBATCH --mem=80G
#SBATCH -o ../Data/mainjob_%j/out.%j
#SBATCH -e ../Data/mainjob_%j/err.%j
#SBATCH -J #DONT_MODIFY_THIS
#SBATCH -p shared
#SBATCH --constraint="lustre"
#SBATCH --account= #MODIFY_THIS
#SBATCH --export=ALL
#SBATCH --signal=B:USR1@180




#write DESCRIPTIVE notes here
notes=""





# email "${SLURM_JOB_NAME}_${SLURM_JOB_ID} geometry optimization and nmr params have started!\n"

# Create new scratch directory and add a variable for the new directory name
NEW_DIR="/expanse/lustre/scratch/${USER}/temp_project/castep/${SLURM_JOB_NAME}/${SLURM_JOB_NAME}_mainjob_${SLURM_JOB_ID}"
DATA=$(pwd)/../Data/mainjob_${SLURM_JOB_ID}/


# Create the new directory
mkdir -p "$NEW_DIR"
[ -d ${DATA} ] || mkdir -p ${DATA}


# Data Backup Function
data_backup() {
    echo Timed out at `date`
    # email "Job has timed out"
    cp ${SLURM_JOB_NAME}.{castep,check} ${DATA}/
    #copies cell and param into data folder
    cp ${DATA}/../../System/${SLURM_JOB_NAME}.{param,cell} ${DATA}/
    #copies and renamed orginal slurm script into data
    cp ${DATA}/../../System/main_job.sh ${DATA}/main_job_restarted.sh
    #adjusts paths accordingly
    sed -i 's/\.\/Data/\./g' ${DATA}/main_job_restarted.sh 
    #adds "restarted" to notes
    sed -i "s/notes=\"/notes=\"restarted\\n/" ${DATA}/main_job_restarted.sh 
    cp *.err ${DATA}
    exit 1
}
trap 'data_backup' USR1




# Load necessary modules
module reset
module load cpu/0.15.4
module load gcc
module load openmpi
module load fftw
module load intel-mkl


export PATH="/expanse/lustre/scratch/${USER}/temp_project/CASTEP_25.1/linux_x86_64_gfortran10--mpi/:$PATH"

# Copy the CASTEP input files to the new directory
cp ${SLURM_JOB_NAME}* "$NEW_DIR"/ # change to your current working directory
#cp ${SLURM_JOB_NAME}* ${DATA}


echo Cutoff energy: $(sed -n 's/cut_off_energy  *= *\(.*\)eV.*/\1/p' ${SLURM_JOB_NAME}.param) >> ${DATA}/notes.txt
echo Kpoint spacing: $(sed -n 's/kpoints_mp_spacing : *\(.*\)/\1/p' ${SLURM_JOB_NAME}.cell) >> ${DATA}/notes.txt
echo Functional:  $(sed -n 's/xc_functional : *\(.*\)/\1/p' ${SLURM_JOB_NAME}.param) >> ${DATA}/notes.txt
echo Geometric force tolerance: $(sed -n 's/GEOM_FORCE_TOL.*:\(.*\)#.*/\1/p' ${SLURM_JOB_NAME}.param) >> ${DATA}/notes.txt

echo Number of taks: $SLURM_NTASKS_PER_NODE >> ${DATA}/notes.txt
echo Memory: $(($SLURM_MEM_PER_NODE / 1000)) >> ${DATA}/notes.txt

echo -e ${notes} >> ${DATA}/notes.txt


# Move to the new directory
cd "$NEW_DIR"

#echo -e ${notes} >> notes.txt


# Uncomment GeoOpt, Comment NMR
sed -i ':a;s/#task : geometryoptimisation/task : geometryoptimisation/g;ta' ${SLURM_JOB_NAME}.param
sed -i '0,/task : magres/s//#task : magres/' ${SLURM_JOB_NAME}.param
sed -i '0,/magres_task : NMR/s//#magres_task : NMR/' ${SLURM_JOB_NAME}.param

# Disable OpenMP multi-threading
export OMP_NUM_THREADS=1

#run castep script - GeoOpt
counter=0
sed -i 's/GEOM_MAX_ITER        : \w\w\w/GEOM_MAX_ITER        : 004/' *.param
while ! grep -q 'LBFGS: Geometry optimization completed successfully.'  ${SLURM_JOB_NAME}.castep ; do
    echo loop $(( $counter + 1 )) starts at `date`
    
    #make random seed
    SEED=`shuf -i 1-100000000 -n 1`
    sed -i 's/[#]*RAND_SEED = .*/RAND_SEED = '$SEED'/' *.param
    echo Random Seed for this loop is $SEED

    if ! mpirun -np $SLURM_NTASKS_PER_NODE castep.mpi ${SLURM_JOB_NAME} ; then

        if grep -Fq "MPI_ABORT was invoked" ${DATA}/err.${SLURM_JOB_ID}; then 
            error_mssg="CASTEP"
        elif grep -Fq "signal 9 (Killed)" ${DATA}/err.${SLURM_JOB_ID}; then
            error_mssg="Out of memory"
        else
            error_mssg="Unknown"
        fi

        echo $error_mssg error at `date`
        email "$error_mssg error"

    fi &
    wait

    cp ${SLURM_JOB_NAME}.castep ${DATA}/

    if grep -Fq "error at" ${DATA}/out.${SLURM_JOB_ID}; then
        exit 1
    fi

    
    counter=$(( $counter + 1 ))
    if [ $counter -eq 6 ] ; then
        sed -i 's/GEOM_MAX_ITER        : \w\w\w/GEOM_MAX_ITER        : 010/' *.param
    else 
        if [ $counter -eq 10 ] ; then
            sed -i 's/GEOM_MAX_ITER        : \w\w\w/GEOM_MAX_ITER        : 200/' *.param
        else
            if [ $counter -eq 12 ] ; then
                break
            fi
        fi
    fi
done

#run castep script - NMR
if grep -q 'LBFGS: Geometry optimization completed successfully.'  ${SLURM_JOB_NAME}.castep
then
    echo GeoOpt finished. NMR calculation starts at `date`
    sed -i '0,/task : geometryoptimisation/s//#task : geometryoptimisation/' ${SLURM_JOB_NAME}.param
    sed -i ':a;s/#task : magres/task : magres/g;ta' ${SLURM_JOB_NAME}.param
    sed -i ':a;s/#magres_task : NMR/magres_task : NMR/g;ta' ${SLURM_JOB_NAME}.param
    mpirun -np $SLURM_NTASKS_PER_NODE castep.mpi ${SLURM_JOB_NAME}
    echo NMR calculation finished at `date`
else
    echo WARNING: GeoOpt may not be finished. NMR calculation NOT starting `date`
fi


# Optional: Post-processing steps, if required
#cp ${SLURM_JOB_NAME}.check ${DATA}
#cp ${SLURM_JOB_NAME}.cst_esp ${DATA}
cp ${SLURM_JOB_NAME}.castep ${DATA}
cp ${SLURM_JOB_NAME}-out.cif ${DATA}
cp ${SLURM_JOB_NAME}.magres ${DATA}
cp *.err ${DATA}


# Move back to the original directory
cd -

#email that the job has finished
# email "${SLURM_JOB_NAME}_${SLURM_JOB_ID} geometry optimization and nmr params has finished!\n"
echo Finished at `date`