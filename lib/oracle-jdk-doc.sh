# Detect product
oracle_j2sdk_doc_detect() {
  j2se_release=0

  # Update or GA release (jdk-7u25-apidocs.zip)
  if [[ $archive_name =~ jdk-([0-9]+)(u([0-9]+))?-apidocs\.zip ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update"
      j2se_version=${j2se_release}u${j2se_update}
    else
      j2se_version_name="$j2se_release GA"
      j2se_version=${j2se_release}
    fi
  fi

  # Early Access Release (jdk-8-ea-docs-b104-all-21_aug_2013.zip)
  if [[ $archive_name =~ jdk-([0-9]+)(u([0-9]+))?-(ea|fcs)-docs-(b[0-9]+)-all.*\.zip ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_build=${BASH_REMATCH[5]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}u${j2se_update}~ea-build-${j2se_build}
    else
      j2se_version_name="$j2se_release Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}~ea-build-${j2se_build}
    fi
  fi

  if [[ $j2se_release > 0 ]]
  then
    case "$j2se_release" in
    6) # JDK 6
      j2se_expected_min_size=44 #Mb
      ;;
    7) # JDK 7
      j2se_expected_min_size=290 #Mb
      ;;
    *) # JDK 8 and higher
      j2se_expected_min_size=320 #Mb
      ;;

    esac

    cat << EOF

Detected product:
    Java(TM) Development Kit (JDK) Documentation
    Standard Edition, Version $j2se_version_name
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

