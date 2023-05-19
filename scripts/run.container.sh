#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 version"
  exit 1
fi

set -e -o pipefail

REPOSITORY="unlimitedrobotics"
ENVIRONMENT_VERSION=$1

if docker info | grep 'Runtimes:' | grep -q 'nvidia'; then
    WITH_GPU='true'
    GPU_FLAGS=(
        --gpus=all
        -e NVIDIA_VISIBLE_DEVICES=all
        -e NVIDIA_DRIVER_CAPABILITIES=all
    )
    IMAGE="raya_os.sim_gpu"
else
    WITH_GPU='false'
    GPU_FLAGS=()
    IMAGE="raya_os.sim"
fi

xhost +local:root >> /dev/null

UR_DEV_PATH=$(realpath ${ENVIRONMENT_PATH}/..)
UR_SIM_PATH=${HOME}/.ur/simulator
UR_ROOT_PATH=${UR_SIM_PATH}/ur_root

# Volumes to blind inside container
SYS_VOL=(
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro
    -v /var/run/pulse/native:/var/run/pulse/native
    -v /run/user/$UID/pulse:/run/user/1000/pulse
    -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie
    -v /var/run/dbus:/var/run/dbus 
    -v ${XAUTHORITY}:/root/.Xauthority
)

PORTS=(--network host)

# Environment variables to container
ENV_VAR=(
    -e DISPLAY=$DISPLAY
    -e QT_X11_NO_MITSHM=1
    -e PULSE_SERVER=unix:/run/user/1000/pulse/native
    -e PULSE_COOKIE=/root/.config/pulse/cookie
    -e MOZ_WEBRENDER=0
    -e MOZ_ACCELERATED=0
)

RAYA_VOL+=(
    -v ${UR_ROOT_PATH}/config:/opt/raya_os/config:ro
    -v ${UR_SIM_PATH}/apps:/opt/raya_os/rayadevel/apps:ro
    -v ${UR_SIM_PATH}/apps:/opt/raya_os/apps
    -v ${UR_ROOT_PATH}/data:/opt/raya_os/data
    -v ${UR_ROOT_PATH}/notebooks:/opt/raya_os/notebooks
    -v ${UR_SIM_PATH}/data_apps:/opt/raya_os/data_apps
    -v ${UR_SIM_PATH}/data_apps_devel:/opt/raya_os/data_apps_devel
)

docker run -it \
    --rm \
    --privileged \
    "${GPU_FLAGS[@]}" \
    "${PORTS[@]}" \
    "${SYS_VOL[@]}" \
    "${ENV_VAR[@]}" \
    "${RAYA_VOL[@]}" \
    --tty \
    --name raya_os \
    --env-file ${UR_ROOT_PATH}/env \
    ${REPOSITORY}/${IMAGE}.prod:${ENVIRONMENT_VERSION}
