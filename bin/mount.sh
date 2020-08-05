#!/bin/bash -u

#######################################################################
usage() {
    echo ''                                                      >&2
    echo "$0 <args> <src> <dest>"                                >&2
    echo ''                                                      >&2
    echo ' --ro: mount read only'                                >&2
    echo ' --datakey: full path to the wrapped-data-passphrase'  >&2
    echo "            default: ${DATAKEY}"                       >&2
    echo " src: default ${ENCRYPTED_DIR}"                        >&2
    echo " dest: default ${UNENCRYPTED_DIR}"                     >&2
    echo ''                                                      >&2
    exit 1
}

#######################################################################
#######################################################################
args=$(getopt -o h --long help,ro,datakey: -n $0 -- "$@")
eval set -- "$args"

RO='FALSE'
DATAKEY=$(readlink -f ./.wrapped-data-passphrase)
ENCRYPTED_DIR='./ENCRYPTED_DATA/'
UNENCRYPTED_DIR='./unencrypted/'

for arg in $@; do
    case $1 in
        -- )
            # end of getopt args, shift off the -- and get out of the loop
            shift
            break 2
           ;;
        -h | --help )
            usage
            shift
           ;;
        --ro )
            RO='TRUE'
            shift
           ;;
        --datakey )
            DATAKEY=$(readlink -f $2)
            shift ; shift
           ;;
    esac
done

if [[ -d ${ENCRYPTED_DIR} ]]; then
  # make sure it is an absolute path for sudo
  ENCRYPTED_DIR=$(readlink -f ${ENCRYPTED_DIR})
else
  echo "ERROR: No directory ${ENCRYPTED_DIR} found" >&2
  exit 1
fi

if [[ -d ${UNENCRYPTED_DIR} ]]; then
  # make sure it is an absolute path for sudo
  UNENCRYPTED_DIR=$(readlink -f ${UNENCRYPTED_DIR})
else
  echo "ERROR: No directory ${UNENCRYPTED_DIR} found" >&2
  exit 1
fi

ECRYPTFS_OPTIONS='ecryptfs_cipher=aes,ecryptfs_key_bytes=32,ecryptfs_unlink_sigs'
if [[ "${RO}" == 'TRUE' ]]; then
  ECRYPTFS_OPTIONS="${ECRYPTFS_OPTIONS},ro"
fi

# Read in the passphrase with echo off from either user or stdin
stty -echo >/dev/null 2>&1
printf "Passphrase: " 1>&2
while read PASSPHRASE; do
break;
done < /dev/stdin
stty echo >/dev/null 2>&1

# unlock data key
if [[ -s ${DATAKEY} ]]; then
  DATAKEYID=$(echo ${PASSPHRASE} | ecryptfs-insert-wrapped-passphrase-into-keyring ${DATAKEY} | cut -d'[' -f2 | cut -d']' -f1 | sed -e 's/Passphrase: //' | tr -d '[[:space:]]')
  ECRYPTFS_OPTIONS="${ECRYPTFS_OPTIONS},ecryptfs_sig=${DATAKEYID}"
else
  echo "Could not find '${DATAKEY}'" >&2
  exit 1
fi

# do the mounting
if [[ ${EUID} -eq 0 ]]; then
  mount -i -t ecryptfs "${ENCRYPTED_DIR}" "${UNENCRYPTED_DIR}" -o nodev,nosuid,${ECRYPTFS_OPTIONS}
else
  sudo mount -i -t ecryptfs "${ENCRYPTED_DIR}" "${UNENCRYPTED_DIR}" -o nodev,nosuid,${ECRYPTFS_OPTIONS}
fi
