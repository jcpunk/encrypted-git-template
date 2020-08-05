#!/bin/bash

OUTDIR='../'
MYDIR=$(dirname $0)
if [[ ${MYDIR} != '.' ]]; then
  OUTDIR=`pwd`
fi

if [[ -e ${OUTDIR}/.wrapped-data-passphrase ]]; then
  echo "Found existing ${OUTDIR}/.wrapped-data-passphrase" 1>&2
  echo "  You should move or remove it first" 1>&2
  exit 1
fi

if [[ -e ${OUTDIR}/.wrapped-file-passphrase ]]; then
  echo "Found existing ${OUTDIR}/.wrapped-data-passphrase" 1>&2
  echo "  You should move or remove it first" 1>&2
  exit 1
fi
# Read in the passphrase with echo off
stty -echo
printf "Passphrase: " 1>&2
read PASSPHRASE
printf "\nConfirm Passphrase: " 1>&2
read CONFIRM
if [[ "${PASSPHRASE}" != "${CONFIRM}" ]]; then
    printf "Confirm Passphrase does not match!" 1>&2
    exit 1
fi
stty echo

# read a random string between 55-64 chars for the encryption keys
echo ${PASSPHRASE} | xargs -i printf "%s\n%s" $(head -c 500 /dev/random | tr -dc '[[:graph:]' | head -c $(seq 55 64 | sort -R | head -1)) {} | ecryptfs-wrap-passphrase ${OUTDIR}/.wrapped-data-passphrase
echo ${PASSPHRASE} | xargs -i printf "%s\n%s" $(head -c 500 /dev/random | tr -dc '[[:graph:]' | head -c $(seq 55 64 | sort -R | head -1)) {} | ecryptfs-wrap-passphrase ${OUTDIR}/.wrapped-file-passphrase
