# Detect product
j2se_detect_oracle_j2sdk=oracle_j2sdk_detect
oracle_j2sdk_detect() {
  j2se_release=0

  # Update or GA release (jdk-7u15-linux-i586.tar.gz)
  if [[ $archive_name =~ jdk-([0-9]+)(u([0-9]+))?-linux-(i586|x64|amd64|arm-vfp-hflt)\.(bin|tar\.gz) ]]
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

  # Early Access Release (jdk-8-ea-bin-b103-linux-i586-15_aug_2013.tar.gz)
  if [[ $archive_name =~ jdk-([0-9]+)(u([0-9]+))?-(ea|fcs)(-bin)?-(b[0-9]+)-linux-(i586|x64|amd64|arm-vfp-hflt).*\.(bin|tar\.gz) ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_build=${BASH_REMATCH[6]}
    j2se_arch=${BASH_REMATCH[7]}
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
      i386|i486-linux-gnu)
        if [[ "$j2se_arch" != "i586" ]]; then compatible=0; fi
        ;;
      amd64|x86_64-linux-gnu)
        if [[ "$j2se_arch" != "x64" && "$j2se_arch" != "amd64" ]]; then compatible=0; fi
        ;;
      armhf|armel|arm-linux-gnueabihf|arm-linux-gnueabi)
      case "$archive_name" in
        "jdk-7u"[0-9]"-linux-arm-sfp.tar.gz") # SUPPORTED
            j2se_version=1.7.0+update${archive_name:6:1}${revision}
            j2se_expected_min_size=100 #Mb
            j2se_priority=317
            found=true
            ;;
        "jdk-7u"[0-9][0-9]"-linux-arm-sfp.tar.gz") # SUPPORTED
            j2se_version=1.7.0+update${archive_name:6:2}${revision}
            j2se_expected_min_size=60 #Mb
            j2se_priority=317
            found=true
            ;;
      esac
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

      j2se_install=oracle_j2sdk_install
      j2se_remove=oracle_j2sdk_remove
      j2se_jinfo=oracle_j2sdk_jinfo
      j2se_control=oracle_j2sdk_control
      if [ "${DEB_BUILD_ARCH:0:3}" = "arm" ]; then
        # javaws is not available for ARM
        oracle_jre_bin_hl="java keytool orbd pack200 rmid rmiregistry servertool tnameserv unpack200 policytool"
        oracle_jre_bin_jre="policytool"
      else
        oracle_jre_bin_hl="java javaws keytool orbd pack200 rmid rmiregistry servertool tnameserv unpack200 policytool"
        oracle_jre_bin_jre="javaws policytool"
      fi
      if [ "${DEB_BUILD_ARCH:0:3}" != "arm" ]; then
        oracle_no_man_jre_bin_jre="ControlPanel jcontrol"
      fi
      oracle_jre_lib_hl="jexec"
      oracle_bin_jdk="appletviewer extcheck idlj jar jarsigner javac javadoc javah javap jcmd jconsole jdb jdeps jhat jinfo jmap jmc jps jrunscript jsadebugd jstack jstat jstatd jvisualvm native2ascii rmic schemagen serialver wsgen wsimport xjc"
      j2se_package="$j2se_vendor-java$j2se_release-jdk"
      j2se_run
    fi
  fi
}

oracle_j2sdk_install() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

if [ "x$without_alternatives" == "x" ]; then
    install_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_hl
    install_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_jre
    if [ -n "$oracle_no_man_jre_bin_jre" ]; then
        install_no_man_alternatives $jvm_base$j2se_name/jre/bin $oracle_no_man_jre_bin_jre
    fi
    install_no_man_alternatives $jvm_base$j2se_name/jre/lib $oracle_jre_lib_hl
    install_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk
fi

# No plugin for ARM architecture yet
if [ "${DEB_BUILD_ARCH:0:3}" != "arm" ]; then
plugin_dir="$jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH"
for b in $browser_plugin_dirs;do
    install_browser_plugin "/usr/lib/\$b/plugins" "libjavaplugin.so" "\$b-javaplugin.so" "\$plugin_dir/libnpjp2.so"
done
fi
EOF
}

oracle_j2sdk_remove() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

if [ "x$without_alternatives" == "x" ]; then
    remove_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_hl
    remove_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_jre
    if [ -n "$oracle_no_man_jre_bin_jre" ]; then
        remove_alternatives $jvm_base$j2se_name/jre/bin $oracle_no_man_jre_bin_jre
    fi
    remove_alternatives $jvm_base$j2se_name/jre/lib $oracle_jre_lib_hl
    remove_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk
fi

# No plugin for ARM architecture yet
if [ "${DEB_BUILD_ARCH:0:3}" != "arm" ]; then
plugin_dir="$jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH"
for b in $browser_plugin_dirs;do
    remove_browser_plugin "\$b-javaplugin.so" "\$plugin_dir/libnpjp2.so"
done
fi
EOF
}

oracle_j2sdk_jinfo() {
    cat << EOF
name=$j2se_name
priority=${priority_override:-$j2se_priority}
section=main
EOF
    jinfos "hl" $jvm_base$j2se_name/jre/bin/ $oracle_jre_bin_hl
    jinfos "jre" $jvm_base$j2se_name/jre/bin/ $oracle_jre_bin_jre
    if [ -n "$oracle_no_man_jre_bin_jre" ]; then
        jinfos "jre" $jvm_base$j2se_name/jre/bin/ $oracle_no_man_jre_bin_jre
    fi
    jinfos "hl" $jvm_base$j2se_name/jre/lib/ $oracle_jre_lib_hl
    jinfos "jdk" $jvm_base$j2se_name/bin/ $oracle_bin_jdk
    if [ "${DEB_BUILD_ARCH:0:3}" != "arm" ]; then
        for b in $browser_plugin_dirs;do
            echo "plugin iceweasel-javaplugin.so $jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH/libnpjp2.so"
        done
    fi
}

oracle_j2sdk_control() {
    build_depends="libasound2, libgl1-mesa-glx, libgtk2.0-0, libxslt1.1, libxtst6, libxxf86vm1"
    j2se_control
    java_browser_plugin="java-browser-plugin, "
    depends="\${shlibs:Depends}"
    if [ "${DEB_BUILD_ARCH:0:3}" = "arm" -a "${j2se_arch}" != "arm-vfp-hflt" ]; then
        # ARM is only softfloat ATM so if building on armhf
        # force the dependencies to pickup cross platform fu
        if [ "${DEB_BUILD_ARCH}" == "armhf" ]; then
            depends="libc6-armel, libsfgcc1, libsfstdc++6"
        fi
        # No browser on ARM yet
        java_browser_plugin=""
    fi
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
