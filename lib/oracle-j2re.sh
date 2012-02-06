# Detect product
j2se_detect_oracle_j2re=oracle_j2re_detect
oracle_j2re_detect() {
  local found=
  
  case "${DEB_BUILD_ARCH:-$DEB_BUILD_GNU_TYPE}" in
    i386|i486-linux-gnu)
      case "$archive_name" in
	"jre-6u"[0-9][0-9]"-linux-i586.bin") # SUPPORTED
	    j2se_version=1.6.0+update${archive_name:6:2}${revision}
	    j2se_expected_min_size=16 #Mb
	    j2se_priority=314
	    found=true
	    ;;
	"jre-7u"[0-9]"-linux-i586.tar.gz") # SUPPORTED
	    j2se_version=1.7.0+update${archive_name:6:1}${revision}
	    j2se_expected_min_size=94 #Mb
	    j2se_priority=316
	    found=true
	    ;;
      esac
      ;;
    amd64|x86_64-linux-gnu)
      case "$archive_name" in
	"jre-6u"[0-9][0-9]"-linux-x64.bin") # SUPPORTED
	    j2se_version=1.6.0+update${archive_name:6:2}${revision}
	    j2se_expected_min_size=16 #Mb
	    j2se_priority=314
	    found=true
	    ;;
	"jre-7u"[0-9]"-linux-x64.tar.gz") # SUPPORTED
	    j2se_version=1.7.0+update${archive_name:6:1}${revision}
	    j2se_expected_min_size=88 #Mb
	    j2se_priority=316
	    found=true
	    ;;
      esac
      ;;
  esac
  if [[ -n "$found" ]]; then
	cat << EOF

Detected product:
    Java(TM) Runtime Environment (JRE)
    Standard Edition, Version $j2se_version
    Oracle(TM)
EOF
	if read_yn "Is this correct [Y/n]: "; then
	    j2se_found=true
	    j2se_release="${j2se_version:0:3}"
	    j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
	    j2se_vendor="oracle"
	    j2se_title="Java(TM) JRE, Standard Edition, Oracle(TM)"

	    j2se_install=oracle_j2re_install
	    j2se_remove=oracle_j2re_remove
	    j2se_jinfo=oracle_j2re_jinfo
	    oracle_jre_bin_hl="java javaws keytool orbd pack200 rmid rmiregistry servertool tnameserv unpack200 policytool"
	    oracle_jre_bin_jre="javaws policytool"
	    oracle_no_man_jre_bin_jre="ControlPanel"
	    oracle_jre_lib_hl="jexec"
	    j2re_run
	fi
    fi
}

oracle_j2re_install() {
	cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

install_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_hl
install_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_jre
install_no_man_alternatives $jvm_base$j2se_name/bin $oracle_no_man_jre_bin_jre
install_no_man_alternatives $jvm_base$j2se_name/lib $oracle_jre_lib_hl

plugin_dir="$jvm_base$j2se_name/lib/$DEB_BUILD_ARCH"
install_browser_plugin "/usr/lib/iceweasel/plugins" "libjavaplugin.so" "iceweasel-javaplugin.so" "\$plugin_dir/libnpjp2.so"
install_browser_plugin "/usr/lib/chromium/plugins" "libjavaplugin.so" "chromium-javaplugin.so" "\$plugin_dir/libnpjp2.so"
EOF
}

oracle_j2re_remove() {
	cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

remove_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_hl
remove_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_jre
remove_alternatives $jvm_base$j2se_name/bin $oracle_no_man_jre_bin_jre
remove_alternatives $jvm_base$j2se_name/lib $oracle_jre_lib_hl

plugin_dir="$jvm_base$j2se_name/lib/$DEB_BUILD_ARCH"
remove_browser_plugin "iceweasel-javaplugin.so" "\$plugin_dir/libnpjp2.so"
remove_browser_plugin "chromium-javaplugin.so" "\$plugin_dir/libnpjp2.so"
EOF
}

oracle_j2re_jinfo() {
    cat << EOF
name=$j2se_name
priority=$j2se_priority
section=main
EOF
    jinfos "hl" $jvm_base$j2se_name/bin/ $oracle_jre_bin_hl
    jinfos "jre" $jvm_base$j2se_name/bin/ $oracle_jre_bin_jre
    jinfos "jre" $jvm_base$j2se_name/bin/ $oracle_no_man_jre_bin_jre
    jinfos "hl" $jvm_base$j2se_name/lib/ $oracle_jre_lib_hl
    echo "plugin iceweasel-javaplugin.so $jvm_base$j2se_name/lib/$DEB_BUILD_ARCH/libnpjp2.so"
    echo "plugin chromium-javaplugin.so $jvm_base$j2se_name/lib/$DEB_BUILD_ARCH/libnpjp2.so"
}

