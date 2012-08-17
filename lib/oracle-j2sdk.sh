# Detect product
j2se_detect_oracle_j2sdk=oracle_j2sdk_detect
oracle_j2sdk_detect() {

  if [[ $archive_name =~ jdk-([0-9]+)u([0-9]+)-linux-(i586|x64)\.(bin|tar\.gz) ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[2]}
    j2se_arch=${BASH_REMATCH[3]}
    j2se_version=$j2se_release.$j2se_update
    j2se_priority=$((310 + $j2se_release))
    j2se_expected_min_size=130 #Mb

    # check if the architecture matches
    let compatible=1
  
    case "${DEB_BUILD_ARCH:-$DEB_BUILD_GNU_TYPE}" in
      i386|i486-linux-gnu)
        if [[ "$j2se_arch" != "i586" ]]; then compatible=0; fi
        ;;
      amd64|x86_64-linux-gnu)
        if [[ "$j2se_arch" != "x64" ]]; then compatible=0; fi
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
    Standard Edition, Version $j2se_release Update $j2se_update
    Oracle(TM)
EOF
    if read_yn "Is this correct [Y/n]: "; then
      j2se_found=true
      j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
      j2se_vendor="oracle"
      j2se_title="Java(TM) JDK, Standard Edition, Oracle(TM)"

      j2se_install=oracle_j2sdk_install
      j2se_remove=oracle_j2sdk_remove
      j2se_jinfo=oracle_j2sdk_jinfo
      oracle_jre_bin_hl="java javaws keytool orbd pack200 rmid rmiregistry servertool tnameserv unpack200 policytool"
      oracle_jre_bin_jre="javaws policytool"
      oracle_no_man_jre_bin_jre="ControlPanel"
      oracle_jre_lib_hl="jexec"
      oracle_bin_jdk="appletviewer extcheck idlj jar jarsigner javac javadoc javah javap jconsole jdb jinfo jmap jps jsadebugd jstack jstat jstatd native2ascii rmic serialver"
      j2sdk_run
    fi
  fi
}

oracle_j2sdk_install() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

install_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_hl
install_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_jre
install_no_man_alternatives $jvm_base$j2se_name/jre/bin $oracle_no_man_jre_bin_jre
install_no_man_alternatives $jvm_base$j2se_name/jre/lib $oracle_jre_lib_hl
install_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk

plugin_dir="$jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH"
install_browser_plugin "/usr/lib/iceweasel/plugins" "libjavaplugin.so" "iceweasel-javaplugin.so" "\$plugin_dir/libnpjp2.so"
install_browser_plugin "/usr/lib/chromium/plugins" "libjavaplugin.so" "chromium-javaplugin.so" "\$plugin_dir/libnpjp2.so"
install_browser_plugin "/usr/lib/mozilla/plugins" "libjavaplugin.so" "mozilla-javaplugin.so" "\$plugin_dir/libnpjp2.so"
install_browser_plugin "/usr/lib/firefox/plugins" "libjavaplugin.so" "firefox-javaplugin.so" "\$plugin_dir/libnpjp2.so"
EOF
}

oracle_j2sdk_remove() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

remove_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_hl
remove_alternatives $jvm_base$j2se_name/jre/bin $oracle_jre_bin_jre
remove_alternatives $jvm_base$j2se_name/jre/bin $oracle_no_man_jre_bin_jre
remove_alternatives $jvm_base$j2se_name/jre/lib $oracle_jre_lib_hl
remove_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk

plugin_dir="$jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH"
remove_browser_plugin "iceweasel-javaplugin.so" "\$plugin_dir/libnpjp2.so"
remove_browser_plugin "chromium-javaplugin.so" "\$plugin_dir/libnpjp2.so"
remove_browser_plugin "mozilla-javaplugin.so" "\$plugin_dir/libnpjp2.so"
remove_browser_plugin "firefox-javaplugin.so" "\$plugin_dir/libnpjp2.so"
EOF
}

oracle_j2sdk_jinfo() {
    cat << EOF
name=$j2se_name
priority=$j2se_priority
section=main
EOF
    jinfos "hl" $jvm_base$j2se_name/jre/bin/ $oracle_jre_bin_hl
    jinfos "jre" $jvm_base$j2se_name/jre/bin/ $oracle_jre_bin_jre
    jinfos "jre" $jvm_base$j2se_name/jre/bin/ $oracle_no_man_jre_bin_jre
    jinfos "hl" $jvm_base$j2se_name/jre/lib/ $oracle_jre_lib_hl
    jinfos "jdk" $jvm_base$j2se_name/bin/ $oracle_bin_jdk
    echo "plugin iceweasel-javaplugin.so $jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH/libnpjp2.so"
    echo "plugin chromium-javaplugin.so $jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH/libnpjp2.so"
}
