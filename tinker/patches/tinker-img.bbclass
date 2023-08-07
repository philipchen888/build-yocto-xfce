# Copyright (C) 2017 Fuzhou Rockchip Electronics Co., Ltd
# Copyright (C) 2017 Trevor Woerner <twoerner@gmail.com>
# Released under the MIT license (see COPYING.MIT for the terms)

inherit image_types

# Use an uncompressed ext4 by default as rootfs
IMG_ROOTFS_TYPE = "ext4"
IMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.${IMG_ROOTFS_TYPE}"

# This image depends on the rootfs image
IMAGE_TYPEDEP:tinker-img = "${IMG_ROOTFS_TYPE}"

GPTIMG = "${IMAGE_BASENAME}-${MACHINE}-gpt.img"
BOOT_IMG = "${IMAGE_BASENAME}-${MACHINE}-boot.img"
IDBLOADER = "idbloader.img"

UBOOT_IMG = "u-boot.img"

LOADER1_SIZE = "8128"
BOOT_SIZE = "131072"

# WORKROUND: miss recipeinfo
do_image_tinker_img[depends] += " \
	parted-native:do_populate_sysroot \
	mtools-native:do_populate_sysroot \
	gptfdisk-native:do_populate_sysroot \
	dosfstools-native:do_populate_sysroot \
	virtual/kernel:do_deploy"

PER_CHIP_IMG_GENERATION_COMMAND:rk3288 = "generate_loader1_image"

IMAGE_CMD:tinker-img () {
	# Change to image directory
	cd ${DEPLOY_DIR_IMAGE}

	# Remove the existing image
	rm -f "${GPTIMG}"
	rm -f "${BOOT_IMG}"

	create_rk_image

	${PER_CHIP_IMG_GENERATION_COMMAND}

	cd ${DEPLOY_DIR_IMAGE}
	if [ -f ${WORKDIR}/${BOOT_IMG} ]; then
		cp ${WORKDIR}/${BOOT_IMG} ./
	fi
}

create_rk_image () {

	# last dd rootfs will extend gpt image to fit the size,
	# but this will overrite the backup table of GPT
	# will cause corruption error for GPT

	# Initialize sdcard image file
	dd if=/dev/zero of=${GPTIMG} bs=1M count=0 seek=4096

	# Create partition table
	parted -s ${GPTIMG} mklabel gpt

	# Create vendor defined partitions
	LOADER1_START=64
	BOOT_START=8192
	ROOTFS_START=139264

	# Create boot partition and mark it as bootable
	parted -s ${GPTIMG} unit s mkpart boot ${BOOT_START} $(expr ${ROOTFS_START} - 1)
	parted -s ${GPTIMG} set 1 boot on

	# Create rootfs partition
	parted -s ${GPTIMG} -- unit s mkpart rootfs ${ROOTFS_START} -34s

	if [ "${DEFAULTTUNE}" = "aarch64" ];then
		ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"
	else
		ROOT_UUID="69DAD710-2CE4-4E3C-B16C-21A1D49ABED3"
	fi

	# Change rootfs partuuid
	gdisk ${GPTIMG} <<EOF
x
c
2
${ROOT_UUID}
w
y
EOF

	# Delete the boot image to avoid trouble with the build cache
	rm -f ${WORKDIR}/${BOOT_IMG}

	# Create boot partition image

	mkfs.vfat -n "boot" -S 512 -C ${WORKDIR}/${BOOT_IMG} 131072
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/zImage ::
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/rk3288-tinker.dtb ::
	mmd -i ${WORKDIR}/${BOOT_IMG} ::/extlinux
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ~/build-yocto-xfce/tinker/patches/rk3288.conf ::/extlinux/extlinux.conf
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ~/build-yocto-xfce/tinker/patches/hw_intf.conf ::

	# Burn Boot Partition
	dd if=${WORKDIR}/${BOOT_IMG} of=${GPTIMG} conv=notrunc,fsync seek=8192

	# Burn Rootfs Partition
	dd if=${IMG_ROOTFS} of=${GPTIMG} conv=notrunc,fsync seek=139264
}

generate_loader1_image () {

	# Burn bootloader
	# mkimage -n ${SOC_FAMILY} -T rksd -d ${DEPLOY_DIR_IMAGE}/u-boot-spl-dtb.bin ${DEPLOY_DIR_IMAGE}/${IDBLOADER}
	# cat ${DEPLOY_DIR_IMAGE}/u-boot.bin >>${DEPLOY_DIR_IMAGE}/${IDBLOADER}
	dd if=${TMPDIR}/../../../debian_u-boot/u-boot.img of=${GPTIMG} conv=notrunc,fsync seek=64
}
