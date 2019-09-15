#!/bin/bash
###############################################################################
#  Copyright (c) 2014-2019 libbitcoin-explorer developers (see COPYING).
#
#         GENERATED SOURCE CODE, DO NOT EDIT EXCEPT EXPERIMENTALLY
#
###############################################################################
# Script to build and install libbitcoin-explorer.
#
# Script options:
# --with-icu               Compile with International Components for Unicode.
#                            Since the addition of BIP-39 and later BIP-38
#                            support, libbitcoin conditionally incorporates ICU
#                            to provide BIP-38 and BIP-39 passphrase
#                            normalization features. Currently
#                            libbitcoin-explorer is the only other library that
#                            accesses this feature, so if you do not intend to
#                            use passphrase normalization this dependency can
#                            be avoided.
# --with-png               Compile with QR Code PNG Output Support
#                            Since the addition of png support, libbitcoin
#                            conditionally incorporates libpng (which in turn
#                            requires zlib). Currently libbitcoin-explorer is
#                            the only other library that accesses this feature,
#                            so if you do not intend to use png this dependency
#                            can be avoided.
# --with-qrencode          Compile with QR Code Support
#                            Since the addition of qrcode support, libbitcoin
#                            conditionally incorporates qrencode. Currently
#                            libbitcoin-explorer is the only other library that
#                            accesses this feature, so if you do not intend to
#                            use qrcode this dependency can be avoided.
# --build-icu              Builds ICU libraries.
# --build-zlib             Builds ZLib libraries.
# --build-png              Builds PNG libraries.
# --build-qrencode         Builds QREncode libraries.
# --build-boost            Builds Boost libraries.
# --build-zmq              Builds ZeroMQ libraries.
# --build-dir=<path>       Location of downloaded and intermediate files.
# --prefix=<absolute-path> Library install location (defaults to /usr/local).
# --disable-shared         Disables shared library builds.
# --disable-static         Disables static library builds.
# --help                   Display usage, overriding script execution.
#
# Verified on Ubuntu 14.04, requires gcc-4.8 or newer.
# Verified on OSX 10.10, using MacPorts and Homebrew repositories, requires
# Apple LLVM version 6.0 (clang-600.0.54) (based on LLVM 3.5svn) or newer.
# This script does not like spaces in the --prefix or --build-dir, sorry.
# Values (e.g. yes|no) in the '--disable-<linkage>' options are not supported.
# All command line options are passed to 'configure' of each repo, with
# the exception of the --build-<item> options, which are for the script only.
# Depending on the caller's permission to the --prefix or --build-dir
# directory, the script may need to be sudo'd.

# Define constants.
#==============================================================================
# The default build directory.
#------------------------------------------------------------------------------
BUILD_DIR="build-libbitcoin-explorer"

main()
{
    initialize_the_build_environment "$@"
    build
}

initialize_the_build_environment()
{
    enable_exit_on_first_error
    parse_command_line_options "$@"
    handle_help_line_option
    configure_build_parallelism
    define_operating_system_specific_settings
    link_to_standard_library_in_nondefault_scenarios
    write_configure_options "$@"
    handle_a_prefix
    display_configuration
    initialize_git
}

