j2sdk_doc_control() {
    j2se_control
    cat << EOF
Package: $j2se_package
Architecture: any
Depends: \${misc:Depends}
Description: $j2se_title
 The Java(TM) SE JDK is a development environment for building
 applications, applets, and components that can be deployed on the
 Java(TM) platform.
 .
 This package provides the official API documentation published
 by Oracle.
 .
 This package has been automatically created with java-package ($version).
EOF
}

j2sdk_doc_doc-base() {
    cat << EOF
Document: $j2se_package
Title: $j2se_title
Author: $maintainer_name
Abstract: This is the API Javadoc provided by the vendor
Section: Programming

Format: HTML
Index: /usr/share/doc/$j2se_vendor-java$j2se_release-doc/index.html
Files: /usr/share/doc/$j2se_vendor-java$j2se_release-doc/*.html

EOF
}

# build debian package
j2sdk_doc_run() {
    echo
    diskfree "$j2se_required_space"
    read_maintainer_info
    j2se_package="$j2se_vendor-java$j2se_release-doc"
    j2se_name="jdk$j2se_release-$j2se_vendor-doc"
    local target="$package_dir/$j2se_name"
    install -d -m 755 "$( dirname "$target" )"
    extract_bin "$archive_path" "$j2se_expected_min_size" "$target"
    rm -rf "$target/.systemPrefs"
    echo "9" > "$debian_dir/compat"
    j2se_readme > "$debian_dir/README.Debian"
    j2se_changelog > "$debian_dir/changelog"
    j2sdk_doc_control > "$debian_dir/control"
    j2se_copyright > "$debian_dir/copyright"
    echo "$j2se_name $javadoc_base" > "$debian_dir/install"
    j2sdk_doc_doc-base > "$debian_dir/$j2se_package.doc-base"
    j2se_rules > "$debian_dir/rules"
    chmod +x "$debian_dir/rules"
    j2se_install_scripts
    install -d "$target/debian"
    j2se_info > "$target/debian/info"
    j2se_build
}
