# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake-multilib

CMAKE_BUILD_TYPE=Release
DESCRIPTION="Columnar in-memory analytics layer designed to accelerate big data"
DOCS=( CHANGELOG_PARQUET.md README.md )
HOMEPAGE="https://arrow.apache.org/"
IUSE="brotli bz2 lz4 snappy test zlib zstd"
KEYWORDS="~amd64"
LICENSE="Apache-2.0"
SLOT="0/${PV}"

SRC_URI="
	mirror://apache/arrow/arrow-${PV}/apache-arrow-${PV}.tar.gz -> ${P}.tar.gz
	test? (
		https://github.com/apache/arrow-testing/archive/90ae758c55aebf40e926ce049a662726b26f485f.tar.gz -> ${P}-testing.tar.gz
		https://github.com/apache/parquet-testing/archive/46c9e977f58f6c5ef1b81f782f3746b3656e5a8c.tar.gz -> ${P}-parquet-testing.tar.gz
	)
"

S="${WORKDIR}/${P}/cpp"

RDEPEND="
	brotli? ( >=app-arch/brotli-1.0.7 )
	lz4? ( >=app-arch/lz4-1.9.2 )
	snappy? ( >=app-arch/snappy-1.1.7 )
	zlib? ( >=sys-libs/zlib-1.2.11-r2 )
	zstd? ( >=app-arch/zstd-1.3.7-r1 )
	>=dev-cpp/glog-0.4.0
	>=dev-cpp/gflags-2.2.1-r1
	>=dev-cpp/gtest-1.10.0
	>=dev-libs/boost-1.67.0
	>=dev-libs/double-conversion-3.1.4-r1
	>=dev-libs/flatbuffers-1.11.0
	>=dev-libs/protobuf-3.10.1
	>=dev-libs/rapidjson-1.1.0
	>=dev-libs/thrift-0.12.0
	>=dev-libs/uriparser-0.9.1
	>=dev-python/numpy-1.14.5
	>=net-dns/c-ares-1.15.0-r1
	>=net-libs/grpc-1.25.0
	dev-libs/openssl:0/1.1
"

BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${P}-find-c-ares-alt.patch" # Install Findc-aresAlt.cmake from an older release so our non-CMake c-ares is detected
	"${FILESDIR}/${P}-ipc-cmakelists-flatc-path.patch" # Hard-code FLATC_EXECUTABLE since lookup is nonfunctional
	"${FILESDIR}/${P}-non-cmake-c-ares.patch" # Find c-ares using the above Findc-aresAlt.cmake
)

# Since upstream does not include the test data in their source distribution, unpack it if needed
src_unpack() {
	unpack "${P}.tar.gz" || die

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
	local mycmakeargs=(
		-DARROW_BUILD_TESTS=$(usex 'test')
		-DARROW_DEPENDENCY_SOURCE=SYSTEM
		-DARROW_FLIGHT=ON
		-DARROW_JEMALLOC=OFF # Arrow wants to use its bundled version and I don't want to fix CMake to use our specific slotted version that they want
		-DARROW_JSON=ON
		-DARROW_ORC=OFF # FIXME
		-DARROW_PARQUET=ON
		-DARROW_PLASMA=ON
		-DARROW_PYTHON=ON
		-DARROW_USE_GLOG=ON
		-DARROW_WITH_BROTLI=$(usex 'brotli')
		-DARROW_WITH_BZ2=$(usex 'bz2')
		-DARROW_WITH_LZ4=$(usex 'lz4')
		-DARROW_WITH_SNAPPY=$(usex 'snappy')
		-DARROW_WITH_ZLIB=$(usex 'zlib')
		-DARROW_WITH_ZSTD=$(usex 'zstd')
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