build()
{
    define_github_build_options

    if [[ $BUILD_ICU ]]; then
        build_from_tarball_icu
    else
        initialize_icu_packages
    fi
    if [[ "$BUILD_ZLIB" ]]; then
        build_from_tarball_zlib
    fi
    if [[ "$BUILD_PNG" ]]; then
        build_from_tarball_png
    fi
    if [[ "$BUILD_QRENCODE" ]]; then
        build_from_tarball_qrencode
    fi
    if [[ "$BUILD_BOOST" ]]; then
        build_from_tarball_boost
    fi
    if [[ "$BUILD_ZMQ" ]]; then
        build_from_tarball_zmq
    fi
    build_from_github libbitcoin secp256k1 version5 "${SECP256K1_OPTIONS[@]}"
    build_from_github libbitcoin libbitcoin-system master "${BITCOIN_SYSTEM_OPTIONS[@]}"
    build_from_github libbitcoin libbitcoin-protocol master "${BITCOIN_PROTOCOL_OPTIONS[@]}"
    build_from_github libbitcoin libbitcoin-client master "${BITCOIN_CLIENT_OPTIONS[@]}"
    build_from_github libbitcoin libbitcoin-network master "${BITCOIN_NETWORK_OPTIONS[@]}"
    if [[ $TRAVIS == true ]]; then
        # Because Travis alread has downloaded the primary repo.
        build_from_local_with_tests "${BITCOIN_EXPLORER_OPTIONS[@]}"
    else
        build_from_github_with_tests libbitcoin libbitcoin-explorer master "${BITCOIN_EXPLORER_OPTIONS[@]}"
    fi
}

# Initialize the build environment.
#==============================================================================
parse_command_line_options()
{
    for OPTION in "$@"; do
        case $OPTION in
            # Standard script options.
            (--help)                DISPLAY_HELP="yes";;

            # Standard build options.
            (--prefix=*)            PREFIX="${OPTION#*=}";;
            (--disable-shared)      DISABLE_SHARED="yes";;
            (--disable-static)      DISABLE_STATIC="yes";;

            # Common project options.
            (--with-icu)            WITH_ICU="yes";;
            (--with-png)            WITH_PNG="yes";;
            (--with-qrencode)       WITH_QRENCODE="yes";;

            # Custom build options (in the form of --build-<option>).
            (--build-icu)           BUILD_ICU="yes";;
            (--build-zlib)          BUILD_ZLIB="yes";;
            (--build-png)           BUILD_PNG="yes";;
            (--build-qrencode)      BUILD_QRENCODE="yes";;
            (--build-zmq)           BUILD_ZMQ="yes";;
            (--build-boost)         BUILD_BOOST="yes";;

            # Unique script options.
            (--build-dir=*)    BUILD_DIR="${OPTION#*=}";;
        esac
    done
}

handle_help_line_option()
{
    if [[ $DISPLAY_HELP ]]; then
        display_help
        exit 0
    fi
}

configure_build_parallelism()
{
    OS=$(uname -s)
    if [[ $PARALLEL ]]; then
        display_message "Using shell-defined PARALLEL value."
    elif [[ $OS == Linux ]]; then
        PARALLEL=$(nproc)
    elif [[ ($OS == Darwin) || ($OS == OpenBSD) ]]; then
        PARALLEL=$(sysctl -n hw.ncpu)
    else
        display_error "Unsupported system: $OS"
        display_error "  Explicit shell-definition of PARALLEL will avoid system detection."
        display_error ""
        display_help
        exit 1
    fi
}

define_operating_system_specific_settings()
{
    if [[ $OS == Darwin ]]; then
        export CC="clang"
        export CXX="clang++"
        STDLIB="c++"
    elif [[ $OS == OpenBSD ]]; then
        make() { gmake "$@"; }
        export CC="egcc"
        export CXX="eg++"
        STDLIB="estdc++"
    else # Linux
        STDLIB="stdc++"
    fi
}

link_to_standard_library_in_nondefault_scenarios()
{
    if [[ ($OS == Linux && $CC == "clang") || ($OS == OpenBSD) ]]; then
        export LDLIBS="-l$STDLIB $LDLIBS"
        export CXXFLAGS="-stdlib=lib$STDLIB $CXXFLAGS"
    fi
}

write_configure_options()
{
    CONFIGURE_OPTIONS=("$@")
    normalize_static_and_shared_options
    remove_build_options_from_configure_options
}

