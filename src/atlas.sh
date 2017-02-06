#!/usr/bin/env bash

# define basic shell options
# set -x  # print trace of simple commands
# set -v  # print shell input lines as they are read
set -e    # stop script when command fails
set -u    # stop script on use undeclared variable
set -f    # disable filename expansion globbing

# define magic variables
declare -r     G_SCRIPT_NAME=$(basename "${0}")
declare        G_BOX_SOURCE_PATH=""
declare        G_REPO_PATH=""
declare -r     G_BOX_SUFFIX=".box"
declare -r -i  G_SUCCESS=0
declare -r -i  G_NO_ARGS=84
declare -r -i  G_BAD_ARGS=85
declare -r -i  G_MISSING_ARGS=86

# define settings
declare -r     G_PATH="/var/www/atlas.com/public_html/vagrant/"
declare -r     G_URL="http://atlas.com/vagrant/boxes/"
declare -r -i  G_MAX_BOXES=3
declare -r     G_BOX_OWNER="lupin"

# program functions
function error_no_args()
{
  printf "[Error] no arguments supplied\n"
  exit "${G_NO_ARGS}"
}

function error_bad_args()
{
  printf "[Error] wrong arguments supplied\n"
  exit "${G_BAD_ARGS}"
}

function error_missing_args()
{
  printf "[Error] missing arguments: \"%s\"\n" "${1}"
  exit "${G_MISSING_ARGS}"
}

function error_no_file()
{
  printf "[Error] %s is not an valid file\n" "${1}"
  exit "${G_BAD_ARGS}"
}

function show_help()
{
  printf "Usage: %s" "${G_SCRIPT_NAME}"
  printf " -b <box> [-h]\n"
}

function generate_repo_file()
{
  # define local vars
  local L_BOX_NAME=$(basename "${G_BOX_SOURCE_PATH}")
  local L_PATH="${1}"
  local L_CURRENT=($(ls $G_REPO_PATH))
  local L_STRING=""
  local L_COUNT=0

  # create json content
  L_STRING+="{\n"
  L_STRING+="\t\"name\": \"${G_BOX_OWNER}/$(basename "${G_REPO_PATH}")\",\n"
  L_STRING+="\t\"versions\": [{\n"
  for i in "${L_CURRENT[@]}"; do
    # define function vars
    F_BASE_NAME=$(basename "${i}")
    F_REPOSITORY=$(basename "${G_REPO_PATH}")
    F_SHA1_FILE_SUM=$(sha1sum "${G_REPO_PATH}/${i}" | awk '{print $1}')
    F_PREFIX="${F_REPOSITORY}_"
    F_VERSION="${i%$G_BOX_SUFFIX}"
    F_VERSION="${F_VERSION#$F_PREFIX}"

    L_STRING+="\t\t\"version\": \"${F_VERSION}\",\n"
    L_STRING+="\t\t\"providers\": [{\n"
    L_STRING+="\t\t\t\"name\": \"virtualbox\",\n"
    L_STRING+="\t\t\t\"url\": \"${G_URL}${F_REPOSITORY}/${F_BASE_NAME}\",\n"
    L_STRING+="\t\t\t\"checksum_type\": \"sha1\",\n"
    L_STRING+="\t\t\t\"checksum\": \"${F_SHA1_FILE_SUM}\"\n"
    L_STRING+="\t\t}]\n"

    L_COUNT=$((L_COUNT+1))
    if [ ${L_COUNT} -lt ${#L_CURRENT[@]} ]; then
      L_STRING+="\t},{\n"
    fi
  done
  L_STRING+="\t}]\n"
  L_STRING+="}\n"

  # output to stdout and file
  echo -e "${L_STRING}" | tee "${L_PATH}"
}

function main()
{
  # define local vars
  local L_BOX_NAME=$(basename "${G_BOX_SOURCE_PATH}")
  local L_REPO_NAME="${L_BOX_NAME%$G_BOX_SUFFIX}"
  local G_REPO_PATH="${G_PATH}boxes/${L_REPO_NAME}"
  local L_REPO_FILE="${L_REPO_NAME}.json"

  # print start summary
  printf "=%.0s" {0..80}
  printf "\n"
  printf "[INFO] start versioning for: \t\t%s\n" "${L_BOX_NAME}"

  # print box repository info
  if [ ! -d "${G_REPO_PATH}" ]; then
    printf "[INFO] create new repository: \t\t%s\n" "${L_REPO_NAME}"
    mkdir -p -m 0755 "${G_REPO_PATH}"
  else
    printf "[INFO] use existing repository: \t%s\n" "${L_REPO_NAME}"
  fi

  # print number of existing boxes for repository
  if [ -d "${G_REPO_PATH}" ]; then
    L_BOX_AMOUNT=($(ls "$G_REPO_PATH"))
    printf "[INFO] vagrant boxes found: \t\t%d\n" "${#L_BOX_AMOUNT[@]}"
  fi

  # print new target name for vagrant box
  L_TARGET_NAME="${L_REPO_NAME}_$(date +%s)${G_BOX_SUFFIX}"
  printf "[INFO] renamed new box to: \t\t%s\n" "${L_TARGET_NAME}"

  # print copy box into repository
  printf "[INFO] copy box into repository\n"
  cp "${G_BOX_SOURCE_PATH}" "${G_REPO_PATH}/${L_TARGET_NAME}"

  # print delete box action
  if [ "${#L_BOX_AMOUNT[@]}" -eq "${G_MAX_BOXES}" ]; then
    printf "[INFO] remove unused box: \t\t%s\n" "${L_BOX_AMOUNT[0]}"
    rm -f "${G_REPO_PATH}/${L_BOX_AMOUNT[0]}"
  fi

  # print JSON file status
  printf "[INFO] generate repository file: \t%s\n\n" "${L_REPO_FILE}"
  if [ -e "${G_PATH}${L_REPO_FILE}" ]; then
    rm -f "${G_PATH}${L_REPO_FILE}"
  fi
  generate_repo_file "${G_PATH}${L_REPO_FILE}"


  # print finish
  printf "[INFO] process successful\n"
  printf "=%.0s" {0..80}
  printf "\n"
}

# check script arguments
if [ "${#}" -eq 0 ]; then
  error_no_args
fi

while getopts "hb:" G_OPTS; do
  case "${G_OPTS}" in
    h)
       show_help
       exit "${G_SUCCESS}";;
    b)
       G_BOX_SOURCE_PATH="${OPTARG}";;
    ?)
       error_bad_args
       show_help;;
  esac
done

if [ -z "${G_BOX_SOURCE_PATH}" ]; then
  error_missing_args "-b <box>"
fi

if [ ! -e "${G_BOX_SOURCE_PATH}" ] || [ ! -f "${G_BOX_SOURCE_PATH}" ]; then
  error_no_file "${G_BOX_SOURCE_PATH}"
fi

# call default function flow
main

# script exit
exit "${G_SUCCESS}"
