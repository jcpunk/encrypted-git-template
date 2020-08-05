#!/bin/bash

TOPDIR='../'
MYDIR=$(dirname $0)
if [[ ${MYDIR} != '.' ]]; then
  TOPDIR=`pwd`
fi

if [[ "x${1}" == 'x' ]]; then
  ENCRYPTED_DIR="${TOPDIR}/ENCRYPTED_DATA/"
  UNENCRYPTED_DIR="${TOPDIR}/unencrypted/"
else
  ENCRYPTED_DIR="${1}"
fi

if [[ "x${2}" == 'x' ]]; then
  UNENCRYPTED_DIR="${TOPDIR}/unencrypted/"
else
  UNENCRYPTED_DIR="${2}"
fi

if [[ ! -d ${ENCRYPTED_DIR} ]]; then
  echo "No such directory ${ENCRYPTED_DIR}" >&2
  exit 1
fi

ECRYPTFS_OPTIONS='ecryptfs_cipher=aes,ecryptfs_key_bytes=32,ecryptfs_unlink_sigs'

# Read in the passphrase with echo off from either user or stdin
stty -echo >/dev/null 2>&1
printf "Passphrase: " 1>&2
while read PASSPHRASE; do
break;
done < /dev/stdin
stty echo >/dev/null 2>&1

# unlock keys
if [[ -s ${TOPDIR}/.wrapped-data-passphrase ]]; then
  DATAKEYID=$(echo ${PASSPHRASE} | ecryptfs-insert-wrapped-passphrase-into-keyring ${TOPDIR}/.wrapped-data-passphrase | cut -d'[' -f2 | cut -d']' -f1 | sed -e 's/Passphrase: //' | tr -d '[[:space:]]')
  ECRYPTFS_OPTIONS="${ECRYPTFS_OPTIONS},ecryptfs_sig=${DATAKEYID}"
fi
if [[ -s ${TOPDIR}/.wrapped-file-passphrase ]]; then
  FILEKEYID=$(echo ${PASSPHRASE} | ecryptfs-insert-wrapped-passphrase-into-keyring ${TOPDIR}/.wrapped-file-passphrase | cut -d'[' -f2 | cut -d']' -f1 | sed -e 's/Passphrase: //' | tr -d '[[:space:]]')
  ECRYPTFS_OPTIONS="${ECRYPTFS_OPTIONS},ecryptfs_fnek_sig=${FILEKEYID}"
fi

mkdir -p "${UNENCRYPTED_DIR}"
sudo mount -i -t ecryptfs "${ENCRYPTED_DIR}" "${UNENCRYPTED_DIR}" -o nodev,nosuid,${ECRYPTFS_OPTIONS}
