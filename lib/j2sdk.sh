
j2sdk_control() {
    j2se_control
    cat << EOF
Package: $j2se_package
Architecture: any
Depends: \${shlibs:Depends}
Recommends: netbase, libx11-6 | xlibs, libasound2, libgtk1.2, libstdc++5
Provides: java-virtual-machine, java-runtime, java2-runtime, java5-runtime, java6-runtime, java-browser-plugin, java-compiler, java2-compiler, java-runtime-headless, java2-runtime-headless, java5-runtime-headless, java6-runtime-headless, java-sdk, java2-sdk, java5-sdk, java6-sdk, j2sdk$j2se_release, j2re$j2se_release
Replaces: ${j2se_package}debian
Description: $j2se_title
 The Java(TM) SE JDK is a development environment for building
 applications, applets, and components that can be deployed on the
 Java(TM) platform.
 .
 The Java(TM) SE JDK software includes tools useful for developing and
 testing programs written in the Java programming language and running
 on the Java platform. These tools are designed to be used from the
 command line. Except for appletviewer, these tools do not provide a
 graphical user interface.
 .
 This package has been automatically created with java-package ($version).
EOF
}

# build debian package
j2sdk_run() {
    echo
    diskfree "$j2se_required_space"
    read_maintainer_info
    j2se_package="$j2se_vendor-java$j2se_release-jdk"
    j2se_name="jdk-$j2se_version-$j2se_vendor-$j2se_arch"
    local target="$install_dir$jvm_base$j2se_name"
    install -d -m 755 "$( dirname "$target" )"
    extract_bin "$archive_path" "$j2se_expected_min_size" "$target"
    rm -rf "$target/.systemPrefs"
    echo "7" > "$debian_dir/compat"
    j2se_readme > "$debian_dir/README.Debian"
    j2se_changelog > "$debian_dir/changelog"
    j2sdk_control > "$debian_dir/control"
    j2se_copyright > "$debian_dir/copyright"
    j2se_install_scripts
    install -d "$target/debian"
    j2se_info > "$target/debian/info"
    eval "$j2se_jinfo" > "$install_dir$jvm_base.$j2se_name.jinfo"
    j2se_build
}
