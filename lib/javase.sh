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
$j2se_package ($j2se_version) $target_distribution; urgency=medium

  * This package was created with java-package ($version).

 -- $maintainer_name <$maintainer_email>  $( date -R )
EOF
}

j2se_control() {
    if test -n "$build_depends"; then
        build_depends=", $build_depends"
    fi
    cat << EOF
Source: $j2se_package
Section: non-free/devel
Priority: optional
Maintainer: $maintainer_name <$maintainer_email>
Build-Depends: debhelper (>= 9)${build_depends}
Standards-Version: 3.9.7

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
    cd "$package_dir"
    find * -type f -iname copyright ! -path debian/copyright |
    while read file; do
        cat << EOF

File: $jvm_base$file

----------------------------------------------------------------------

EOF
        iconv -f ISO-8859-15 -t UTF-8 "$file" | sed 's/[ \t]*$//'
        cat << EOF

----------------------------------------------------------------------
EOF
    done
    )
}

j2se_rules() {
    cat << EOF
#!/usr/bin/make -f

# Exclude libraries that pull in ALSA or OpenGL which are not needed in normal operation
EXCLUDE_LIBS = \\
	--exclude=avplugin \\
	--exclude=fxavcodecplugin \\
	--exclude=libjsoundalsa.so \\
EOF
    for lib in $exlude_libs; do
        printf '\t--exclude=%s \\\n' "$lib"
    done
    cat << EOF
	\$(NULL)

%:
	dh \$@

override_dh_compress:
	dh_compress \$(shell find $j2se_name/man/ -type f ! -name '*.gz' -printf '${jvm_base##/}/%p\n')

override_dh_shlibdeps:
	dh_shlibdeps \$(EXCLUDE_LIBS) -l\$(shell find $j2se_name -type f -name '*.so*' -printf '${jvm_base##/}/%h\n' | sort -u | tr '\n' ':' | sed 's/:\$\$//')

override_dh_strip_nondeterminism:
	# Disable dh_strip_nondeterminism to speed up the build
EOF
}

j2se_doc_rules() {
    cat << EOF
#!/usr/bin/make -f

%:
	dh \$@

override_dh_strip_nondeterminism:
	# Disable dh_strip_nondeterminism to speed up the build
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
            --install "/usr/bin/\$program" "\$program" "\$program_base/\$program" ${priority_override:-$j2se_priority} \\
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
            update-alternatives --install "/usr/bin/\$program" "\$program" "\$program_base/\$program" ${priority_override:-$j2se_priority}
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
          update-alternatives --install "\$link_path/\$link_name" "\$plugin_name" "\$plugin" ${priority_override:-$j2se_priority}
        fi
    }
EOF
    if [ "$create_cert_softlinks" == "true" ];then
        cat >> "$debian_dir/postinst" << EOF
    for subdir in lib/security jre/lib/security;do
        if [ -f $jvm_base$j2se_name/\$subdir/cacerts ]; then
            ln -sf /etc/ssl/certs/java/cacerts $jvm_base$j2se_name/\$subdir/cacerts
        fi
    done
EOF
    fi
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
    if [ -n "$build_source" ]; then
        local source_dir=${j2se_package}-${j2se_version}
        echo "    copy ${source_dir} into directory $working_dir/"
        rm -rf "$working_dir/${source_dir}"
        cp -r "$package_dir" "$working_dir/${source_dir}"
        cat << EOF

The Debian source package has been created in the current directory.
You can build the package with:

    cd ${source_dir}
    dpkg-buildpackage -b -uc -us

EOF
    else
        cd "$package_dir"
        echo "Create debian package:"

        dpkg-buildpackage -b -uc -us
        cd "$tmp"
        local deb_filename="$( echo "${j2se_package}_"*.deb )"
        echo "    copy $deb_filename into directory $working_dir/"
        cp "$deb_filename" "$working_dir/"
        if [ -n "$genchanges" ]; then
            echo "    dpkg-genchanges"
            local changes_filename="${deb_filename%.deb}.changes"
            echo "    copy $changes_filename into directory $working_dir/"
            cp "$changes_filename" "$working_dir/"
        fi
        cat << EOF

The Debian package has been created in the current directory.
You can install the package as root with:

    dpkg -i $deb_filename

EOF
    fi
}

# build debian package
j2se_run() {
    echo
    diskfree "$j2se_required_space"
    read_maintainer_info
    get_distribution
    case "${j2se_arch}" in
      i586)
        j2se_debian_arch=i386
        ;;
      amd64|x64)
        j2se_debian_arch=amd64
        ;;
    esac
    j2se_name="$j2se_package-$j2se_debian_arch"
    local target="$package_dir/$j2se_name"
    install -d -m 755 "$( dirname "$target" )"
    extract_bin "$archive_path" "$j2se_expected_min_size" "$target"
    if [[ -n "$jce_archive" ]]; then
      extract_jce "$jce_path" "$target/jre/lib/security"
    fi
    rm -rf "$target/.systemPrefs"
    echo "9" > "$debian_dir/compat"
    j2se_readme > "$debian_dir/README.Debian"
    j2se_changelog > "$debian_dir/changelog"
    eval "$j2se_control" > "$debian_dir/control"
    j2se_copyright > "$debian_dir/copyright"
    j2se_rules > "$debian_dir/rules"
    chmod +x "$debian_dir/rules"
    j2se_install_scripts
    install -d "$target/debian"
    j2se_info > "$target/debian/info"
    eval "$j2se_jinfo" > "$package_dir/.$j2se_name.jinfo"
    echo ".$j2se_name.jinfo $jvm_base" > "$debian_dir/install"
    echo "$j2se_name $jvm_base" >> "$debian_dir/install"
    j2se_build
}
