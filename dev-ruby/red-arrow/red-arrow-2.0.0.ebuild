# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5
USE_RUBY="ruby26 ruby27 ruby30"

inherit ruby-fakegem

DESCRIPTION="A Ruby library for utilizing Apache Arrow, an in-memory columnar data store."
HOMEPAGE="https://arrow.apache.org/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend "=dev-libs/apache-arrow-glib-${PV}*"
ruby_add_rdepend ">=dev-ruby/bigdecimal-2.0.3"
ruby_add_rdepend ">=dev-ruby/extpp-0.0.7"
ruby_add_rdepend ">=dev-ruby/ruby-gio2-3.3.6"
