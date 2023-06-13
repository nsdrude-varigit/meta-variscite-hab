# NXP CST Utils
# Requires registration, download from https://www.nxp.com/webapp/sps/download/license.jsp?colCode=IMX_CST_TOOL
# Override NXP_CST_URI in local.conf as needed
NXP_CST_URI ?= "file://${HOME}/cst-3.1.0.tgz"
SRC_URI:append:hab += "${NXP_CST_URI};name=cst;subdir=cst;"
CST_BIN_DIR ?= "${WORKDIR}/cst/release/linux64/bin"
CST_BIN ?= "${CST_BIN_DIR}/cst"

# Variscite CST Utils for imx6/imx6ul/imx7
VAR_CST_REV ?= "f66065e4d2fb835e2a251af1d3fec503adfd97ad"
VAR_CST_URI ?= "git://github.com/varigit/var-hab-cst-scripts.git;protocol=https;branch=master;rev=${VAR_CST_REV};"
VAR_CST_DIR ?= "${WORKDIR}/var-cst-scripts"
SRC_URI:append:hab += "${VAR_CST_URI};name=var-cst-scripts;destsuffix=var-cst-scripts;"
SRCREV_var-cst-scripts="${VAR_CST_REV}"

# Override CST_CERTS_URI in local.conf with customer repository:
CST_CERTS_REV ?= "56ad83a9962fb1cd8b4a18dc72993de7e7894bc5"
CST_CERTS_URI ?= "git://github.com/varigit/var-hab-certs.git;protocol=https;branch=master;rev=${CST_CERTS_REV}"
SRC_URI:append:hab += "${CST_CERTS_URI};name=cst-certs;destsuffix=cst-certs;"
SRCREV_cst-certs="${CST_CERTS_REV}"

CST_CRT_ROOT:mx6ul ?= "${WORKDIR}/cst-certs/iMX8M"
CST_CRT_ROOT:mx8m ?= "${WORKDIR}/cst-certs/iMX8M"
CST_CRT_ROOT:mx8 ?= "${WORKDIR}/cst-certs/iMX8"

# HABv4 Keys
CST_SRK:mx6ul ?= "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_table.bin"
CST_SRK:mx8m ?= "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_table.bin"
CST_CSF_CERT ?= "${CST_CRT_ROOT}/crts/CSF1_1_sha256_4096_65537_v3_usr_crt.pem"
CST_IMG_CERT ?= "${CST_CRT_ROOT}/crts/IMG1_1_sha256_4096_65537_v3_usr_crt.pem"
CST_SRK_FUSE:mx6ul ?= "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_fuse.bin"
CST_SRK_FUSE:mx8m ?= "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_fuse.bin"

# AHAB Keys
CST_SRK:mx8 ?= "${CST_CRT_ROOT}/crts/SRK1234table.bin"
CST_KEY ?= "${CST_CRT_ROOT}/crts/SRK1_sha384_4096_65537_v3_usr_crt.pem"
CST_SRK_FUSE:mx8 ?= "${CST_CRT_ROOT}/crts/SRK1234fuse.bin"

# Override in local.conf with customer serial & password
CST_KEYPASS ?= "Variscite_password"
CST_SERIAL ?= "1248163E"

HAB_VER:mx8x:hab="ahab"
HAB_VER:mx8qm:hab="ahab"
HAB_VER:mx8m:hab="habv4"
HAB_VER:mx6ul:hab="habv4"

do_compile:prepend:hab() {
    # Prepare serial and key_pass files with secrets
    echo "${CST_SERIAL}" > ${CST_CRT_ROOT}/keys/serial
    echo "${CST_KEYPASS}" > ${CST_CRT_ROOT}/keys/key_pass.txt
    echo "${CST_KEYPASS}" >> ${CST_CRT_ROOT}/keys/key_pass.txt

    # 32-bit platforms like imx6, imx6ul, imx7 use var-hab-cst-scripts
    # to sign images. The scripts and certificates must be copied
    # to the NXP signing tool. Do that after fetching.
    if [ "${TARGET_ARCH}" = "arm" ]; then
        # Copy Variscite CST Scripts to CST certs directory
        cp ${VAR_CST_DIR}/* ${CST_BIN_DIR}

        # Copy Variscite certs to CST directory
        cp ${CST_CRT_ROOT}/keys/* ${WORKDIR}/cst/release/keys/
        cp ${CST_CRT_ROOT}/crts/* ${WORKDIR}/cst/release/crts/
    fi
}
