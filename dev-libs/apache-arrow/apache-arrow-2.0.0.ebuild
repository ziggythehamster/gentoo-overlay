# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8,9} )
inherit python-single-r1
inherit cmake-multilib

CMAKE_BUILD_TYPE=Release
DESCRIPTION="Columnar in-memory analytics layer designed to accelerate big data"
HOMEPAGE="https://arrow.apache.org/"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
IUSE="cpu_flags_x86_avx2 cpu_flags_x86_avx512f cpu_flags_x86_sse4_2 brotli bz2 jemalloc lz4 s3 snappy tensorflow test zlib zstd"
KEYWORDS="~amd64"
LICENSE="Apache-2.0"
SLOT="0/${PV}"

JEMALLOC_VERSION="5.2.1"
RAPIDJSON_GIT_COMMIT="1a803826f1197b5e30703afe4b9c0e7dd48074f5"

SRC_URI="
	mirror://apache/arrow/arrow-${PV}/apache-arrow-${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/Tencent/rapidjson/archive/${RAPIDJSON_GIT_COMMIT}.tar.gz -> ${P}-vendored-rapidjson.tar.gz

	jemalloc? (
		https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 -> ${P}-vendored-jemalloc.tar.bz2
	)
	test? (
		https://github.com/apache/arrow-testing/archive/860376d4e586a3ac34ec93089889da624ead6c2a.tar.gz -> ${P}-testing.tar.gz
		https://github.com/apache/parquet-testing/archive/d914f9d289488c7db1759d7a88a4a1b8f062c7dd.tar.gz -> ${P}-parquet-testing.tar.gz
	)
"

S="${WORKDIR}/${P}/cpp"

# CMake 3.18 had some problems handling their complicated CMake config
BDEPEND="
	${PYTHON_DEPS}
	>=dev-util/cmake-3.20.0
	test? (
		>=dev-cpp/gtest-1.10.0
	)
"

RDEPEND="
	brotli? ( >=app-arch/brotli-1.0.7 )
	bz2? ( >=app-arch/bzip2-1.0.8 )
	lz4? ( >=app-arch/lz4-1.9.2 )
	s3? ( >=dev-libs/aws-sdk-cpp-1.8.57[access-management,config,s3] )
	snappy? ( >=app-arch/snappy-1.1.8 )
	zlib? ( >=sys-libs/zlib-1.2.11-r2 )
	zstd? ( >=app-arch/zstd-1.4.5 )
	>=dev-cpp/glog-0.4.0
	>=dev-cpp/gflags-2.2.2
	>=dev-libs/boost-1.71.0
	>=dev-libs/protobuf-3.12.1
	>=dev-libs/re2-0.2019.08.01
	>=dev-libs/thrift-0.12.0
	>=dev-libs/uriparser-0.9.1
	>=net-dns/c-ares-1.16.1
	>=net-libs/grpc-1.29.0
	dev-libs/openssl:0/1.1
	>=dev-libs/libutf8proc-2.5.0

	$(python_gen_cond_dep '
		dev-python/numpy[${PYTHON_USEDEP}]
	')
"

BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${P}-cmake-policy.patch" # Silence CMake policy warnings
	"${FILESDIR}/${P}-find-c-ares.patch" # Install Findc-ares.cmake so we can detect our non-CMake built c-ares
	"${FILESDIR}/${P}-non-cmake-c-ares.patch" # Find c-ares using the above Findc-ares.cmake
	"${FILESDIR}/${P}-fix-grpc.patch" # CMake has issues locating gRPC
)

pkg_setup() {
	python-single-r1_pkg_setup
}

# Since upstream does not include the test data in their source distribution, unpack it if needed
src_unpack() {
	unpack "${P}.tar.gz" || die

	ebegin "Adding vendored RapidJSON to build system"
	cp "${DISTDIR}/${P}-vendored-rapidjson.tar.gz" "${S}/thirdparty/rapidjson-${RAPIDJSON_GIT_COMMIT}.tar.gz" || die
	eend

	if use jemalloc; then
		ebegin "Adding vendored jemalloc to build system"
		cp "${DISTDIR}/${P}-vendored-jemalloc.tar.bz2" "${S}/thirdparty/jemalloc-${JEMALLOC_VERSION}.tar.bz2" || die
		eend
	fi

	if use test; then
		ebegin "Unpacking Arrow test data"
		tar --strip-components=1 -xzf "${DISTDIR}/${P}-testing.tar.gz" -C "${WORKDIR}/${P}/testing/" || die
		eend

		ebegin "Unpacking Parquet test data"
		tar --strip-components=1 -xzf "${DISTDIR}/${P}-parquet-testing.tar.gz" -C "${S}/submodules/parquet-testing/" || die
		eend
	fi
}

