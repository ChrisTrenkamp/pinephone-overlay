# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 ninja-utils

BOOTLIN_REPO="https://megous.com/git/p-boot/"
BOOTLIN_VER="2020.02-2"

DESCRIPTION="This is a no nonsense bootloader for extremely fast and flexible booting of 
PinePhone. p-boot is partly based on some borrowed U-Boot and Linux code."
HOMEPAGE="https://xnux.eu/p-boot/"
SRC_URI="
https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--musl--bleeding-edge-"${BOOTLIN_VER}".tar.bz2
https://toolchains.bootlin.com/downloads/releases/toolchains/openrisc/tarballs/openrisc--musl--bleeding-edge-"${BOOTLIN_VER}".tar.bz2
"
EGIT_REPO_URI="${BOOTLIN_REPO}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

src_unpack() {
    git-r3_fetch
    git-r3_checkout

    mkdir aarch64 openrisc
    tar xpf "${DISTDIR}/aarch64--musl--bleeding-edge-${BOOTLIN_VER}.tar.bz2" -C "${WORKDIR}/aarch64" --strip-components=1
    tar xpf "${DISTDIR}/openrisc--musl--bleeding-edge-${BOOTLIN_VER}.tar.bz2" -C "${WORKDIR}/openrisc" --strip-components=1
    prev_repo="${EGIT_CHECKOUT_DIR}"

    mkdir -p "${WORKDIR}/${P}/fw/atf"
    export EGIT_REPO_URI="https://github.com/ARM-software/arm-trusted-firmware.git"
    export EGIT_CHECKOUT_DIR="${WORKDIR}/${P}/fw/atf"
    git-r3_fetch
    git-r3_checkout

    mkdir -p "${WORKDIR}/${P}/fw/crust"
    export EGIT_REPO_URI="https://github.com/crust-firmware/crust.git"
    export EGIT_CHECKOUT_DIR="${WORKDIR}/${P}/fw/crust"
    git-r3_fetch
    git-r3_checkout

    export EGIT_REPO_URI="${BOOTLIN_REPO}"
    export EGIT_CHECKOUT_DIR="${prev_repo}"
}

src_prepare() {
    cd "${WORKDIR}/${P}"
    eapply -p1 "${FILESDIR}/p-boot.patch"

    cd "${WORKDIR}/${P}/fw/crust"
    eapply -p1 "${FILESDIR}/crust.patch" || die

    cd "${WORKDIR}/${P}/fw/atf"
    git apply ../0001-plat-allwinner-Wait-for-SCP-core-to-perform-the-shut.patch ../atf.patch || die

    eapply_user
}

src_compile() {
    export PATH="${WORKDIR}/aarch64/bin:${WORKDIR}/openrisc/bin:${PATH}"

    cd "${WORKDIR}/${P}/theme"
    gcc -o p-boot-argb argb.c || die

    cd "${WORKDIR}/${P}/build"
    eninja

    cd "${WORKDIR}/${P}/fw"
    unset CFLAGS LDFLAGS
    ./build-all.sh || die
}

src_install() {
    dodir etc/p-boot

    cd "${WORKDIR}/${P}/theme"
    dobin p-boot-argb

    cd "${WORKDIR}/${P}/build"
    dobin p-boot-conf-native
    insinto etc/p-boot
    doins p-boot.bin

    cd "${WORKDIR}/${P}/fw"
    insinto etc/p-boot
    doins fw.bin
}
