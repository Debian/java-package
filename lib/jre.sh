
j2re_control() {
    j2se_control
    cat << EOF
Package: $j2se_package
Architecture: any
Depends: \${shlibs:Depends}
Recommends: netbase, libx11-6 | xlibs, libasound2, libgtk1.2
Provides: java-virtual-machine, java-runtime, java2-runtime, java${j2se_release}-runtime, java$((${j2se_release}-1))-runtime, java$((${j2se_release}-2))-runtime, java-runtime-headless, java2-runtime-headless, java${j2se_release}-runtime-headless, java$((${j2se_release}-1))-runtime-headless, java$((${j2se_release}-2))-runtime-headless, java-browser-plugin, j2re${j2se_release}
Replaces: ${j2se_package}debian
Description: $j2se_title
 The Java(TM) SE Runtime Environment contains the Java virtual machine,
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

# build debian package
j2re_run() {
    echo
    diskfree "$j2se_required_space"
    read_maintainer_info
    j2se_package="$j2se_vendor-java$j2se_release-jre"
    j2se_name="jre-$j2se_release-$j2se_vendor-$j2se_arch"
    local target="$install_dir$jvm_base$j2se_name"
    install -d -m 755 "$( dirname "$target" )"
    extract_bin "$archive_path" "$j2se_expected_min_size" "$target"
    rm -rf "$target/.systemPrefs"
    echo "7" > "$debian_dir/compat"
    j2se_readme > "$debian_dir/README.Debian"
    j2se_changelog > "$debian_dir/changelog"
    j2re_control > "$debian_dir/control"
    j2se_copyright > "$debian_dir/copyright"
    j2se_install_scripts
    install -d "$target/debian"
    j2se_info > "$target/debian/info"
    eval "$j2se_jinfo" > "$install_dir$jvm_base.$j2se_name.jinfo"
    j2se_build
}
