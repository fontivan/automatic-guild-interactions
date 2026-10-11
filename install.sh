#!/usr/bin/env bash

# The current directory
DIR="$( cd "$( dirname "$0" )" && pwd )"

# The name of the addon
ADDON_NAME="automatic-guild-interactions"

# The path to the WoW addon directory you want to install to
WOW_ADDON_DIR="${1}"

# The local directory in this repository
LOCAL_ADDON_DIR="${DIR}"

# The addon directory inside the provided WoW addon folder
INSTALL_DIR="${WOW_ADDON_DIR}/${ADDON_NAME}"

# If the addon already exists then delete it
if [[ -d "${INSTALL_DIR}" ]]
then
    echo "Cleaning existing addon"
    rm -r "${INSTALL_DIR}"
fi

# Install the addon
echo "Installing addon"
mkdir -p "${INSTALL_DIR}"
cp "${LOCAL_ADDON_DIR}/${ADDON_NAME}.lua" "${INSTALL_DIR}"

TOC_FILES=(
    "_Mainline"
    "_Vanilla"
    "_Mists"
    "_Forever"
)

for TOC_FILE_SUFFIX in ${TOC_FILES[@]}; do
    cp "${LOCAL_ADDON_DIR}/${ADDON_NAME}${TOC_FILE_SUFFIX}.toc" "${INSTALL_DIR}"
done
