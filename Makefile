# Override the arch with `make ARCH=i386`
ARCH   ?= $(shell flatpak --default-arch)
REPO   ?= repo

# SDK Versions setup here
#
# SDK_BRANCH:          The version (branch) of runtime and sdk to produce
# SDK_RUNTIME_VERSION: The org.freedesktop.BaseSdk and platform version to build against
#
SDK_BRANCH=1.6
SDK_RUNTIME_VERSION=1.6

# Canned recipe for generating metadata
SUBST_FILES=org.freedesktop.Sdk.json org.freedesktop.GlxInfo.json os-release issue issue.net org.freedesktop.Sdk.appdata.xml org.freedesktop.Platform.appdata.xml org.freedesktop.Platform.GL.mesa-git.json
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

extra: glxinfo gl-drivers-${ARCH}

glxinfo: ${REPO} $(patsubst %,%.in,$(SUBST_FILES))
	$(call subst-metadata)
	flatpak-builder --force-clean --ccache --require-changes --repo=${REPO} --arch=${ARCH} \
	    --subject="build of org.freedesktop.GlxInfo, `date`" \
	    ${EXPORT_ARGS} glxinfo org.freedesktop.GlxInfo.json

gl-drivers: gl-drivers-${ARCH}

gl-drivers-${ARCH}:

gl-drivers-i386:

gl-drivers-x86_64:

mesa-git:
	$(call subst-metadata)
	flatpak-builder --force-clean --ccache --require-changes --repo=${REPO} --arch=${ARCH} \
		--subject="build of org.freedesktop.Platform.GL.mesa-git, `date`" \
		${EXPORT_ARGS} mesa org.freedesktop.Platform.GL.mesa-git.json

runtimes: ${REPO} $(patsubst %,%.in,$(SUBST_FILES))
	$(call subst-metadata)
	flatpak-builder --force-clean --ccache --require-changes --repo=${REPO} --arch=${ARCH} \
		--subject="build of org.freedesktop.Sdk, `date`" \
		${EXPORT_ARGS} sdk org.freedesktop.Sdk.json

${REPO}:
	ostree  init --mode=archive-z2 --repo=${REPO}
