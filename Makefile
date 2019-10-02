
build:
	@test -x ${HOME}/.cargo/bin/mdbook || ./ci/install-mdbook.sh
	@mdbook build
