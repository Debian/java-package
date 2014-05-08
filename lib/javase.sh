j2se_readme() {
    cat << EOF
Package for $j2se_title
---

This package has been automatically created with java-package ($version).
All files from the original distribution should have been installed in
the directory $jvm_base$j2se_name. Please take a look at this directory for
further information.

EOF
}

j2se_changelog() {
    cat << EOF
$j2se_package ($j2se_version) unstable; urgency=low

  * This package was created with java-package ($version).

 -- $maintainer_name <$maintainer_email>  $( date -R )

EOF
}

j2se_control() {
    cat << EOF
Source: $j2se_package
Section: non-free/devel
Priority: optional
Maintainer: $maintainer_name <$maintainer_email>
Build-Depends: debhelper (>= 9)
Standards-Version: 3.9.5

EOF
}

j2se_copyright() {
    cat << EOF
----------------------------------------------------------------------

This file contains a copy of all copyright files found in the original
distribution. The original copyright files and further information can
be found in the directory $jvm_base$j2se_name and its
subdirectories.

----------------------------------------------------------------------
EOF
    (
    cd "$install_dir"
    find * -type f -iname copyright |
    while read file; do
        cat << EOF

File: /$file

----------------------------------------------------------------------

EOF
        cat "$file"
        cat << EOF

----------------------------------------------------------------------
EOF
    done
    )
}

j2se_rules() {
    cat << EOF
#!/usr/bin/make -f

%:
	dh \$@
EOF
}

j2se_install_scripts() {
    cat > "$debian_dir/postinst" << EOF
#!/bin/bash

set -e

if [ "\$1" = configure ]; then

    # Common functions for all install scripts

    # install_alternatives program_base programs
    install_alternatives() {
        program_base="\$1"
        shift
        for program in \$*; do
          if [[ -f "\$program_base/\$program" ]]; then
            update-alternatives \\
            --install "/usr/bin/\$program" "\$program" "\$program_base/\$program" $j2se_priority \\
            --slave "/usr/share/man/man1/\$program.1.gz" "\$program.1.gz" "$jvm_base$j2se_name/man/man1/\$program.1.gz"
          fi
        done
    }

    # install_alternatives_no_man program_base programs
    install_no_man_alternatives() {
        program_base="\$1"
        shift
        for program in \$*; do
          if [[ -f "\$program_base/\$program" ]]; then
            update-alternatives --install "/usr/bin/\$program" "\$program" "\$program_base/\$program" $j2se_priority
          fi
        done
    }

    # install_browser_plugin link_path link_name plugin_name plugin
    install_browser_plugin() {
        local link_path="\$1"
        local link_name="\$2"
        local plugin_name="\$3"
        local plugin="\$4"
        [ -d "\$link_path" ] || install -d -m 755 "\$link_path"
        if [[ -f "\$plugin" ]]; then
          update-alternatives --install "\$link_path/\$link_name" "\$plugin_name" "\$plugin" $j2se_priority
        fi
    }

EOF
    eval "$j2se_install" >> "$debian_dir/postinst"

    cat >> "$debian_dir/postinst" << EOF
fi

#DEBHELPER#

exit 0
EOF
    chmod 755 "$debian_dir/postinst"

    cat > "$debian_dir/prerm" << EOF
#!/bin/bash

set -e

case "\$1" in
    remove | deconfigure)

    # Common functions for all remove scripts

    # remove_alternatives program_base programs
    remove_alternatives() {
        program_base="\$1"
        shift
        for program in \$*; do
          update-alternatives --remove "\$program" "\$program_base/\$program"
        done
    }

    # remove_browser_plugin plugin_name plugin
    remove_browser_plugin() {
        local plugin_name="\$1"
        local plugin="\$2"
        update-alternatives --remove "\$plugin_name" "\$plugin"
    }

EOF
    eval "$j2se_remove" >> "$debian_dir/prerm"

    cat >> "$debian_dir/prerm" << EOF
    ;;
esac

#DEBHELPER#

exit 0
EOF
    chmod 755 "$debian_dir/prerm"
}

j2se_info() {
    cat << EOF
version="$version"
j2se_version="$j2se_version"
maintainer_name="$maintainer_name"
maintainer_email="$maintainer_email"
date="$( date +%Y/%m/%d )"
EOF
}

# jinfos prefix program_base programs
jinfos() {
    prefix="$1"
    program_base="$2"
    shift ; shift
    for program in $*; do
      echo "$prefix $program $program_base$program" 
    done
}

j2se_build() {
    cd "$tmp"
    echo "Create debian package:"

    #export DH_VERBOSE=1
    export DH_OPTIONS=--tmpdir="$install_dir"

    echo "    dh_testdir"
    dh_testdir
    echo "    dh_testroot"
    dh_testroot
    echo "    dh_installchangelogs"
    dh_installchangelogs
    # Problem: dh_installchangelogs thinks this is a native package.
    echo "    dh_installdocs"
    dh_installdocs
    # dh_install
    # dh_link
    # Conditionally wrapping this as not all JRE/JDKs have man directories
    if [ -e "$install_dir/$jvm_base$j2se_name/man" ]; then
        echo "    dh_compress"
        dh_compress $( find "$install_dir/$jvm_base$j2se_name/man" -type f ! -name "*.gz" )
    fi
    echo "    dh_fixperms"
    dh_fixperms
    echo "    dh_installdeb"
    dh_installdeb
    echo "    dh_shlibdeps"
    ldpath=
    for dir in $( find "$install_dir" -type f -name "*.so*" -printf "%h\n" | sort -u ); do
        if [[ -z "$ldpath" ]]; then
            ldpath="$dir"
        else
            ldpath="$ldpath:$dir"
        fi
    done
    # suppress some warnings
    dh_shlibdeps --exclude=fxavcodecplugin -l"$ldpath" 2>&1 |
    { grep -v "warning: format of \`NEEDED lib.*\.so' not recognized" >&2 || true; }
    echo "    dh_gencontrol"
    dh_gencontrol
    echo "    dh_md5sums"
    dh_md5sums
    echo "    dh_builddeb"
    dh_builddeb --destdir="$tmp"
    local deb_filename="$( echo "${j2se_package}_"*.deb )"
    echo "    copy $deb_filename into directory $working_dir/"
    cp "$deb_filename" "$working_dir/"
    if [ -n "$genchanges" ]; then
        echo "    dpkg-genchanges"
        local changes_filename="${deb_filename%.deb}.changes"
        dpkg-genchanges -b -u. > "$changes_filename"
        echo "    copy $changes_filename into directory $working_dir/"
        cp "$changes_filename" "$working_dir/"
    fi
    cat << EOF

The Debian package has been created in the current directory.
You can install the package as root with:

    dpkg -i $deb_filename

EOF
}
