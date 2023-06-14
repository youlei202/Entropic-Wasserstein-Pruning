##### instructions ####
# first generate commands via `bash filename> > commands.txt` and then execute `bash commands.txt`
#######################

#!/bin/bash

#TARGET_SPARSITYS=(0.2 0.4 0.6 0.7 0.8 0.9 0.1 0.3 0.5 0.98)
TARGET_SPARSITYS=(0.7)
MODULES=("layer1.0.conv1_layer1.0.conv2_layer1.1.conv1_layer1.1.conv2_layer1.2.conv1_layer1.2.conv2_layer2.0.conv1_layer2.0.conv2_layer2.1.conv1_layer2.1.conv2_layer2.2.conv1_layer2.2.conv2_layer3.0.conv1_layer3.0.conv2_layer3.1.conv1_layer3.1.conv2_layer3.2.conv1_layer3.2.conv2")

#SEEDS=(0 1 2)
SEEDS=(0)
FISHER_SUBSAMPLE_SIZES=(1000)
#PRUNERS=(woodfisherblock globalmagni magni diagfisher)
PRUNERS=(optimal_transport)
JOINTS=(1)
FISHER_DAMP="1e-5"
EPOCH_END="10"
PROPER_FLAG="1"
ROOT_DIR="/zhome/b2/8/197929/GitHub/CBS"
DATA_DIR="/zhome/b2/8/197929/GitHub/CBS/datasets"
SWEEP_NAME="exp_oct_21_resnet20_all_rep"
NOWDATE=""
DQT='"'
GPUS=(2 3)
LOG_DIR="${ROOT_DIR}/prob_regressor_results/${SWEEP_NAME}/log/"
CSV_DIR="${ROOT_DIR}/prob_regressor_results/${SWEEP_NAME}/csv/"
mkdir -p ${LOG_DIR}
mkdir -p ${CSV_DIR}
# ONE_SHOT="--one-shot"
#CKP_PATH="${ROOT_DIR}/checkpoints/resnet20_cifar10.pth.tar"
CKP_PATH="${ROOT_DIR}/../exp_root/exp_oct_21_resnet20_all_rep/20211026_18-55-28_694095_239/regular_checkpoint.ckpt"

# OPTIMAL_TRANSPORTATION="--ot"
extra_cmd=" ${OPTIMAL_TRANSPORTATION}  "

ID=0

for PRUNER in "${PRUNERS[@]}"
do
    for JOINT in "${JOINTS[@]}"
    do
        if [ "${JOINT}" = "0" ]; then
            JOINT_FLAG=""
        elif [ "${JOINT}" = "1" ]; then
            JOINT_FLAG="--woodburry-joint-sparsify"
        fi

        for SEED in "${SEEDS[@]}"
        do
            for MODULE in "${MODULES[@]}"
            do
                for TARGET_SPARSITY in "${TARGET_SPARSITYS[@]}"
                do
                    for FISHER_SUBSAMPLE_SIZE in "${FISHER_SUBSAMPLE_SIZES[@]}"
                    do
                        if [ "${FISHER_SUBSAMPLE_SIZE}" = 80 ]; then
                            FISHER_MINIBSZS=(1)
                        elif [ "${FISHER_SUBSAMPLE_SIZE}" = 1000 ]; then
                            #FISHER_MINIBSZS=(1 50)
                            FISHER_MINIBSZS=(1)
                        elif [ "${FISHER_SUBSAMPLE_SIZE}" = 4000 ]; then
                            FISHER_MINIBSZS=(1)
                        elif [ "${FISHER_SUBSAMPLE_SIZE}" = 5000 ]; then
                            FISHER_MINIBSZS=(1)
                        elif [ "${FISHER_SUBSAMPLE_SIZE}" = 8000 ]; then
                            FISHER_MINIBSZS=(10)
                        fi

                        for FISHER_MINIBSZ in "${FISHER_MINIBSZS[@]}"
                        do


                            CUDA_VISIBLE_DEVICES=${GPUS[$((${ID} % ${#GPUS[@]}))]} python3 ${ROOT_DIR}/main.py --exp_name=${SWEEP_NAME}  --dset=cifar10 --dset_path=${DATA_DIR} --arch=resnet20 --config_path=${ROOT_DIR}/configs/resnet20_optimal_transport.yaml --workers=1 --batch_size=64 --logging_level debug --gpus=0 --from_checkpoint_path=${CKP_PATH} --batched-test --not-oldfashioned --disable-log-soft --use-model-config --sweep-id ${ID} --fisher-damp ${FISHER_DAMP} --prune-modules ${MODULE} --fisher-subsample-size ${FISHER_SUBSAMPLE_SIZE} --fisher-mini-bsz ${FISHER_MINIBSZ} --update-config --prune-class ${PRUNER} --target-sparsity ${TARGET_SPARSITY} --prune-end ${EPOCH_END} --prune-freq ${EPOCH_END} --result-file ${CSV_DIR}/prune_module-woodfisher-based_all_epoch_end-${EPOCH_END}.csv --seed ${SEED} --deterministic --full-subsample ${JOINT_FLAG} --fisher-optimized --fisher-parts 5 --offload-grads --offload-inv $extra_cmd 
                            #CUDA_VISIBLE_DEVICES=${GPUS[$((${ID} % ${#GPUS[@]}))]} python3 ${ROOT_DIR}/main.py --exp_name=${SWEEP_NAME}  --dset=cifar10 --dset_path=${DATA_DIR} --arch=resnet20 --config_path=${ROOT_DIR}/configs/resnet20_woodfisher.yaml --workers=1 --batch_size=64 --logging_level debug --gpus=0 --from_checkpoint_path=${CKP_PATH} --batched-test --not-oldfashioned --disable-log-soft --use-model-config --sweep-id ${ID} --fisher-damp ${FISHER_DAMP} --prune-modules ${MODULE} --fisher-subsample-size ${FISHER_SUBSAMPLE_SIZE} --fisher-mini-bsz ${FISHER_MINIBSZ} --update-config --prune-class ${PRUNER} --target-sparsity ${TARGET_SPARSITY} --prune-end ${EPOCH_END} --prune-freq ${EPOCH_END} --result-file ${CSV_DIR}/prune_module-woodfisher-based_all_epoch_end-${EPOCH_END}.csv --seed ${SEED} --deterministic --full-subsample ${JOINT_FLAG} --fisher-optimized --fisher-parts 5 --offload-grads --offload-inv $extra_cmd &> ${LOG_DIR}/${PRUNER}_proper-1_joint-${JOINT}_module-all_target_sp-${TARGET_SPARSITY}_epoch_end-${EPOCH_END}_samples-${FISHER_SUBSAMPLE_SIZE}_${FISHER_MINIBSZ}_damp-${FISHER_DAMP}_seed-${SEED}.txt

                            ID=$((ID+1))

                        done
                    done
                done
            done
        done
    done
done