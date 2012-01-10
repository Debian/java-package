# Detect product
function oracle_j2sdk_doc_detect() {
  local found=
      case "$archive_name" in
	"jdk-6u"[0-9][0-9]"-apidocs.zip") # SUPPORTED
	    j2se_version=1.6.0+update${archive_name:6:2}${revision}
	    j2se_expected_min_size=44 #Mb
	    found=true
	    ;;
	"jdk-7u"[0-9]"-apidocs.zip") # SUPPORTED
	    j2se_version=1.7.0+update${archive_name:6:1}${revision}
	    j2se_expected_min_size=290 #Mb
	    found=true
	    ;;
      esac
  if [[ -n "$found" ]]; then
	cat << EOF

Detected product:
    Java(TM) Development Kit (JDK) Documentation
    Standard Edition, Version $j2se_version
    Oracle(TM), Inc.
EOF
	if read_yn "Is this correct [Y/n]: "; then
	    j2se_found=true
	    j2se_release="${j2se_version:0:3}"
	    j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
	    j2se_vendor="oracle"
	    j2se_title="Java(TM) JDK, Standard Edition, Oracle(TM) Documentation"
	    j2sdk_doc_run
	fi
    fi
}

j2se_detect_j2sdk_doc_oracle=oracle_j2sdk_doc_detect
