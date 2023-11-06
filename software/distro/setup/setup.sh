#!/bin/bash -eu
# The software distro is the complete, finished, fully-function operating system
# for the PlanktoScope. The resulting image can be flashed to an SD card, inserted
# into a PlanktoScope, and booted up to make the PlanktoScope fully operational.
# This setup script assumes that the PlanktoScope Git repository has been
# downloaded to /home/pi/Planktoscope.
# TODO: don't assume that there is a PlanktoScope Git repo at /home/pi/PlanktoScope

# Determine the base path for sub-scripts

setup_scripts_root=$(dirname $(realpath $BASH_SOURCE))

# Get command-line args

hardware_type="$1" # should be either adafruithat or pscopehat

# Set up pretty error printing

red_fg=31
blue_fg=34
magenta_fg=35
bold=1

script_fmt="\e[${bold};${magenta_fg}m"
error_fmt="\e[${bold};${red_fg}m"
reset_fmt='\e[0m'

function report_starting {
  echo
  echo -e "${script_fmt}Starting: ${1}...${reset_fmt}"
}
function report_finished {
  echo
  echo -e "${script_fmt}Finished: ${1}!${reset_fmt}"
}
function panic {
  echo -e "${error_fmt}Error: couldn't ${1}${reset_fmt}"
  exit 1
}

# Run sub-scripts

echo -e "${script_fmt}Setting up full operating system...${reset_fmt}"

description="set up base operating system"
report_starting "$description"
if $setup_scripts_root/base-os/setup.sh ; then
  report_finished "$description"
  source $setup_scripts_root/base-os/export-env.sh
else
  panic "$description"
fi

description="set up PlanktoScope application environment"
report_starting "$description"
if $setup_scripts_root/planktoscope-app-env/setup.sh "$hardware_type" ; then
  report_finished "$description"
  source $setup_scripts_root/planktoscope-app-env/export-env.sh
else
  panic "$description"
fi