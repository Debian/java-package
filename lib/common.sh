# read_yn <prompt>
read_yn() {
    local prompt="$1"
    while true; do
    read -e -n 1 -p "$prompt" reply
    case "$reply" in
        "" | "y" | "Y")
        return 0
        ;;
        "N" | "n")
        return 1
        ;;
    esac
    done
}


# diskusage <path>: prints size in MB
diskusage() {
    local path="$1"
    read size dummy < <( du -sm --apparent-size "$path" )
    echo "$size"
}


# diskfree <minimum size in MB>
diskfree() {
    local size="$1"
    echo -n "Checking free diskspace:"
    (( free = `stat -f -c '%a / 2048 * ( %s / 512 )' $tmp ` ))

    if [ "$free" -ge "$size" ]; then
    echo " done."
    else
    cat >&2 << EOF


WARNING: Possibly not enough free disk space in "$tmp".

You need at least $size MB, but only $free MB seems free. Note: You
can specify an alternate directory by setting the environment variable

Press Ctrl+C to interrupt, or return to try to continue anyway.

TMPDIR.

EOF
    read
    fi
}


# extract_bin <file> <expected_min_size> <dest>
extract_bin() {
    local file="$1"
    local expected_min_size="$2"
    local dest="$3"
    cat << EOF

In the next step, the binary file will be extracted. Probably a
license agreement will be displayed. Please read this agreement
carefully. If you do not agree to the displayed license terms, the
package will not be built.

EOF
    read -e -p "Press [Return] to continue: " dummy
    echo
    local extract_dir="$tmp/extract"
    mkdir "$extract_dir"
    cd "$extract_dir"
    echo

    local extract_cmd
    case "$archive_path" in
    *.tar)
        extract_cmd="tar xf";;
    *.tar.bz2)
        extract_cmd="tar --bzip2 -xf";;
    *.tgz|*.tar.gz)
        extract_cmd="tar xfz";;
    *.zip)
        extract_cmd="unzip -q";;
    *)
        extract_cmd=sh
    esac

    if ! $extract_cmd "$archive_path"; then
    cat << EOF

WARNING: The package installation script exited with an error
value. Usually, this means, that the installation failed for some
reason. But in some cases there is no problem and you can continue
creating the Debian package.

Please check if there are any error messages. Press [Return] to
continue or Ctrl-C to abort.

EOF
    read
    fi
    echo
    echo -n "Testing extracted archive..."
    local size="$( diskusage "$extract_dir" )"
    if [ "$size" -lt "$expected_min_size" ]; then
    cat << EOF

Invalid size ($size MB) of extracted archive. Probably you have not
enough free disc space in the temporary directory. Note: You can
specify an alternate directory by setting the environment variable
TMPDIR.

EOF
    error_exit
    else
    cd "$extract_dir"
    files=(*)
    if [ "${#files[*]}" -ne 1 ]; then
        cat << EOF

Expected one file, but found the following ${#files[*]} files:
    ${files[*]}

EOF
        error_exit
    fi
    mv "$files" "$dest"
    echo -e " okay.\n"
    fi
}

extract_jce() {
  local zip_file="$1"
  local dest_dir="$2"

  echo "Installing unlimited strength cryptography files using $zip_file"
  for f in {US_export,local}_policy.jar; do
    unzip -o -j -d "$dest_dir" "$zip_file" "*/$f"
  done
}

read_maintainer_info() {
    if [ -z "$maintainer_name" ]; then
    if [ -n "$DEBFULLNAME" ]; then
        maintainer_name="$DEBFULLNAME"
    elif [ -n "$DEBNAME" ]; then
        maintainer_name="$DEBNAME"
    else
        default_name="$(getent passwd $(id -run) | cut -d: -f5| cut -d, -f1)"

    cat << EOF

Please enter your full name. This value will be used in the maintainer
field of the created package.

EOF

    # gecos can be null
    while [ -z "$maintainer_name" ]; do
        read -e -p "Full name [$default_name]:" maintainer_name
        if [ -z "$maintainer_name" ] && [ -n "$default_name" ]; then
            maintainer_name="$default_name"
        fi
    done
    fi
    fi

    if [ -z "$maintainer_email" ]; then
    local default_email=
    if [ -n "$DEBEMAIL" ]; then
        maintainer_email="$DEBEMAIL"
    else
    if [ -r "/etc/mailname" ]; then
        default_email="$( id -run )@$( cat /etc/mailname )"
    else
        default_email="$( id -run )@$( hostname --fqdn )"
    fi
    cat << EOF

Please enter a valid email address or press return to accept the
default value. This address will be used in the maintainer field of
the created package.

EOF
    read -e -p "Email [$default_email]: " maintainer_email
    if [ -z "$maintainer_email" ]; then
        maintainer_email="$default_email"
    fi
    fi
    fi
}

# provide the architecture for evaluation by plugins
get_architecture() {
    echo

    export DEB_BUILD_ARCH=$(dpkg-architecture -qDEB_BUILD_ARCH)

    export DEB_BUILD_GNU_TYPE=$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)

    echo "Detected Debian build architecture: ${DEB_BUILD_ARCH:-N/A}"

    echo "Detected Debian GNU type: ${DEB_BUILD_GNU_TYPE:-N/A}"
}

# get browser plugin directories
get_browser_plugin_dirs() {
    if dpkg-vendor --derives-from Ubuntu; then
        export browser_plugin_dirs="xulrunner-addons firefox iceape iceweasel mozilla midbrowser xulrunner"
    else
        export browser_plugin_dirs=mozilla
    fi
}

get_distribution() {
    if [ -n "$distribution" ]; then
      target_distribution="$distribution"
    else
      target_distribution="unstable"
    fi
}
