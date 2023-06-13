inherit var-hab
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:hab += "file://u-boot-hab.cfg"

# u-boot-ivt.img.log and spl.log are generated when manually building U-Boot
# when building with Yocto, they are in the do_compile.log file.
# This function extracts them.
# Use the "leaving directory...defconfig" or "entering directory...defconfig"
# to split the log file for nand and sd configs
sign_uboot32_getlog() {
	TYPE="$1"
	DEFCONFIG="$2"
	DO_COMPILE_LOG="${WORKDIR}/temp/log.do_compile"
	LOG="${DO_COMPILE_LOG}.${TYPE}"

	# Create a working copy of the logfile
	cp ${DO_COMPILE_LOG} ${LOG}

	case "$TYPE" in
		"nand")
			# Split the file, removing the sd log. Assume nand defconfig is first
			sed -i -e "/Leaving directory.*${DEFCONFIG}/,\$d" ${LOG}
			;;
		"sd")
			# Split the file, removing the nand log. Assume nand defconfig is first
			sed -i -e "1,/Entering directory.*${DEFCONFIG}/d" ${LOG}
			;;
		*)
			return
			;;
	esac

	# Get SPL log:
	# sed -e '1,/Image Type:   Freescale IMX Boot Image/d;/DCD Blocks: $/,$d' ${LOG} > ${CST_BIN_DIR}/SPL-${TYPE}.log
	sed -n '/^Image Type:   Freescale IMX Boot Image$/,/^DCD Blocks:.*$/p' ${LOG} > ${CST_BIN_DIR}/SPL-${TYPE}.log

	# Get U-Boot log:
	sed -n '/^Image Name:   U-Boot .*$/,/^HAB Blocks:.*$/p' ${LOG} > ${CST_BIN_DIR}/u-boot-ivt.img-${TYPE}.log
}

sign_uboot32() {
	SOC="$1"

	# Copy images to linux64/bin directory of CST
	unset i j k
	for config in ${UBOOT_MACHINE}; do
		i=$(expr $i + 1);
		for type in ${UBOOT_CONFIG}; do
			j=$(expr $j + 1);
			if [ $j -eq $i ]; then
				for binary in ${UBOOT_BINARIES}; do
					k=$(expr $k + 1);
					if [ $k -eq $i ]; then
						# Copy binaries
						cp ${B}/${config}/${UBOOT_BINARY} ${CST_BIN_DIR}/${UBOOT_BINARY}-${type}
						cp ${B}/${config}/SPL ${CST_BIN_DIR}/SPL-${type}

						# Parse log file
						sign_uboot32_getlog "${type}" "${config}"
					fi
				done
				unset k
			fi
		done
		unset j
	done
	unset i

	# Sign images
	cd ${CST_BIN_DIR}
	for type in ${UBOOT_CONFIG}; do
		bbwarn "Signing SPL-${type} ${UBOOT_BINARY}-${type}"
		SOC=${SOC} ./var-som_sign_image.sh SPL-${type} ${UBOOT_BINARY}-${type}
	done

	# Generate fuse commands
	cd ${CST_BIN_DIR}
	./var-u-boot_fuse_commands.sh "${SOC}" > ${WORKDIR}/$(basename ${CST_SRK_FUSE}).u-boot-cmds
}

deploy_uboot32() {
    # Deploy U-Boot Fuse Commands
    install -m 0644 ${WORKDIR}/$(basename ${CST_SRK_FUSE}).u-boot-cmds ${DEPLOYDIR}

	# Deploy signed images
	cd ${CST_BIN_DIR}
	for type in ${UBOOT_CONFIG}; do
		cp SPL-${type}_signed ${DEPLOYDIR}/SPL-${type}
		cp u-boot-ivt.img-${type}_signed ${DEPLOYDIR}/u-boot.img-${type}
	done
}

# Empty task for mx8/mx8m/mx9
do_sign_uboot() {
	:
}

do_sign_uboot:arm:hab() {
	if [ -n "${UBOOT_HAB_SOC}" ]; then
		sign_uboot32 "${UBOOT_HAB_SOC}"
	fi
}

do_deploy:append:arm:hab() {
	if [ -n "${UBOOT_HAB_SOC}" ]; then
		deploy_uboot32
	fi
}

addtask sign_uboot after do_compile before do_deploy
