# Override the arch with `make ARCH=i386`
ARCH   ?= $(shell flatpak --default-arch)
REPO   ?= repo
FB_ARGS ?=

# SDK Versions setup here
#
# SDK_BRANCH:          The version (branch) of runtime and sdk to produce
# SDK_RUNTIME_VERSION: The org.freedesktop.BaseSdk and platform version to build against
#
SDK_BRANCH=1.6
SDK_RUNTIME_VERSION=1.6

# Canned recipe for generating metadata
SUBST_FILES=org.freedesktop.Sdk.json \
	org.freedesktop.GlxInfo.json \
	os-release issue issue.net \
	org.freedesktop.Sdk.appdata.xml org.freedesktop.Platform.appdata.xml \
	org.freedesktop.Platform.GL.mesa-git.json \
	org.freedesktop.Platform.GL.mesa-stable.json \
	org.freedesktop.Sdk.Extension.gfortran62.json \
	org.freedesktop.Platform.VAAPI.Intel.json

define subst-metadata
	@echo -n "Generating files: ${SUBST_FILES}... ";
	@for file in ${SUBST_FILES}; do 					\
	  file_source=$${file}.in; 						\
	  sed -e 's/@@SDK_ARCH@@/${ARCH}/g' 					\
	      -e 's/@@SDK_BRANCH@@/${SDK_BRANCH}/g' 				\
	      -e 's/@@SDK_RUNTIME_VERSION@@/${SDK_RUNTIME_VERSION}/g' 		\
	      $$file_source > $$file.tmp && mv $$file.tmp $$file || exit 1;	\
	done
	@echo "Done.";
endef

all: runtimes

extra: glxinfo gl-drivers extensions

$(SUBST_FILES): $(patsubst %,%.in,$(SUBST_FILES))
	$(call subst-metadata)

glxinfo: ${REPO} $(patsubst %,%.in,$(SUBST_FILES))
	$(call subst-metadata)
	flatpak-builder --force-clean --require-changes --repo=${REPO} --arch=${ARCH} \
	    --subject="build of org.freedesktop.GlxInfo, `date`" \
	    ${EXPORT_ARGS} ${FB_ARGS} glxinfo org.freedesktop.GlxInfo.json

gl-drivers: gl-drivers-${ARCH}

gl-drivers-${ARCH}:

gl-drivers-i386: mesa-stable

gl-drivers-x86_64: mesa-stable

mesa-git:
	$(call subst-metadata)
	flatpak-builder --force-clean --require-changes --repo=${REPO} --arch=${ARCH} \
		--subject="build of org.freedesktop.Platform.GL.mesa-git, `date`" \
		${EXPORT_ARGS} ${FB_ARGS} mesa org.freedesktop.Platform.GL.mesa-git.json

mesa-stable:
	$(call subst-metadata)
	flatpak-builder --force-clean --require-changes --repo=${REPO} --arch=${ARCH} \
		--subject="build of org.freedesktop.Platform.GL.mesa-stable, `date`" \
		${EXPORT_ARGS} ${FB_ARGS} mesa org.freedesktop.Platform.GL.mesa-stable.json
	if test "${ARCH}" = "i386" ; then \
		flatpak build-commit-from ${EXPORT_ARGS} --src-ref=runtime/org.freedesktop.Platform.GL.default/${ARCH}/${SDK_BRANCH} ${REPO} runtime/org.freedesktop.Platform.GL32.default/x86_64/${SDK_BRANCH} ; \
	fi

vaapi-intel:
	$(call subst-metadata)
	flatpak-builder --force-clean --require-changes --repo=${REPO} --arch=${ARCH} \
		--subject="build of org.freedesktop.Platform.VAAPI.Intel, `date`" \
		${EXPORT_ARGS} vaapi-intel org.freedesktop.Platform.VAAPI.Intel.json

runtimes: ${REPO} $(patsubst %,%.in,$(SUBST_FILES))
	$(call subst-metadata)
	flatpak-builder --force-clean --require-changes --repo=${REPO} --arch=${ARCH} \
		--subject="build of org.freedesktop.Sdk, `date`" \
		${EXPORT_ARGS} ${FB_ARGS} sdk org.freedesktop.Sdk.json
	if test "${ARCH}" = "i386" -a -f ${REPO}/refs/heads/runtime/org.freedesktop.Platform/i386/${SDK_BRANCH}; then \
		flatpak build-commit-from ${EXPORT_ARGS} --src-ref=runtime/org.freedesktop.Platform/${ARCH}/${SDK_BRANCH} ${REPO} runtime/org.freedesktop.Platform.Compat32/x86_64/${SDK_BRANCH} ; \
	fi

extensions: extensions-${ARCH}

extensions-${ARCH}:

# It seems like gfortran has issues on arm atm, lets drop it there

extensions-i386: gfortran-extension

extensions-x86_64: gfortran-extension


gfortran-extension: ${REPO} $(patsubst %,%.in,$(SUBST_FILES))
	$(call subst-metadata)
	flatpak-builder --force-clean --require-changes --repo=${REPO} --arch=${ARCH} \
		--subject="build of org.freedesktop.Sdk.Extension.gfortran62, `date`" \
		${EXPORT_ARGS} ${FB_ARGS} sdk org.freedesktop.Sdk.Extension.gfortran62.json

${REPO}:
	ostree  init --mode=archive-z2 --repo=${REPO}
