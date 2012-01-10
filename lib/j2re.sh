function j2re_readme() {
    j2se_readme
}

function j2re_changelog() {
    j2se_changelog
}

function j2re_control() {
    j2se_control
    cat << EOF
Package: $j2se_package
Architecture: any
Depends: \${shlibs:Depends}
Recommends: netbase, libx11-6 | xlibs, libasound2, libgtk1.2
Provides: java-virtual-machine, java-runtime, java2-runtime, java-runtime-headless, java2-runtime-headless, java-browser-plugin, j2re${j2se_release}
Replaces: ${j2se_package}debian
Description: $j2se_title
 The Java(TM) 2 Runtime Environment contains the Java virtual machine,
 runtime class libraries, and Java application launcher that are
 necessary to run programs written in the Java progamming language
 (this includes the Java 2 Plug-In for Netscape and Mozilla
 browsers). It is not a development environment and doesn't contain
 development tools such as compilers or debuggers. For development
 tools, see the Java 2 SDK, Standard Edition.
 .
 This package has been automatically created with java-package ($version).
EOF
}

function j2re_copyright() {
    j2se_copyright
}

function j2re_install_scripts() {
    j2se_install_scripts
}

function j2re_info() {
    j2se_info
}

function j2re_build() {
    j2se_build
}

# build debian package
function j2re_run() {
    echo
    diskfree "$j2se_required_space"
    read_maintainer_info
    j2se_package="$j2se_vendor-j2re$j2se_release"
    j2se_base="/usr/lib/jvm/j2re$j2se_release-$j2se_vendor"
    local target="$install_dir$j2se_base"
    install -d -m 755 "$( dirname "$target" )"
    extract_bin "$archive_path" "$j2se_expected_min_size" "$target"
    rm -rf "$target/.systemPrefs"
    j2re_readme > "$debian_dir/README.Debian"
    j2re_changelog > "$debian_dir/changelog"
    j2re_control > "$debian_dir/control"
    j2re_copyright > "$debian_dir/copyright"
    j2re_install_scripts
    install -d "$target/debian"
    j2re_info > "$target/debian/info"
    j2re_build
}
