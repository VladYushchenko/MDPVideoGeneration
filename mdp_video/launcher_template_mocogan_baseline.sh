# Training configuration for baseline mocogan model

DEVICE='0'
PYTHON_PATH='<path tp conda env>/bin/python'
PROJECT_FOLDER='<project folder>'
SCRIPT_NAME="$PROJECT_FOLDER"'/mdp_video/train.py'
DATASET='<dataset>'
OUT_FOLDER_BASE='<results folder>'

# Note: provide checkpoint to start training from it
# CHECKPOINT=''
MODEL_NAME='Baseline'
TRAINER_TYPE='vanilla_gan'
MODEL_GENERATOR='VideoGenerator'
MODEL_DISCRIMINATORS='PatchImageDiscriminator PatchVideoDiscriminator'
OPT_SUFFIX=''

# Model Flags
FULL_DETERMINISTIC=true
USE_NOISE=true
USE_CATEGORIES_GEN=false

# Model parameters
SEED=0
BATCH_SIZE=32
NOISE_SIGMA=0.1
PRINT_EVERY=1
SAVE_EVERY=10000
SHOW_DATA_INTERVAL=2000
NUM_WORKERS=4
SAMPLING_FREQUENCY=2
DIM_CONTENT=50
DIM_MOTION=10
DIM_CATEGORY=0
TRAINING_LENGTH=16
ITERATIONS=100000

# Trim to basename, then trim last underscore
DATASET_BASENAME=${DATASET##*/}
DATASET_BASENAME=${DATASET_BASENAME%_*}
echo "$DATASET_BASENAME"

# Check checkpoint name is unset
if [ -z ${CHECKPOINT+x} ]; then
    CHECKPOINT=''
fi

# Set suffixes
SUFFIX_CAT='_nocat'
if [ $DIM_CATEGORY -gt 0 ]; then
    SUFFIX_CAT='_cat'
fi

SUFFIX_DETER=''
if [ $FULL_DETERMINISTIC ]; then
    SUFFIX_DETER='_deterministic'
fi

SUFFIX_NOISE='_offnoise'
if [ $USE_NOISE ]; then
    SUFFIX_NOISE='_noise'
fi

# Construct output folder
OUT_FOLDER="$OUT_FOLDER_BASE"'/'"$DATASET_BASENAME""$SUFFIX_CAT"'/'"$MODEL_NAME""$SUFFIX_NOISE""$SUFFIX_DETER"/Seed_"$SEED""$OPT_SUFFIX"/TrainLength_"$TRAINING_LENGTH"/Batch_"$BATCH_SIZE"
mkdir -p "$OUT_FOLDER"

git --git-dir="$PROJECT_FOLDER"'/.git' --work-tree="$PROJECT_FOLDER" log -1 > "$OUT_FOLDER"'/CurrentRevision.out'
echo -e '\n##### DIFF to REVISION #####\n' >> "$OUT_FOLDER"'/CurrentRevision.out'
git --git-dir="$PROJECT_FOLDER"'/.git' --work-tree="$PROJECT_FOLDER" diff >> "$OUT_FOLDER"'/CurrentRevision.out'

get_parameters()
{
    local PARAM_CMD='--image_batch '"$BATCH_SIZE"
    PARAM_CMD="$PARAM_CMD"' --video_batch '"$BATCH_SIZE"
    PARAM_CMD="$PARAM_CMD"' --print_every '"$PRINT_EVERY"
    PARAM_CMD="$PARAM_CMD"' --save_every '"$SAVE_EVERY"
    PARAM_CMD="$PARAM_CMD"' --show_data_interval '"$SHOW_DATA_INTERVAL"
    PARAM_CMD="$PARAM_CMD"' --num_workers '"$NUM_WORKERS"
    PARAM_CMD="$PARAM_CMD"' --every_nth '"$SAMPLING_FREQUENCY"
    PARAM_CMD="$PARAM_CMD"' --dim_z_content '"$DIM_CONTENT"
    PARAM_CMD="$PARAM_CMD"' --dim_z_motion '"$DIM_MOTION"
    PARAM_CMD="$PARAM_CMD"' --dim_z_category '"$DIM_CATEGORY"
    PARAM_CMD="$PARAM_CMD"' --video_length '"$TRAINING_LENGTH"
    PARAM_CMD="$PARAM_CMD"' --trainer_type '"$TRAINER_TYPE"
    PARAM_CMD="$PARAM_CMD"' --n_iterations '"$ITERATIONS"
    PARAM_CMD="$PARAM_CMD"' --seed '"$SEED"
    PARAM_CMD="$PARAM_CMD"' --checkpoint "'"${CHECKPOINT}"'"'

    if [ $FULL_DETERMINISTIC ]; then
        PARAM_CMD="$PARAM_CMD"' --deterministic'
    fi

    if [ $USE_NOISE ]; then
        PARAM_CMD="$PARAM_CMD"' --use_noise --noise_sigma '"$NOISE_SIGMA"
    fi

    if [ $USE_CATEGORIES_GEN ]; then
        PARAM_CMD="$PARAM_CMD"' --use_infogan'
    fi

    echo "$PARAM_CMD"
}

PARAMETERS="$(get_parameters)"

CMD="CUDA_VISIBLE_DEVICES=${DEVICE} ${PYTHON_PATH} ${SCRIPT_NAME} ${PARAMETERS} --dataset ${DATASET} --log_folder ${OUT_FOLDER} --generator ${MODEL_GENERATOR} --discriminators ${MODEL_DISCRIMINATORS}"
echo "$CMD"
export PYTHONPATH=${PROJECT_FOLDER}
echo "$PYTHONPATH"
eval "$CMD"
wait
exit