multilib_src_configure() {
	export ARROW_RAPIDJSON_URL="${S}/thirdparty/rapidjson-${RAPIDJSON_GIT_COMMIT}.tar.gz"

	if use jemalloc; then
		export ARROW_JEMALLOC_URL="${S}/thirdparty/jemalloc-${JEMALLOC_VERSION}.tar.bz2"
	fi

	# Determine the SIMD level to compile and use
	if use cpu_flags_x86_avx512f; then
		local simd_level=AVX512
	elif use cpu_flags_x86_avx2; then
		local simd_level=AVX2
	elif use cpu_flags_x86_sse4_2; then
		local simd_level=SSE4_2
	else
		local simd_level=NONE
	fi

	local mycmakeargs=(
		-DARROW_ALTIVEC=OFF # TODO: handle PPC and PPC CPU_FLAGS
		-DARROW_BUILD_TESTS=$(usex 'test')
		-DARROW_BUILD_UTILITIES=ON
		-DARROW_COMPUTE=ON
		-DARROW_CSV=ON
		-DARROW_CUDA=OFF # FIXME: Add use and dependencies
		-DARROW_DATASET=ON
		-DARROW_DEPENDENCY_SOURCE=SYSTEM
		-DARROW_FILESYSTEM=ON
		-DARROW_FLIGHT=ON
		-DARROW_GANDIVA=OFF # FIXME: Add use and dependencies
		-DARROW_GANDIVA_JAVA=OFF # FIXME: Add use and dependencies
		-DARROW_HDFS=ON # This always uses a bundled hdfs.h
		-DARROW_HIVESERVER2=OFF # Currently does not work due to improper Arrow API use
		-DARROW_INSTALL_NAME_RPATH=OFF # Required to prevent building a library which apache-arrow-glib can't use
		-DARROW_IPC=ON
		-DARROW_JEMALLOC=$(usex 'jemalloc')
		-DARROW_JNI=OFF # FIXME: Add use and dependencies
		-DARROW_JSON=ON
		-DARROW_MIMALLOC=OFF # This is for Windows
		-DARROW_ORC=OFF # FIXME: Add use and dependencies
		-DARROW_PARQUET=ON
		-DARROW_PLASMA=ON
		-DARROW_PLASMA_JAVA_CLIENT=OFF # FIXME: Add use and dependencies
		-DARROW_PROTOBUF_USE_SHARED=ON
		-DARROW_PYTHON=ON
		-DARROW_RE2_LINKAGE=shared
		-DARROW_RUNTIME_SIMD_LEVEL=${simd_level}
		-DARROW_S3=$(usex 's3')
		-DARROW_SIMD_LEVEL=${simd_level}
		-DARROW_TENSORFLOW=$(usex 'tensorflow')
		-DARROW_USE_GLOG=ON
		-DARROW_WITH_BROTLI=$(usex 'brotli')
		-DARROW_WITH_BZ2=$(usex 'bz2')
		-DARROW_WITH_GRPC=ON
		-DARROW_WITH_LZ4=$(usex 'lz4')
		-DARROW_WITH_PROTOBUF=ON
		-DARROW_WITH_RAPIDJSON=ON
		-DARROW_WITH_SNAPPY=$(usex 'snappy')
		-DARROW_WITH_ZLIB=$(usex 'zlib')
		-DARROW_WITH_ZSTD=$(usex 'zstd')
		-DPARQUET_BUILD_EXECUTABLES=ON
		-DRapidJSON_SOURCE=BUNDLED # a pre-release version is required due to https://github.com/Tencent/rapidjson/pull/1323
	)

	cmake-utils_src_configure
}

# Given the large number of bleeding edge dependencies, I highly recommend running the tests always for this package :)
multilib_src_test() {
	export ARROW_TEST_DATA="${WORKDIR}/${P}/testing/data"
	export PARQUET_TEST_DATA="${S}/submodules/parquet-testing/data"

	einfo "Using Arrow test data location: ${ARROW_TEST_DATA}"
	einfo "Using Parquet test data location: ${PARQUET_TEST_DATA}"

	cmake-utils_src_test
}

multilib_src_install() {
	cmake-utils_src_install

	cd "${S}"

	dodoc CHANGELOG_PARQUET.md

	cd ..

	dodoc CHANGELOG.md CODE_OF_CONDUCT.md CONTRIBUTING.md LICENSE.txt NOTICE.txt README.md

	# Remove /usr/share/doc/arrow they helpfully created
	rm -rf "${D}/usr/share/doc/arrow"

	# Don't install the testing stuff since they're only used by src_test
	find "${D}" -name '*_testing.*' -delete -o -name '*ArrowTesting*' -delete
}
