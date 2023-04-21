#!/bin/bash

# Resets the line
LINE_RESET='\e[2K\r'

# Terminal escape codes to color text
TEXT_GREEN='\e[032m'
TEXT_YELLOW='\e[33m'
TEXT_RED='\e[31m'
TEXT_RESET='\e[0m'

# Logs like systemd on startup, it's pretty
TEXT_INFO="[${TEXT_YELLOW}i${TEXT_RESET}]"
TEXT_FAIL="[${TEXT_RED}-${TEXT_RESET}]"
TEXT_SUCC="[${TEXT_GREEN}+${TEXT_RESET}]"

IMAGENAME="almalinux-bp-028-9.1-build:latest"

echo -n -e "${TEXT_INFO} Building the Docker build image"
docker build -t ${IMAGENAME} $(pwd)
if [ $? -ne 0 ]; then
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_FAIL} Couldn't build the docker image."
	exit 255
else
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_SUCC} Built the Docker build image"
fi

echo -n -e "${TEXT_INFO} Running the build inside the Docker build image"
echo ''
docker run -v $(pwd):/app ${IMAGENAME}
if [ $? -ne 0 ]; then
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_FAIL} Couldn't run the build in the Docker build image"
        exit 255
else
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_SUCC} Successfully built the ISO in the Docker build image"
fi