normalize_static_and_shared_options()
{
    if [[ $DISABLE_SHARED ]]; then
        CONFIGURE_OPTIONS=("${CONFIGURE_OPTIONS[@]}" "--enable-static")
    elif [[ $DISABLE_STATIC ]]; then
        CONFIGURE_OPTIONS=("${CONFIGURE_OPTIONS[@]}" "--enable-shared")
    else
        CONFIGURE_OPTIONS=("${CONFIGURE_OPTIONS[@]}" "--enable-shared")
        CONFIGURE_OPTIONS=("${CONFIGURE_OPTIONS[@]}" "--enable-static")
    fi
}

remove_build_options_from_configure_options()
{
    # Purge custom build options so they don't break configure.
    #------------------------------------------------------------------------------
    CONFIGURE_OPTIONS=("${CONFIGURE_OPTIONS[@]/--build-*/}")
}

handle_a_prefix()
{
    set_prefix
    incorporate_the_prefix
}

set_prefix()
{
    if [[ ! ($PREFIX) ]]; then
        PREFIX="/usr/local"
        CONFIGURE_OPTIONS=( "${CONFIGURE_OPTIONS[@]}" "--prefix=$PREFIX")
    else
        # Incorporate the custom libdir into each object, for runtime resolution.
        export LD_RUN_PATH="$PREFIX/lib"
    fi
}

incorporate_the_prefix()
{
    # Set the prefix-based package config directory.
    PREFIX_PKG_CONFIG_DIR="$PREFIX/lib/pkgconfig"

    # Prioritize prefix package config in PKG_CONFIG_PATH search path.
    export PKG_CONFIG_PATH="$PREFIX_PKG_CONFIG_DIR:$PKG_CONFIG_PATH"

    # Set a package config save path that can be passed via our builds.
    with_pkgconfigdir="--with-pkgconfigdir=$PREFIX_PKG_CONFIG_DIR"

    if [[ $BUILD_BOOST ]]; then
        # Boost has no pkg-config, m4 searches in the following order:
        # --with-boost=<path>, /usr, /usr/local, /opt, /opt/local, $BOOST_ROOT.
        # We use --with-boost to prioritize the --prefix path when we build it.
        # Otherwise standard paths suffice for Linux, Homebrew and MacPorts.
        # ax_boost_base.m4 appends /include and adds to BOOST_CPPFLAGS
        # ax_boost_base.m4 searches for /lib /lib64 and adds to BOOST_LDFLAGS
        with_boost="--with-boost=$PREFIX"
    fi
}

initialize_git()
{
    create_directory "$BUILD_DIR"
    push_directory "$BUILD_DIR"
    display_heading_message "Initialize git"

    # Initialize git repository at the root of the current directory.
    git init
    git config user.name anonymous
    pop_directory
}


# Define github build options.
#==============================================================================
define_github_build_options()
{
    define_secp256k1_options
    define_bitcoin_system_options
    define_bitcoin_protocol_options
    define_bitcoin_client_options
    define_bitcoin_network_options
    define_bitcoin_explorer_options
}

define_secp256k1_options()
{
    SECP256K1_OPTIONS=(
    "--disable-tests" \
    "--enable-module-recovery")
}

define_bitcoin_system_options()
{
    BITCOIN_SYSTEM_OPTIONS=(
    "--without-tests" \
    "--without-examples" \
    "${with_boost}" \
    "${with_pkgconfigdir}")
}

define_bitcoin_protocol_options()
{
    BITCOIN_PROTOCOL_OPTIONS=(
    "--without-tests" \
    "--without-examples" \
    "${with_boost}" \
    "${with_pkgconfigdir}")
}

define_bitcoin_client_options()
{
    BITCOIN_CLIENT_OPTIONS=(
    "--without-tests" \
    "--without-examples" \
    "${with_boost}" \
    "${with_pkgconfigdir}")
}

define_bitcoin_network_options()
{
    BITCOIN_NETWORK_OPTIONS=(
    "--without-tests" \
    "${with_boost}" \
    "${with_pkgconfigdir}")
}

define_bitcoin_explorer_options()
{
    BITCOIN_EXPLORER_OPTIONS=(
    "${with_boost}" \
    "${with_pkgconfigdir}")
}


