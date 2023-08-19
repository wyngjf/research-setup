#!/bin/bash

RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"
BLUE="\033[34m"
CYAN="\033[36m"
YELLOW="\e[0;33m"


export current_path=$(pwd)
export CONDA_ENV_NAME="py310_t2_cu118"

function draw_split_line() {
    local split_line_character="-"  # Default to '-'
    local text="${BLUE}${1:-}${YELLOW}"  # Default to empty string
    local terminal_width=$(tput cols)

    local split_line=""
    local text_start=$(( (terminal_width - ${#text}) / 2 ))
    for ((i=1; i<="$terminal_width"; i++)); do
        if [[ $i -ge $text_start && $i -lt $((text_start + ${#text})) ]]; then
            split_line="${split_line}${text}"
            ((i += ${#text} - 1))
        else
            split_line="${split_line}${split_line_character}"
        fi
    done

    echo -e "${YELLOW}$split_line${RESET}"
}


# Function to set or validate environment variables containing paths
function check_or_set_path_variable() {
    local var_name="$1"
    local default_path="$2"

    if [[ -n "${!var_name}" && -d "${!var_name}" ]]; then
        echo -e "${GREEN}Environment variable ${BLUE}$var_name ${GREEN}is set and valid.${RESET}"
    else
        echo -e "${RED}Environment variable ${BLUE}$var_name ${RED}is not set or not valid.${RESET}"
        read -p "Do you want to use the default path ($default_path)? [Y/n] " choice
        choice=${choice:-Y}  # Default to "Y" if user presses Enter without typing anything

        if [[ $choice =~ ^[Yy]$ ]]; then
            export "$var_name"="$default_path"
            echo -e "${GREEN}Using default path for ${BLUE}$var_name: ${CYAN}$default_path${RESET}"
            echo "export $var_name=$default_path" >> ~/.bashrc
        else
            read -p "Enter a new path for $var_name: " new_path
            if [[ ! -d "$new_path" ]]; then
                echo -e "${GREEN}Creating new path: ${BLUE}$new_path${RESET}"
                mkdir -p "$new_path"
            fi
            echo -e "${GREEN}Using new path for ${BLUE}$var_name: ${CYAN}$new_path${RESET}"
            export "$var_name"="$new_path"
            echo "export $var_name=$new_path" >> ~/.bashrc
        fi
    fi
}

draw_split_line " Setup Env Variables "
echo -e "${GREEN}specify path where you want to have robot-utils, robot-vision, and kvil package using PROJECT_PATH_CONTROL"
check_or_set_path_variable "PROJECT_PATH_CONTROL" "$HOME/projects/control/"
check_or_set_path_variable "PROJECT_PATH_VISION" "$HOME/projects/vision/"
check_or_set_path_variable "DEFAULT_DATASET_PATH" "$HOME/dataset"
check_or_set_path_variable "DEFAULT_CHECKPOINT_PATH" "$HOME/dataset/checkpoints"

draw_split_line " Setup Conda Env "
if conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo -e "${GREEN}Conda environment exists."
else
    echo "${GREEN}Creating and activating Conda environment."
    conda create -n "$CONDA_ENV_NAME" python=3.10
fi
conda activate "$CONDA_ENV_NAME"

python_path=$(which python)
echo -e "${GREEN}Python executable path: ${BLUE}$python_path${RESET}"
read -p $"Press ctrl+c to terminate. Enter to continue..."

draw_split_line " Install deps "
pip install numpy==1.23.1 fvcore
conda install -y pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia



draw_split_line " Install robot-utils "
cd "$PROJECT_PATH_CONTROL" || return
if [[ ! -d "$PROJECT_PATH_CONTROL/robot-utils" ]]; then
    echo -e "${BLUE}get robot-utils${RESET}"
    git clone git@git.h2t.iar.kit.edu:sw/machine-learning-control/robot-utils.git robot-utils
fi
echo -e "${BLUE}Installing robot-utils${RESET}"
cd "$PROJECT_PATH_CONTROL/robot-utils" || return
pip install -e .



draw_split_line " Install robot-vision "
cd "$PROJECT_PATH_CONTROL" || return
if [[ ! -d "$PROJECT_PATH_CONTROL/robot-vision" ]]; then
    echo -e "${BLUE}get robot-vision${RESET}"
    git clone git@git.h2t.iar.kit.edu:sw/machine-learning-control/robot-vision.git robot-vision
fi
echo -e "${BLUE}Installing robot-vision${RESET}"
cd "$PROJECT_PATH_CONTROL/robot-vision" || return
pip install -e .




draw_split_line " Install K-VIL "
echo -e "${BLUE}Installing K-VIL${RESET}"
cd "$PROJECT_PATH_CONTROL" || return
if [[ ! -d "$PROJECT_PATH_CONTROL/kvil" ]]; then
    echo -e "${BLUE}get kvil${RESET}"
    git clone git@git.h2t.iar.kit.edu:sw/machine-learning-control/visual-imitation-learning.git
fi
pip install --no-index --no-cache-dir pytorch3d -f https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py310_cu118_pyt201/download.html
cd "$PROJECT_PATH_CONTROL/kvil" || return
pip install -e .
draw_split_line " Done "
