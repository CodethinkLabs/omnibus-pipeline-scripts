#!/bin/bash

set -e

usage() {
  cat <<EOF
  usage: $0
  mandatory options:  -a ARTIFACTS_DIR
                      -n REPOSITORY_NAME
                      -g GIT_REF
                      -u REMOTE_USER
                      -i REMOTE_IP
                      -t REMOTE_DEST_DIR
                      [-r]
  This script creates an appropriately named directory
  with artifacts and deploys it to a provided deployment
  server.
  If -r is present, release version of deployment is performed,
  otherwise build version.
EOF
}

send_dir() {
  scp_src="$isolate_dir"
  remote_host="$remote_user@$remote_ip"
  remote_dest="$remote_dest_dir"
  scp_dest="$remote_host:$remote_dest"

  echo -e "\n- Sending dir to deployment server"
  echo -e "  src: $scp_src"
  echo -e "  dest: $scp_dest"
  scp -r "$scp_src"/* "$scp_dest"
}

rename_dir() {
  deployment_dir_name=""
  if [[ -z "$release_version" ]]; then
    deployment_dir_name="$repository_name""_build_""$git_ref"
  else
    deployment_dir_name="$repository_name""_""$git_ref"
  fi

  temp_deployment_parent_dir="$(dirname "$temp_deployment_dir")"
  deployment_dir="$temp_deployment_parent_dir/$deployment_dir_name"

  echo -e "\n- Renaming deployment directory"
  echo -e "  old: $temp_deployment_dir"
  echo -e "  new: $deployment_dir"
  mv "$temp_deployment_dir" "$deployment_dir"
}

create_dir_with_artifacts() {
  isolate_dir="$(mktemp -d)"
  temp_deployment_dir="$isolate_dir/$repository_name/$deployment_version/deployment_artifacts"

  mkdir -p "$temp_deployment_dir"

  echo -e "\n- Copying artifacts"
  echo -e "  src:$artifacts_dir/*"
  echo -e "  dest:$temp_deployment_dir"
  cp -r "$artifacts_dir"/* "$temp_deployment_dir"
}

deploy() {
  create_dir_with_artifacts
  rename_dir
  send_dir
}

main() {
  artifacts_dir=""
  repository_name=""
  git_ref=""
  remote_user=""
  remote_ip=""
  remote_dest_dir=""
  release_version=""
  while getopts "ha:n:g:u:i:t:r" option; do
    case "$option" in
      h)
        usage; exit 0
        ;;
      a)
        artifacts_dir="$OPTARG"
        ;;
      n)
        repository_name="$OPTARG"
        ;;
      g)
        git_ref="$OPTARG"
        ;;
      u)
        remote_user="$OPTARG"
        ;;
      i)
        remote_ip="$OPTARG"
        ;;
      t)
        remote_dest_dir="$OPTARG"
        ;;
      r)
        release_version="yes"
        ;;
    esac
  done

  if [[ -z "$artifacts_dir" || ! -d "$artifacts_dir" ]]; then
    echo -e "ERROR: ARTIFACTS_DIR is mandatory and must be a directory\n"
    usage; exit 1
  fi

  if [[ -z "$repository_name" ]]; then
    echo -e "ERROR: REPOSITORY_NAME is mandatory\n"
    usage; exit 1
  fi

  if [[ -z "$git_ref" ]]; then
    echo -e "ERROR: GIT_REF is mandatory\n"
    usage; exit 1
  fi

  if [[ -z "$remote_user" ]]; then
    echo -e "ERROR: REMOTE_USER is mandatory\n"
    usage; exit 1
  fi

  if [[ -z "$remote_ip" ]]; then
    echo -e "ERROR: REMOTE_IP is mandatory\n"
    usage; exit 1
  fi

  if [[ -z "$remote_dest_dir" ]]; then
    echo -e "ERROR: REMOTE_DEST_DIR is mandatory\n"
    usage; exit 1
  fi

  deployment_version=""
  if [[ -z "$release_version" ]]; then
    deployment_version="build"
  else
    deployment_version="release"
  fi
  echo -e "\n Deployment version: $deployment_version"

  deploy
}

main "$@"