# Define build functions.
#==============================================================================
build_from_tarball_icu()
{
    local URL="http://download.icu-project.org/files/icu4c/55.1/icu4c-55_1-src.tgz"
    local ARCHIVE="icu4c-55_1-src.tgz"
    local COMPRESSION="gzip"
    local OPTIONS=(
    "--enable-draft" \
    "--enable-tools" \
    "--disable-extras" \
    "--disable-icuio" \
    "--disable-layout" \
    "--disable-layoutex" \
    "--disable-tests" \
    "--disable-samples")

    local SAVE_LDFLAGS=$LDFLAGS
    export LDFLAGS="-L$PREFIX/lib $LDFLAGS"

    change_dir_for_build_and_download_and_extract "$ARCHIVE" "$URL" "$COMPRESSION"
    push_directory "source"
    configure_and_make_and_install "${OPTIONS[@]}"

    pop_directory
    pop_directory
    pop_directory

    # Restore flags to prevent side effects.
    export LDFLAGS=$SAVE_LDFLAGS
}

# Because PKG_CONFIG_PATH doesn't get updated by Homebrew or MacPorts.
initialize_icu_packages()
{
    if [[ ($OS == Darwin) ]]; then
        # Update PKG_CONFIG_PATH for ICU package installations on OSX.
        # OSX provides libicucore.dylib with no pkgconfig and doesn't support
        # renaming or important features, so we can't use that.
        local HOMEBREW_ICU_PKG_CONFIG="/usr/local/opt/icu4c/lib/pkgconfig"
        local MACPORTS_ICU_PKG_CONFIG="/opt/local/lib/pkgconfig"

        if [[ -d "$HOMEBREW_ICU_PKG_CONFIG" ]]; then
            export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$HOMEBREW_ICU_PKG_CONFIG"
        elif [[ -d "$MACPORTS_ICU_PKG_CONFIG" ]]; then
            export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$MACPORTS_ICU_PKG_CONFIG"
        fi
    fi
}

build_from_tarball_zlib()
{
    local URL="https://github.com/madler/zlib/archive/v1.2.9.tar.gz"
    local ARCHIVE="v1.2.9.tar.gz"
    local COMPRESSION="gzip"

    change_dir_for_build_and_download_and_extract "$ARCHIVE" "$URL" "$COMPRESSION"

    # Enable static only zlib build.
    patch_zlib_configuration
    configure_and_make_and_install

    clean_zlib_build

    pop_directory
    pop_directory
}

# Because ZLIB doesn't actually parse its --disable-shared option.
# Because ZLIB doesn't follow GNU recommentation for unknown arguments.
patch_zlib_configuration()
{
    sed -i.tmp "s/leave 1/shift/" configure
    sed -i.tmp "s/--static/--static | --disable-shared/" configure
    sed -i.tmp "/unknown option/d" configure
    sed -i.tmp "/help for help/d" configure

    # display_message "Hack: ZLIB configuration options modified."
}

# Because ZLIB can't build shared only.
clean_zlib_build()
{
    if [[ $DISABLE_STATIC ]]; then
        rm --force "$PREFIX/lib/libz.a"
    fi
}

build_from_tarball_png()
{
    local URL="http://downloads.sourceforge.net/project/libpng/libpng16/older-releases/1.6.29/libpng-1.6.29.tar.xz"
    local ARCHIVE="libpng-1.6.29.tar.xz"
    local COMPRESSION="xz"

    # Because libpng doesn't actually use pkg-config to locate zlib.
    local SAVE_LDFLAGS=$LDFLAGS
    export LDFLAGS="-L$PREFIX/lib $LDFLAGS"

    # Because libpng doesn't actually use pkg-config to locate zlib.h.
    local SAVE_CPPFLAGS=$CPPFLAGS
    export CPPFLAGS="-I$PREFIX/include $CPPFLAGS"

    change_dir_for_build_and_download_and_extract "$ARCHIVE" "$URL" "$COMPRESSION"
    configure_and_make_and_install

    pop_directory
    pop_directory

    # Restore flags to prevent side effects.
    export LDFLAGS=$SAVE_LDFLAGS
    export CPPFLAGS=$SAVE_CPPFLAGS
}

