################################################################################
#    HPCC SYSTEMS software Copyright (C) 2012 HPCC Systems®.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
################################################################################


# Component: ecl-package
#####################################################
# Description:
# ------------
#    Cmake Input File for ecl-package
#####################################################


project( ecl-package )

include(${HPCC_SOURCE_DIR}/esp/scm/espscm.cmake)

set (    SRCS
         ${ESPSCM_GENERATED_DIR}/common_esp.cpp
         ${ESPSCM_GENERATED_DIR}/ws_packageprocess_esp.cpp
         ${ESPSCM_GENERATED_DIR}/ws_fs_esp.cpp
         ecl-package.cpp
         ${HPCC_SOURCE_DIR}/ecl/eclcmd/eclcmd_shell.cpp
         ${HPCC_SOURCE_DIR}/ecl/eclcmd/eclcmd_common.hpp
         ${HPCC_SOURCE_DIR}/ecl/eclcmd/eclcmd_common.cpp
    )

include_directories (
         ${CMAKE_BINARY_DIR}
         ${CMAKE_BINARY_DIR}/oss
         ${HPCC_SOURCE_DIR}/system/include
         ${HPCC_SOURCE_DIR}/system/jlib
         ${HPCC_SOURCE_DIR}/common/workunit
         ${HPCC_SOURCE_DIR}/esp/clients
         ${HPCC_SOURCE_DIR}/esp/bindings
         ${HPCC_SOURCE_DIR}/esp/bindings/SOAP/xpp
         ${HPCC_SOURCE_DIR}/esp/platform
         ${HPCC_SOURCE_DIR}/esp/smc/SMCLib
         ${HPCC_SOURCE_DIR}/system/security/shared
         ${HPCC_SOURCE_DIR}/system/include
         ${HPCC_SOURCE_DIR}/system/xmllib
         ${HPCC_SOURCE_DIR}/ecl/eclcmd
         ${HPCC_SOURCE_DIR}/ecl/eclcc
         ${HPCC_SOURCE_DIR}/common/thorhelper
         ${ESPSCM_GENERATED_DIR}
    )

ADD_DEFINITIONS( -D_CONSOLE -DWsPackageProcess_API_LOCAL -DFileSpray_API_LOCAL )

HPCC_ADD_EXECUTABLE ( ecl-packagemap ${SRCS} )

add_dependencies ( ecl-packagemap espscm )
install ( TARGETS ecl-packagemap RUNTIME DESTINATION ${EXEC_DIR} )
target_link_libraries ( ecl-packagemap
        jlib
        esphttp
        workunit
    )

if ( UNIX )
    install ( PROGRAMS ecl-package.install DESTINATION etc/init.d/install COMPONENT Runtime )
    install ( PROGRAMS ecl-package.uninstall DESTINATION etc/init.d/uninstall COMPONENT Runtime )
endif ( UNIX )

