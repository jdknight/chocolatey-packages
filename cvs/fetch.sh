#!/usr/bin/env bash

version=$(grep -oP '(?<=<version>).*?(?=</version>)' cvs.nuspec)

base_url=https://ftp.gnu.org/non-gnu/cvs
binary_base_url=$base_url/binary/stable/x86-woe

bin_version=${version//./-}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
tools_dir=$script_dir/tools
work_dir=$script_dir/workdir

artifacts=(
    $binary_base_url/cvs-${bin_version}.zip
    $binary_base_url/cvs-${bin_version}.zip.sig
)

hashes=(
    635828e428d8f57e239bda9eadc05a26f12634da83c5d8453ad5f90f5bd2f418
    1b2f60c9bda3bbc9dd5933818b5138d416d0de023019f1096db33f51a984c681
)

mkdir -p $work_dir
targets=()

# download required files
for artifact in ${artifacts[@]}; do
    target=$work_dir/$(basename $artifact)
    targets+=($target)
    if [ ! -f $target ]; then
        echo "Downloading artifact: $artifact"
        curl $artifact -o $target
    fi
done

# sanity check artifacts
for i in "${!targets[@]}"; do
    target=${targets[i]}
    target_name=$(basename $target)
    echo "Verifying hash for: $target_name"
    if ! echo "${hashes[i]}  $target" | sha256sum --check --status; then
        echo "FAILED] Invalid hash detected: $target_name"
        exit 1
    fi
done

# (excessive) re-check signatures
for target in ${targets[@]}; do
    if [[ $target == *.sig ]]; then
        echo "Checking signature..."
        if ! gpg --verify $target ${target%.*}; then
            exit 1
        fi
    fi
done

# extract the cvs executable
echo "Extracting executable..."
unzip -p $work_dir/cvs-${bin_version}.zip cvs.exe >$tools_dir/cvs.exe
