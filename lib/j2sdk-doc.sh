function j2sdk_doc_readme() {
    j2se_readme
}

function j2sdk_doc_changelog() {
    j2se_changelog
}

function j2sdk_doc_control() {
    j2se_control
    cat << EOF
Package: $j2se_package
Architecture: any
Depends: 
Recommends: 
Provides: 
Replaces: 
Description: $j2se_title
 The Java(TM) 2 SDK is a development environment for building
 applications, applets, and components that can be deployed on the
 Java(TM) platform.
 .
 This package provides the official API documentation published
 by Sun Microsystems.
 .
 This package has been automatically created with java-package ($version).
EOF
}

function j2sdk_doc_copyright() {
    j2se_copyright
}

function j2sdk_doc_install_scripts() {
    j2se_install_scripts
}

function j2sdk_doc_info() {
    j2se_info
}

function j2sdk_doc_doc-base() {
    cat << EOF
Document: $j2se_package
Title: $j2se_title
Author: $maintainer_name
Abstract: This is the API Javadoc provided by the vendor
Section: Programming

Format: HTML
Index: /usr/share/doc/j2sdk$j2se_release-$j2se_vendor-doc/index.html
Files: /usr/share/doc/j2sdk$j2se_release-$j2se_vendor-doc/*.html

EOF
}

function j2sdk_doc_build() {
    j2se_build
}

# build debian package
function j2sdk_doc_run() {
    echo
    diskfree "$j2se_required_space"
    read_maintainer_info
    j2se_package="$j2se_vendor-j2sdk$j2se_release-doc"
    j2se_base="/usr/share/doc/j2sdk$j2se_release-$j2se_vendor-doc"
    local target="$install_dir$j2se_base"
    install -d -m 755 "$( dirname "$target" )"
    extract_bin "$archive_path" "$j2se_expected_min_size" "$target"
    rm -rf "$target/.systemPrefs"
    j2sdk_doc_readme > "$debian_dir/README.Debian"
    j2sdk_doc_changelog > "$debian_dir/changelog"
    j2sdk_doc_control > "$debian_dir/control"
    j2sdk_doc_copyright > "$debian_dir/copyright"
    j2sdk_doc_doc-base > "$debian_dir/$j2se_package.doc-base"
    j2sdk_doc_install_scripts
    install -d "$target/debian"
    j2sdk_doc_info > "$target/debian/info"
    j2sdk_doc_build
}
