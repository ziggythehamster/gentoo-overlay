# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5
USE_RUBY="ruby25 ruby26 ruby27 ruby30"

inherit ruby-fakegem

DESCRIPTION="This library provides arbitrary-precision decimal floating-point number class."
HOMEPAGE="https://github.com/ruby/bigdecimal"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"

SRC_URI="https://github.com/ruby/bigdecimal/archive/refs/tags/v${PV}.tar.gz"

ruby_add_bdepend "test? ( <dev-ruby/minitest-5 )"

each_ruby_configure() {
	${RUBY} -Cext/bigdecimal extconf.rb || die
}

each_ruby_compile() {
	emake -Cext/bigdecimal V=1
	cp -v ext/bigdecimal/bigdecimal$(get_modname) lib/ || die
}

each_ruby_test() {
	# Run tests directly to avoid dependencies in the Rakefile
	${RUBY} -Ilib:test/lib:test:. -e "gem 'minitest', '< 5.0'; require 'minitest/autorun'; Dir['test/bigdecimal/**/test_*.rb'].each { |f| require f }" || die
}
