# Detect product
j2se_detect_oracle_j9sdk=oracle_j9sdk_detect
oracle_j9sdk_detect() {
  j2se_release=0

  # GA release (jdk-9_linux-x64_bin.tar.gz, jdk-9.0.1-x64_bin.tar.gz)
  if [[ $archive_name =~ jdk-(9|([1-9][0-9]+))((\.[0-9]+)*)_linux-(x64)_bin\.tar\.gz ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_arch=${BASH_REMATCH[5]}
    j2se_version_name="$j2se_release$j2se_update"
    j2se_version=${j2se_release}${j2se_update}${revision}
  fi

  # Early Access Release (jdk-9-ea+162_linux-x64_bin.tar.gz)
  if [[ $archive_name =~ jdk-(9)()-ea[+]([0-9]+)_linux-(x86|x64)_bin\.tar\.gz ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[2]}
    j2se_build=${BASH_REMATCH[3]}
    j2se_arch=${BASH_REMATCH[4]}
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
    j2se_priority=$((310 + $j2se_release))
    j2se_expected_min_size=130 #Mb

    # check if the architecture matches
    let compatible=1

    case "${DEB_BUILD_ARCH:-$DEB_BUILD_GNU_TYPE}" in
      amd64|x86_64-linux-gnu)
        if [[ "$j2se_arch" != "x64" ]]; then compatible=0; fi
        ;;
      *)
        compatible=0
        ;;
    esac

    if [[ $compatible == 0 ]]
    then
      echo "The archive $archive_name is not supported on the ${DEB_BUILD_ARCH} architecture"
      return
    fi


    cat << EOF

Detected product:
    Java(TM) Development Kit (JDK)
    Standard Edition, Version $j2se_version_name
    Oracle(TM)
EOF
    if read_yn "Is this correct [Y/n]: "; then
      j2se_found=true
      j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
      j2se_vendor="oracle"
      j2se_title="Java Platform, Standard Edition $j2se_release Development Kit"

      j2se_install=oracle_j9sdk_install
      j2se_remove=oracle_j9sdk_remove
      j2se_jinfo=oracle_j9sdk_jinfo
      j2se_control=oracle_j9sdk_control

      oracle_bin_hl="appletviewer idlj java javaws jcontrol jjs jrunscript jweblauncher keytool orbd pack200 rmid rmiregistry servertool tnameserv unpack200"
      oracle_lib_hl="jexec"
      oracle_bin_jdk="jaotc jar jarsigner javac javadoc javah javap javapackager jcmd jconsole jdb jdeprscan jdeps jhsdb jinfo jlink jmap jmod jps jshell jstack jstat jstatd policytool rmic schemagen serialver wsgen wsimport xjc"

      j2se_package="$j2se_vendor-java$j2se_release-jdk"
      j2se_run
    fi
  fi
}

oracle_j9sdk_install() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

install_no_man_alternatives $jvm_base$j2se_name/bin $oracle_bin_hl
install_no_man_alternatives $jvm_base$j2se_name/lib $oracle_lib_hl
install_no_man_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk
EOF
}

oracle_j9sdk_remove() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

remove_alternatives $jvm_base$j2se_name/bin $oracle_bin_hl
remove_alternatives $jvm_base$j2se_name/lib $oracle_lib_hl
remove_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk
EOF
}

oracle_j9sdk_jinfo() {
    cat << EOF
name=$j2se_name
priority=${priority_override:-$j2se_priority}
section=main
EOF
    jinfos "hl" $jvm_base$j2se_name/bin/ $oracle_bin_hl
    jinfos "hl" $jvm_base$j2se_name/lib/ $oracle_lib_hl
    jinfos "jdk" $jvm_base$j2se_name/bin/ $oracle_bin_jdk
}

oracle_j9sdk_control() {
    build_depends="libasound2, libgl1-mesa-glx, libgtk2.0-0, libxslt1.1, libxtst6, libxxf86vm1"
    j2se_control
    depends="\${shlibs:Depends}"
    if [ "$create_cert_softlinks" == "true" ]; then
        depends="$depends, ca-certificates-java"
    fi
    for i in `seq 5 ${j2se_release}`;
    do
        provides_runtime="${provides_runtime} java${i}-runtime,"
        provides_headless="${provides_headless} java${i}-runtime-headless,"
        provides_sdk="${provides_sdk} java${i}-sdk,"
    done
    cat << EOF
Package: $j2se_package
Architecture: $j2se_debian_arch
Depends: \${misc:Depends}, java-common, $depends
Recommends: netbase
Provides: java-virtual-machine, java-runtime, java2-runtime, $provides_runtime $java_browser_plugin java-compiler, java2-compiler, java-runtime-headless, java2-runtime-headless, $provides_headless java-sdk, java2-sdk, $provides_sdk
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
