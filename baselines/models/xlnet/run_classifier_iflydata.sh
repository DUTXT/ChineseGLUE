#!/usr/bin/env bash
# @Author: bo.shi
# @Date:   2019-11-04 09:56:36
# @Last Modified by:   bo.shi
# @Last Modified time: 2019-11-10 13:38:33

TASK_NAME="iflydata"
MODEL_NAME="chinese_xlnet_mid_L-24_H-768_A-12"
CURRENT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
export CUDA_VISIBLE_DEVICES="0"
export PRETRAINED_MODELS_DIR=$CURRENT_DIR/prev_trained_model
export XLNET_DIR=$PRETRAINED_MODELS_DIR/$MODEL_NAME
export GLUE_DATA_DIR=$CURRENT_DIR/../../glue/chineseGLUEdatasets

# install related packages
pip install sentencepiece --user

# download and unzip dataset
if [ ! -d $GLUE_DATA_DIR ]; then
  mkdir -p $GLUE_DATA_DIR
  echo "makedir $GLUE_DATA_DIR"
fi
cd $GLUE_DATA_DIR
if [ ! -d $TASK_NAME ]; then
  mkdir $TASK_NAME
  echo "makedir $GLUE_DATA_DIR/$TASK_NAME"
fi
cd $TASK_NAME
if [ ! -f "train.txt" ] || [ ! -f "dev.txt" ] || [ ! -f "test.txt" ]; then
  rm *
  wget https://storage.googleapis.com/chineseglue/tasks/iflytek.zip
  unzip iflytek.zip
  rm iflytek.zip
else
  echo "data exists"
fi
echo "Finish download dataset."

# download model
if [ ! -d $XLNET_DIR ]; then
  mkdir -p $XLNET_DIR
  echo "makedir $XLNET_DIR"
fi
cd $XLNET_DIR
if [ ! -f "xlnet_config.json" ] || [ ! -f "spiece.model" ] || [ ! -f "xlnet_model.ckpt.index" ] || [ ! -f "xlnet_model.ckpt.meta" ] || [ ! -f "xlnet_model.ckpt.data-00000-of-00001" ]; then
  rm *
  wget --header="Host: doc-0o-c4-docs.googleusercontent.com" --header="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3" --header="Accept-Language: zh-CN,zh;q=0.9" --header="Referer: https://drive.google.com/uc?id=1342uBc7ZmQwV6Hm6eUIN_OnBSz1LcvfA&export=download" "https://doc-0o-c4-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/v6cf02qggu69e2tquf493h65atrh5a1b/1573358400000/05961793937965181111/*/1342uBc7ZmQwV6Hm6eUIN_OnBSz1LcvfA?e=download" -O "chinese_xlnet_mid_L-24_H-768_A-12.zip" -c
  unzip chinese_xlnet_mid_L-24_H-768_A-12.zip
  rm chinese_xlnet_mid_L-24_H-768_A-12.zip
else
  echo "model exists"
fi
echo "Finish download model."

# run task
cd $CURRENT_DIR
echo "Start running..."
python run_classifier.py \
    --spiece_model_file=${XLNET_DIR}/spiece.model \
    --model_config_path=${XLNET_DIR}/xlnet_config.json \
    --init_checkpoint=${XLNET_DIR}/xlnet_model.ckpt \
    --task_name=$TASK_NAME \
    --do_train=True \
    --do_eval=True \
    --eval_all_ckpt=False \
    --uncased=False \
    --data_dir=$GLUE_DATA_DIR/$TASK_NAME \
    --output_dir=$CURRENT_DIR/${TASK_NAME}_output/ \
    --model_dir=$CURRENT_DIR/${TASK_NAME}_output/ \
    --train_batch_size=32 \
    --eval_batch_size=8 \
    --num_hosts=1 \
    --num_core_per_host=1 \
    --num_train_epochs=3 \
    --max_seq_length=128 \
    --learning_rate=2e-5 \
    --save_steps=1000 \
    --use_tpu=False
