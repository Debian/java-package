# Detect product
oracle_j2sdk_doc_detect() {

  if [[ $archive_name =~ jdk-([0-9]+)u([0-9]+)-apidocs\.zip ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[2]}
    j2se_version=$j2se_release.$j2se_update
    
    case "$j2se_release" in
    6) # JDK 6
	  j2se_expected_min_size=44 #Mb
	  ;;
	*) # JDK 7 and higher
	  j2se_expected_min_size=290 #Mb
	  ;;
    esac

	cat << EOF

Detected product:
    Java(TM) Development Kit (JDK) Documentation
    Standard Edition, Version $j2se_release Update $j2se_update
    Oracle(TM)
EOF
	if read_yn "Is this correct [Y/n]: "; then
	    j2se_found=true
	    j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
	    j2se_vendor="oracle"
	    j2se_title="Java(TM) JDK, Standard Edition, Oracle(TM) Documentation"

	    j2se_install=oracle_j2sdk_doc_install
	    j2se_remove=oracle_j2sdk_doc_remove
	    j2sdk_doc_run
	fi
    fi
}

j2se_detect_j2sdk_doc_oracle=oracle_j2sdk_doc_detect

oracle_j2sdk_doc_install() {
	cat << EOF
if [ ! -e "$javadoc_base$j2se_name" ]; then
    exit 0
fi

# Register the documentation in the various documentation systems, i.e. dhelp and dwww.
if [ "\$1" = configure ] ; then
    if which install-docs >/dev/null 2>&1; then
        install-docs -i $javadoc_base$j2se_name
    fi
fi
EOF
}

oracle_j2sdk_doc_remove() {
	cat << EOF
if [ ! -e "$javadoc_base$j2se_name" ]; then
    exit 0
fi

# Unregister documentation from the various documentation systems, i.e. dhelp and dwww.
if [ "\$1" = configure ] ; then
    if which install-docs >/dev/null 2>&1; then
        install-docs -r $javadoc_base$j2se_name
    fi
fi
EOF
}

