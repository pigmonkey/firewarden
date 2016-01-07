#!/bin/bash
#
# Open a file via the specified application within a private Firejail sandbox.
#
# This is accomplished by creating a temporary directory, copying the given
# file into it, and then specifying that temporary directory be used by
# Firejail as the user home. After the application has closed, the temporary
# directory and all of its contents are deleted.
#
# Any arguments are passed directly to the application.
#
###############################################################################

get_file() {
    # Build the full path of the file, ensuring that it exists.
    file_path=$(readlink -e "$file")
    # If the full path of the file was not succesfully built, fail.
    if [[ -z "$file_path" ]]; then
        echo 'could not find file'
        exit 11
    # Otherwise, also get the name of the file.
    else
        file_name=$(basename "$file")
    fi
}

build_dir() {
    dir=/tmp/$USER/firewarden/$now
    # Build a temporary directory to function as the jail's home.
    mkdir -p $dir
    # Copy the requested file into it.
    cp "$file_path" $dir
}

cleanup() {
    # Recursevily remove the temporary directory and all of its contents.
    rm -r /tmp/$USER/firewarden/$now
}

execute() {
    # Create the sandbox and open the file.
    eval /usr/bin/firejail --private-dev --net=none --private=$dir $args \"$file_name\"
}

# Get the current time.
now=`date --iso-8601=s`

# Get the last argument passed, assuming it is the file to open.
file="${@: -1}"

# Get the rest of the arguments.
arg_length=$(($#-1))
args=${@:1:$arg_length}

get_file
build_dir
execute
cleanup
