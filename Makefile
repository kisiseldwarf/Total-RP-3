# Copyright The Total RP 3 Authors
# SPDX-License-Identifier: Apache-2.0

LIBDIR := totalRP3/libs
PACKAGER_URL := https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh

.PHONY: check dist libs locales

all: check

check:
	pre-commit run --all-files

dist:
	@curl -s $(PACKAGER_URL) | bash -s -- -d -S

libs:
	@curl -s $(PACKAGER_URL) | bash -s -- -c -d -z
	@cp -a .release/$(LIBDIR)/* $(LIBDIR)/

locales:
	bash Scripts/generate-locales.sh