build_from_tarball_qrencode()
{
    local URL="http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.bz2"
    local ARCHIVE="qrencode-3.4.4.tar.bz2"
    local COMPRESSION="bzip2"

    change_dir_for_build_and_download_and_extract "$ARCHIVE" "$URL" "$COMPRESSION"
    configure_and_make_and_install

    pop_directory
    pop_directory
}

# Because boost doesn't use autoconfig.
build_from_tarball_boost()
{
    local URL="http://downloads.sourceforge.net/project/boost/boost/1.62.0/boost_1_62_0.tar.bz2"
    local ARCHIVE="boost_1_62_0.tar.bz2"
    local COMPRESSION="bzip2"
    local OPTIONS=(
    "--with-atomic" \
    "--with-chrono" \
    "--with-date_time" \
    "--with-filesystem" \
    "--with-iostreams" \
    "--with-locale" \
    "--with-log" \
    "--with-program_options" \
    "--with-regex" \
    "--with-system" \
    "--with-thread" \
    "--with-test")

    change_dir_for_build_and_download_and_extract "$ARCHIVE" "$URL" "$COMPRESSION"
    initialize_boost_configuration
    initialize_boost_icu_configuration
    display_boost_configuration "${OPTIONS[@]}"

    # boost_iostreams
    # The zlib options prevent boost linkage to system libs in the case where
    # we have built zlib in a prefix dir. Disabling zlib in boost is broken in
    # all versions (through 1.60). https://svn.boost.org/trac/boost/ticket/9156
    # The bzip2 auto-detection is not implemented, but disabling it works.

    ./bootstrap.sh \
        "--prefix=$PREFIX" \
        "--with-icu=$ICU_PREFIX"

    ./b2 install \
        "variant=release" \
        "threading=multi" \
        "$BOOST_TOOLSET" \
        "$BOOST_CXXFLAGS" \
        "$BOOST_LINKFLAGS" \
        "link=$BOOST_LINK" \
        "boost.locale.iconv=$BOOST_ICU_ICONV" \
        "boost.locale.posix=$BOOST_ICU_POSIX" \
        "-sNO_BZIP2=1" \
        "-sICU_PATH=$ICU_PREFIX" \
        "-sICU_LINK=${ICU_LIBS[@]}" \
        "-sZLIB_LIBPATH=$PREFIX/lib" \
        "-sZLIB_INCLUDE=$PREFIX/include" \
        "-j $PARALLEL" \
        "-d0" \
        "-q" \
        "--reconfigure" \
        "--prefix=$PREFIX" \
        "${OPTIONS[@]}"

    pop_directory
    pop_directory
}

# Because boost ICU detection assumes in incorrect ICU path.
circumvent_boost_icu_detection()
{
    # Boost expects a directory structure for ICU which is incorrect.
    # Boost ICU discovery fails when using prefix, can't fix with -sICU_LINK,
    # so we rewrite the two 'has_icu_test.cpp' files to always return success.

    local SUCCESS="int main() { return 0; }"
    local REGEX_TEST="libs/regex/build/has_icu_test.cpp"
    local LOCALE_TEST="libs/locale/build/has_icu_test.cpp"

    printf "%s" "$SUCCESS" > $REGEX_TEST
    printf "%s" "$SUCCESS" > $LOCALE_TEST

    # display_message "Hack: ICU detection modified, will always indicate found."
}

