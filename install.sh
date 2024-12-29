#!/bin/bash

TMP_DIR=/tmp/aca
VARS_FILE="$TMP_DIR/common/vars/main.yml"

NO_AMDGPU=false
NO_NVIDIA=false
NO_GPU=false
NO_APPS=false
ONLY_CORE=false

packages=("git" "python" "ansible")

for package in "${packages[@]}"; do
    if ! pacman -Qi "$package" > /dev/null; then
        echo "Installing $package..."
        sudo pacman -S --noconfirm "$package"
    else
        echo "=> $package already installed."
    fi
done

git clone https://github.com/odevsa/aca.git $TMP_DIR

for arg in "$@"; do
    case $arg in
        --no-amdgpu)
            NO_AMDGPU=true
            ;;
        --no-nvidia)
            NO_NVIDIA=true
            ;;
        --no-gpu)
            NO_GPU=true
            ;;
        --no-apps)
            NO_APPS=true
            ;;
        --only-core)
            ONLY_CORE=true
            ;;
        *)
            echo "Unknown option: $arg"
            ;;
    esac
done

update_yaml_block_value() {
    local block="$1"
    local key="$2"
    local value="$3"
    local file="$4"
    sed -i -E "/^${block}:/,/^(\S|$)/ s/(${key}:).*/\1 ${value}/" "$file"
}

if [ "$NO_AMDGPU" = true ] || [ "$NO_GPU" = true ] || [ "$ONLY_CORE" = true ]; then
    update_yaml_block_value "amdgpu" "install" "false" "$VARS_FILE"
fi

if [ "$NO_NVIDIA" = true ] || [ "$NO_GPU" = true ] || [ "$ONLY_CORE" = true ]; then
    update_yaml_block_value "nvidia" "install" "false" "$VARS_FILE"
fi

if [ "$ONLY_CORE" = true ] || [ "$NO_APPS" = true ]; then
    update_yaml_block_value "application" "development" "false" "$VARS_FILE"
    update_yaml_block_value "application" "graphical" "false" "$VARS_FILE"
    update_yaml_block_value "application" "multimedia" "false" "$VARS_FILE"
    update_yaml_block_value "application" "three_dimensional" "false" "$VARS_FILE"
fi

(cd $TMP_DIR && ansible-playbook --ask-become-pass main.yml)