#!/bin/bash

START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "InterviewPad Deployment Script | START: ($START_TIME)"

# Setup our swap / container variables. First, check and see which image is current (1 or 2).
if docker images | grep -q "ipapp_swap_image_1"; then
    CURRENT_SWAP_IMAGE="ipapp_swap_image_1"
    CURRENT_SWAP_CONT="ipapp_swap_cont_1"
    NEXT_SWAP_IMAGE="ipapp_swap_image_2"
    NEXT_SWAP_CONT="ipapp_swap_cont_2"
else
    CURRENT_SWAP_IMAGE="ipapp_swap_image_2"
    CURRENT_SWAP_CONT="ipapp_swap_cont_2"
    NEXT_SWAP_IMAGE="ipapp_swap_image_1"
    NEXT_SWAP_CONT="ipapp_swap_cont_1"
fi
echo ""
echo "current swap image:     $CURRENT_SWAP_IMAGE"
echo "current swap container: $CURRENT_SWAP_CONT"
echo ""
echo "next swap image:        $NEXT_SWAP_IMAGE"
echo "next swap container:    $NEXT_SWAP_CONT"
echo ""

# No-op function to print a message when we don't need to deploy
function noChangeNeeded {
    echo "InterviewPad deployment up-to-date, current HEAD:"
    git log -1
}

# Function that carries out an actual deployment if needed
function update {
    echo "InterviewPad deployment needed, starting..."
    echo "current HEAD:"
    git log -1
    git pull
    echo "new HEAD:"
    git log -1

    # Go back to user's home folder (where Dockerfile is located)
    cd ~

    echo ""
    echo "building next swap image: $NEXT_SWAP_IMAGE"
    echo ""
    docker build -t $NEXT_SWAP_IMAGE .

    echo ""
    echo "stopping current container: $CURRENT_SWAP_CONT"
    echo ""
    docker stop $CURRENT_SWAP_CONT

    echo ""
    echo "running next image: $NEXT_SWAP_IMAGE in container: $NEXT_SWAP_CONT"
    echo ""
    docker run --name $NEXT_SWAP_CONT -p 80:80 -i -d -t $NEXT_SWAP_IMAGE

    echo ""
    echo "cleaning up previous swap container: $CURRENT_SWAP_CONT"
    echo ""
    docker rm $CURRENT_SWAP_CONT

    echo ""
    echo "cleaning up previous swap image: $CURRENT_SWAP_IMAGE"
    echo ""
    docker rmi $CURRENT_SWAP_IMAGE
}

# Change to the app locally cloned repo's folder
cd ~/ip_app/

# Check to see if we're in sync with remote master
git fetch origin
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ $LOCAL = $REMOTE ]; then
    noChangeNeeded
elif [ $LOCAL = $BASE ]; then
    update
elif [ $REMOTE = $BASE ]; then
    echo "ERROR: InterviewPad local change on server detected"
else
    echo "ERROR: InterviewPad repo diverged"
fi

cd ~

END_TIME=$(date "+%Y-%m-%d %H:%M:%S")
echo ""
echo "InterviewPad Deployment Script | END: ($END_TIME)"