# Because boost doesn't support autoconfig and doesn't like empty settings.
initialize_boost_configuration()
{
    if [[ $DISABLE_STATIC ]]; then
        BOOST_LINK="shared"
    elif [[ $DISABLE_SHARED ]]; then
        BOOST_LINK="static"
    else
        BOOST_LINK="static,shared"
    fi

    if [[ $CC ]]; then
        BOOST_TOOLSET="toolset=$CC"
    fi

    if [[ ($OS == Linux && $CC == "clang") || ($OS == OpenBSD) ]]; then
        STDLIB_FLAG="-stdlib=lib$STDLIB"
        BOOST_CXXFLAGS="cxxflags=$STDLIB_FLAG"
        BOOST_LINKFLAGS="linkflags=$STDLIB_FLAG"
    fi
}

# Because boost doesn't use pkg-config.
initialize_boost_icu_configuration()
{
    BOOST_ICU_ICONV="on"
    BOOST_ICU_POSIX="on"

    if [[ $WITH_ICU ]]; then
        circumvent_boost_icu_detection

        # Restrict other locale options when compiling boost with icu.
        BOOST_ICU_ICONV="off"
        BOOST_ICU_POSIX="off"

        # Extract ICU libs from package config variables and augment with -ldl.
        ICU_LIBS="$(pkg-config icu-i18n --libs) -ldl"

        # This is a hack for boost m4 scripts that fail with ICU dependency.
        # See custom edits in ax-boost-locale.m4 and ax_boost_regex.m4.
        export BOOST_ICU_LIBS=("${ICU_LIBS[@]}")

        # Extract ICU prefix directory from package config variable.
        ICU_PREFIX=$(pkg-config icu-i18n --variable=prefix)
    fi
}

build_from_tarball_zmq()
{
    local URL="https://github.com/zeromq/libzmq/releases/download/v4.3.2/zeromq-4.3.2.tar.gz"
    local ARCHIVE="zeromq-4.3.2.tar.gz"
    local COMPRESSION="gzip"

    change_dir_for_build_and_download_and_extract "$ARCHIVE" "$URL" "$COMPRESSION"
    configure_and_make_and_install

    pop_directory
    pop_directory
}

# Standard build from github.
build_from_github()
{
    local ACCOUNT=$1
    local REPO=$2
    local BRANCH=$3
    shift 3
    local OPTIONS=("$@")

    FORK="$ACCOUNT/$REPO"
    push_directory "$BUILD_DIR"
    display_heading_message "Download $FORK/$BRANCH"

    # Clone the repository locally.
    git clone --depth 1 --branch "$BRANCH" --single-branch "https://github.com/$FORK"

    # Build the local repository clone.
    push_directory "$REPO"
    autogen_and_configure_and_make_and_install "${OPTIONS[@]}"
    pop_directory
    pop_directory
}

build_from_local_with_tests()
{
    local OPTIONS=("$@")
    build_from_local "Local $TRAVIS_REPO_SLUG" "${OPTIONS[@]}"
    make_tests
}

# Standard build of current directory.
build_from_local()
{
    local MESSAGE="$1"
    shift 1
    local OPTIONS=("$@")

    display_heading_message "$MESSAGE"

    # Build the current directory.
    autogen_and_configure_and_make_and_install "${OPTIONS[@]}"
}

build_from_github_with_tests()
{
    local ACCOUNT=$1
    local REPO=$2
    local BRANCH=$3
    shift 3
    local OPTIONS=("$@")

    build_from_github "$ACCOUNT" "$REPO" "$BRANCH" "${OPTIONS[@]}"
    push_directory "$BUILD_DIR"
    push_directory "$REPO"
    make_tests
    pop_directory
    pop_directory
}


# Define utility functions.
#==============================================================================
enable_exit_on_first_error()
{
    set -e
}

disable_exit_on_first_error()
{
    set +e
}

configure_links()
{
    # Configure dynamic linker run-time bindings when installing to system.
    if [[ ($OS == Linux) && ($PREFIX == "/usr/local") ]]; then
        ldconfig
    fi
}

