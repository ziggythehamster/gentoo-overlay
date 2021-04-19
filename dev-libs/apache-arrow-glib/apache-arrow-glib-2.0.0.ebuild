# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Arrow GLib is a wrapper library for Arrow C++. Arrow GLib provides a C API."
DOCS=( README.md )
HOMEPAGE="https://arrow.apache.org/"
IUSE="doc"
KEYWORDS="~amd64"
LICENSE="Apache-2.0"
SLOT="0/${PV}"

SRC_URI="mirror://apache/arrow/arrow-${PV}/apache-arrow-${PV}.tar.gz -> apache-arrow-${PV}.tar.gz"

S="${WORKDIR}/apache-arrow-${PV}/c_glib"

RDEPEND="
	>=dev-libs/glib-2.60.7
	>=dev-libs/gobject-introspection-1.60.2
	dev-libs/apache-arrow:${SLOT}
"

BDEPEND="
	doc? ( >=dev-util/gtk-doc-1.25-r1 )
	>=dev-util/meson-0.52.1
	virtual/pkgconfig
"

src_configure() {
	econf $(use_enable doc gtk-doc)
}

src_install() {
	emake DESTDIR="${D}" install

	if [[ $(declare -p DOCS) == "declare -a "* ]] ; then
			dodoc "${DOCS[@]}"
	else
			dodoc ${DOCS}
	fi

	# delete /usr/share/doc/arrow-glib they helpfully made for us
	rm -rf "${D}/usr/share/doc/arrow-glib"
}
