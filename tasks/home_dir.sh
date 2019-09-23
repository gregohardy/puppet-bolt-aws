#!/bin/bash

real_home=''

if [ -n "${HOME}" ];then
  real_home="${HOME}"
fi

if [ -n "${HOMEPATH}" ];then
  real_home="${HOMEPATH}"
fi

if [ -z "${real_home}" ];then
  echo "env HOME or HOPEPATH are not set"
  exit 2
fi

if [ ! -d "${real_home}/.puppetlabs/bolt/modules" ];then
  mkdir -p "${real_home}/.puppetlabs/bolt/modules"
fi

echo -n "$(pwd)"