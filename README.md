# An eCryptfs protected git repo

This is an example of how to setup an eCryptfs protected git repo.

Using this method, eCryptfs will encrypt your repo on disk and require
a decryption key to read the files.

You cannot meaningfully revoke access to someone once they know the
passphrase to decrypt the repo.

In practice you could change the password on the `.wrapped-*-passphrase`
files, but:

* If the old key exists in your commit logs it can be used to decrypt everything anyway!
* If the old key is in someone's local copy it can be used to decrypt everything anyway!

Changing the key password only works when the copies of the key with the
old password are all destroyed!

Git cannot really do that for you!

# Setup

You must have `ecryptfs.ko` and `ecryptfs-utils` installed.

It is recommended that you install `pre-commit` (https://pre-commit.com/) and run `pre-commit install` once you've cloned the repo.

## Usage

To make your random key run `bin/make_new_key.sh` it will prompt you
for a decryption passphrase.

To mount a directory with these keys run `bin/mount.sh`.
It optionally takes two arguments:

* `SOURCEDIR`: Where is the eCryptfs directory (defaults to `ENCRYPTED_DATA`)
* `DESTDIR`: Where should this be mounted (defaults to `unencrypted`)

A server hook is provided under the `hooks` directory that you can use to help
protect the repo.