change_dir_for_build_and_download_and_extract()
{
    local ARCHIVE=$1
    local URL=$2
    local COMPRESSION=$3

    # Use the suffixed archive name as the extraction directory.
    local EXTRACT="build-$ARCHIVE"
    push_directory "$BUILD_DIR"
    create_directory "$EXTRACT"
    push_directory "$EXTRACT"

    # Extract the source locally.
    display_heading_message "Download $ARCHIVE"
    wget --output-document "$ARCHIVE" "$URL"
    tar --extract --file "$ARCHIVE" --"$COMPRESSION" --strip-components=1
}

configure_and_make_and_install()
{
    local OPTIONS=("$@")
    local CONFIGURATION=("${OPTIONS[@]}" "${CONFIGURE_OPTIONS[@]}")

    configure_options "${CONFIGURATION[@]}"
    make_jobs --silent
    make install
    configure_links
}

autogen_and_configure_and_make_and_install()
{
    local OPTIONS=("$@")
    local CONFIGURATION=("${OPTIONS[@]}" "${CONFIGURE_OPTIONS[@]}")

    ./autogen.sh
    configure_options "${CONFIGURATION[@]}"
    make_jobs
    make install
    configure_links
}

make_jobs()
{
    local JOBS="$PARALLEL"

    # Avoid setting -j1 (causes problems on Travis).
    local SEQUENTIAL=1
    if [[ $JOBS > $SEQUENTIAL ]]; then
        make -j"$JOBS" "$@"
    else
        make "$@"
    fi
}

configure_options()
{
    display_message "configure options:"
    for OPTION in "$@"; do
        if [[ $OPTION ]]; then
            display_message $OPTION
        fi
    done

    ./configure "$@"
}

make_tests()
{
    disable_exit_on_first_error

    # Build and run unit tests relative to the primary directory.
    # VERBOSE=1 ensures test runner output sent to console (gcc).
    make_jobs check "VERBOSE=1"
    local RESULT=$?

    # Test runners emit to the test.log file.
    if [[ -e "test.log" ]]; then
        cat "test.log"
    fi

    if [[ $RESULT -ne 0 ]]; then
        exit $RESULT
    fi

    enable_exit_on_first_error
}

create_directory()
{
    local DIRECTORY="$1"

    rm -rf "$DIRECTORY"
    mkdir "$DIRECTORY"
}

pop_directory()
{
    popd >/dev/null
}

push_directory()
{
    local DIRECTORY="$1"

    pushd "$DIRECTORY" >/dev/null
}


# Define display functions.
#==============================================================================
display_heading_message()
{
    printf "\n********************** %s **********************\n" "$@"
}

display_message()
{
    printf "%s\n" "$@"
}

display_error()
{
    >&2 printf "%s\n" "$@"
}

display_configuration()
{
    display_message "libbitcoin-explorer installer configuration."
    display_message "--------------------------------------------------------------------"
    display_message "OS                    : $OS"
    display_message "PARALLEL              : $PARALLEL"
    display_message "CC                    : $CC"
    display_message "CXX                   : $CXX"
    display_message "CPPFLAGS              : $CPPFLAGS"
    display_message "CFLAGS                : $CFLAGS"
    display_message "CXXFLAGS              : $CXXFLAGS"
    display_message "LDFLAGS               : $LDFLAGS"
    display_message "LDLIBS                : $LDLIBS"
    display_message "WITH_ICU              : $WITH_ICU"
    display_message "WITH_PNG              : $WITH_PNG"
    display_message "WITH_QRENCODE         : $WITH_QRENCODE"
    display_message "BUILD_ICU             : $BUILD_ICU"
    display_message "BUILD_ZLIB            : $BUILD_ZLIB"
    display_message "BUILD_PNG             : $BUILD_PNG"
    display_message "BUILD_QRENCODE        : $BUILD_QRENCODE"
    display_message "BUILD_ZMQ             : $BUILD_ZMQ"
    display_message "BUILD_BOOST           : $BUILD_BOOST"
    display_message "BUILD_DIR             : $BUILD_DIR"
    display_message "PREFIX                : $PREFIX"
    display_message "DISABLE_SHARED        : $DISABLE_SHARED"
    display_message "DISABLE_STATIC        : $DISABLE_STATIC"
    display_message "with_boost            : ${with_boost}"
    display_message "with_pkgconfigdir     : ${with_pkgconfigdir}"
    display_message "--------------------------------------------------------------------"
}

