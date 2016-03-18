# Detect product
j2se_detect_oracle_server_j2re=oracle_server_j2re_detect
oracle_server_j2re_detect() {
  j2se_release=0

  # Update or GA release (server-jre-8u74-linux-x64.tar.gz)
  if [[ $archive_name =~ server-jre-([0-9]+)(u([0-9]+))?-linux-(i586|x64|amd64)\.(bin|tar\.gz) ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_arch=${BASH_REMATCH[4]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update"
      j2se_version=${j2se_release}u${j2se_update}${revision}
    else
      j2se_version_name="$j2se_release GA"
      j2se_version=${j2se_release}${revision}
    fi
  fi

  # Early Access Release (jre-8-ea-bin-b103-linux-x64-15_aug_2013.tar.gz)
  if [[ $archive_name =~ server-jre-([0-9]+)(u([0-9]+))?-(ea|fcs)-bin-(b[0-9]+)-linux-(i586|x64|amd64).*\.(bin|tar\.gz) ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_build=${BASH_REMATCH[5]}
    j2se_arch=${BASH_REMATCH[6]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}u${j2se_update}~ea-build-${j2se_build}${revision}
    else
      j2se_version_name="$j2se_release Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}~ea-build-${j2se_build}${revision}
    fi
  fi

  if [[ $j2se_release > 0 ]]
  then
    j2se_priority=$((310 + $j2se_release - 1))
    j2se_expected_min_size=85 #Mb

    # check if the architecture matches
    let compatible=1

    case "${DEB_BUILD_ARCH:-$DEB_BUILD_GNU_TYPE}" in
      i386|i486-linux-gnu)
        if [[ "$j2se_arch" != "i586" ]]; then compatible=0; fi
        ;;
      amd64|x86_64-linux-gnu)
        if [[ "$j2se_arch" != "x64" && "$j2se_arch" != "amd64" ]]; then compatible=0; fi
        ;;
    esac

    if [[ $compatible == 0 ]]
    then
      echo "The archive $archive_name is not supported on the ${DEB_BUILD_ARCH} architecture"
      return
    fi


    cat << EOF

Detected product:
    Server Java(TM) Runtime Environment (JRE)
    Standard Edition, Version $j2se_version_name
    Oracle(TM)
EOF
    if read_yn "Is this correct [Y/n]: "; then
      j2se_found=true
      j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
      j2se_vendor="oracle"
      j2se_title="Java™ Platform, Standard Edition $j2se_release Server Runtime Environment"

      j2se_install=oracle_server_j2re_install
      j2se_remove=oracle_server_j2re_remove
      j2se_jinfo=oracle_server_j2re_jinfo
      j2se_control=oracle_server_j2re_control
      oracle_jre_bin_hl="java keytool orbd pack200 rmid rmiregistry servertool tnameserv unpack200 policytool"
      oracle_jre_bin_jre="policytool"
      oracle_jre_lib_hl="jexec"
      j2se_package="$j2se_vendor-java$j2se_release-server-jre"
      exlude_libs="appletviewer libawt_xawt.so libsplashscreen.so policytool"
      j2se_run
    fi
  fi
}

oracle_server_j2re_install() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

install_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_hl
install_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_jre
install_no_man_alternatives $jvm_base$j2se_name/lib $oracle_jre_lib_hl
EOF
}

oracle_server_j2re_remove() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

remove_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_hl
remove_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_jre
remove_alternatives $jvm_base$j2se_name/lib $oracle_jre_lib_hl
EOF
}

oracle_server_j2re_jinfo() {
    cat << EOF
name=$j2se_name
priority=$j2se_priority
section=main
EOF
    jinfos "hl" $jvm_base$j2se_name/bin/ $oracle_jre_bin_hl
    jinfos "jre" $jvm_base$j2se_name/bin/ $oracle_jre_bin_jre
    jinfos "hl" $jvm_base$j2se_name/lib/ $oracle_jre_lib_hl
}

oracle_server_j2re_control() {
    j2se_control
    if [ "$create_cert_softlinks" == "true" ]; then
        depends="ca-certificates-java"
    fi
    for i in `seq 5 ${j2se_release}`;
    do
        provides_headless="${provides_headless} java${i}-runtime-headless,"
    done
    cat << EOF
Package: $j2se_package
Architecture: $j2se_debian_arch
Depends: \${misc:Depends}, \${shlibs:Depends}, $depends
Recommends: netbase
Provides: java-runtime-headless, java2-runtime-headless, $provides_headless
Description: $j2se_title
 The Java(TM) SE Server Runtime Environment contains the Java virtual machine,
 runtime class libraries, and Java application launcher that are necessary to
 run programs written in the Java programming language. It includes tools for
 JVM monitoring and tools commonly required for server applications, but does
 not include browser integration (the Java plug-in), auto-update, nor an
 installer.
 .
 This package has been automatically created with java-package ($version).
EOF
}
