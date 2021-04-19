# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5
USE_RUBY="ruby26 ruby27 ruby30"

inherit ruby-fakegem

DESCRIPTION="A Ruby library for working with Apache Arrow Dataset, a component of Apache Arrow."
HOMEPAGE="https://arrow.apache.org/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend "=dev-ruby/red-arrow-${PV}*"
