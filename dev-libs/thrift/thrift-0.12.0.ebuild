# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Framework for scalable cross-language services development"
DOCS=( CHANGES CONTRIBUTING.md LANGUAGES.md README.md doc tutorial )
HOMEPAGE="https://thrift.apache.org/"
KEYWORDS="~amd64"
LICENSE="Apache-2.0"
SLOT="0"

SRC_URI="mirror://apache/thrift/${PV}/thrift-${PV}.tar.gz -> ${P}.tar.gz"

RDEPEND="
	>=dev-libs/boost-1.56.0
	dev-libs/openssl:0/1.1
"

BDEPEND="
    virtual/pkgconfig
    >=sys-devel/bison-3.1
    >=sys-devel/flex-2.6.4-r1
"

src_configure() {
    # We just want the basic C/C++ library. PRs welcomed for making these configurable.
	econf \
        --disable-debug \
        --disable-tests \
        --without-c_glib \
        --without-cl \
        --without-csharp \
        --without-d \
        --without-dart \
        --without-dotnetcore \
        --without-erlang \
        --without-go \
        --without-haskell \
        --without-haxe \
        --without-java \
        --without-libevent \
        --without-lua \
        --without-nodejs \
        --without-nodets \
        --without-perl \
        --without-php \
        --without-php_extension \
        --without-python \
        --without-qt4 \
        --without-qt5 \
        --without-ruby \
        --without-rust \
        --without-swift
}