display_help()
{
    display_message "Usage: ./install.sh [OPTION]..."
    display_message "Manage the installation of libbitcoin-explorer."
    display_message "Script options:"
    display_message "  --with-icu               Compile with International Components for Unicode."
    display_message "                             Since the addition of BIP-39 and later BIP-38 "
    display_message "                             support, libbitcoin conditionally incorporates ICU "
    display_message "                             to provide BIP-38 and BIP-39 passphrase "
    display_message "                             normalization features. Currently "
    display_message "                             libbitcoin-explorer is the only other library that "
    display_message "                             accesses this feature, so if you do not intend to "
    display_message "                             use passphrase normalization this dependency can "
    display_message "                             be avoided."
    display_message "  --with-png               Compile with QR Code PNG Output Support"
    display_message "                             Since the addition of png support, libbitcoin "
    display_message "                             conditionally incorporates libpng (which in turn "
    display_message "                             requires zlib). Currently libbitcoin-explorer is "
    display_message "                             the only other library that accesses this feature, "
    display_message "                             so if you do not intend to use png this dependency "
    display_message "                             can be avoided."
    display_message "  --with-qrencode          Compile with QR Code Support"
    display_message "                             Since the addition of qrcode support, libbitcoin "
    display_message "                             conditionally incorporates qrencode. Currently "
    display_message "                             libbitcoin-explorer is the only other library that "
    display_message "                             accesses this feature, so if you do not intend to "
    display_message "                             use qrcode this dependency can be avoided."
    display_message "  --build-icu              Builds ICU libraries."
    display_message "  --build-zlib             Builds ZLib libraries."
    display_message "  --build-png              Builds PNG libraries."
    display_message "  --build-qrencode         Builds QREncode libraries."
    display_message "  --build-boost            Builds Boost libraries."
    display_message "  --build-zmq              Build ZeroMQ libraries."
    display_message "  --build-dir=<path>       Location of downloaded and intermediate files."
    display_message "  --prefix=<absolute-path> Library install location (defaults to /usr/local)."
    display_message "  --disable-shared         Disables shared library builds."
    display_message "  --disable-static         Disables static library builds."
    display_message "  --help                   Display usage, overriding script execution."
    display_message ""
    display_message "All unrecognized options provided shall be passed as configuration options for "
    display_message "all dependencies."
}

display_boost_configuration()
{
    display_message "Libbitcoin boost configuration."
    display_message "--------------------------------------------------------------------"
    display_message "variant               : release"
    display_message "threading             : multi"
    display_message "toolset               : $CC"
    display_message "cxxflags              : $STDLIB_FLAG"
    display_message "linkflags             : $STDLIB_FLAG"
    display_message "link                  : $BOOST_LINK"
    display_message "boost.locale.iconv    : $BOOST_ICU_ICONV"
    display_message "boost.locale.posix    : $BOOST_ICU_POSIX"
    display_message "-sNO_BZIP2            : 1"
    display_message "-sICU_PATH            : $ICU_PREFIX"
    display_message "-sICU_LINK            : " "${ICU_LIBS[@]}"
    display_message "-sZLIB_LIBPATH        : $PREFIX/lib"
    display_message "-sZLIB_INCLUDE        : $PREFIX/include"
    display_message "-j                    : $PARALLEL"
    display_message "-d0                   : [supress informational messages]"
    display_message "-q                    : [stop at the first error]"
    display_message "--reconfigure         : [ignore cached configuration]"
    display_message "--prefix              : $PREFIX"
    display_message "BOOST_OPTIONS         : " "$@"
    display_message "--------------------------------------------------------------------"
}

main "$@"
