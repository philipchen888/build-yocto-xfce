export ARCH=arm
export CROSS_COMPILE=/usr/local/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-

u-boot: builduboot postbuilduboot

builduboot:
	cd debian_u-boot; \
	make clean; \
	make ARCH=arm tinker-rk3288_defconfig; \
	make all

postbuilduboot:
	cd debian_u-boot; \
	./tools/mkimage -n rk3288 -T rksd -d ./spl/u-boot-spl-dtb.bin u-boot.img; \
	cat ./u-boot.bin >> u-boot.img

get_kernel:
	cd linux-5.10.git; \
	git init; \
	git add * ; \
	git commit -m "initial release"; \
	git status; \
	git remote add origin https://github.com/TinkerBoard/debian_kernel.git

apply_patches:
	cd poky/build; \
	cp ../../patches/xfce-desktop-image.bb ../meta/recipes-graphics/images/; \
	rm -f ../meta-radxa/recipes-kernel/cypress-backports/brcmfmac.bb; \
	cp -r ../../patches/recipes-graphics ../meta-radxa/; \
	cp ../../patches/tinker-rk3288.conf ../meta-radxa/conf/machine/; \
	cp ../../patches/tinker-img.bbclass ../meta-radxa/classes/; \
	cp ../../patches/tcmode-default.inc ../meta/conf/distro/include/; \
	cp ../../patches/linux-rockpi-4_4.4.bb ../meta-radxa/recipes-kernel/linux/; \
	cp ../../patches/bblayers.conf ./conf/; \
	cp ../../patches/local.conf ./conf/
