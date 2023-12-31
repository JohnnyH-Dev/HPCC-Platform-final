################################################################################
#    HPCC SYSTEMS software Copyright (C) 2022 HPCC Systems®.
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


# Component: ws_dfsservice
#####################################################
# Description:
# ------------
#    Cmake Input File for ws_dfsservice
#####################################################

project( ws_dfsservice )

include(${HPCC_SOURCE_DIR}/esp/scm/smcscm.cmake)

set (    SRCS
         ${ESPSCM_GENERATED_DIR}/ws_dfs_esp.cpp
         ${HPCC_SOURCE_DIR}/esp/scm/ws_dfs.ecm
         ws_dfsservice.cpp
         ws_dfsplugin.cpp
    )

include_directories (
         ${CMAKE_BINARY_DIR}
         ${CMAKE_BINARY_DIR}/oss
         ${HPCC_SOURCE_DIR}/system/jlib
         ${HPCC_SOURCE_DIR}/system/mp
         ${HPCC_SOURCE_DIR}/system/xmllib
         ${HPCC_SOURCE_DIR}/system/security/securesocket
         ${HPCC_SOURCE_DIR}/system/security/shared
         ${HPCC_SOURCE_DIR}/system/security/cryptohelper
         ${HPCC_SOURCE_DIR}/system/include
         ${HPCC_SOURCE_DIR}/esp/platform
         ${HPCC_SOURCE_DIR}/esp/services
         ${HPCC_SOURCE_DIR}/esp/bindings
         ${HPCC_SOURCE_DIR}/esp/smc/SMCLib
         ${HPCC_SOURCE_DIR}/esp/bindings/SOAP/xpp
         ${HPCC_SOURCE_DIR}/esp/clients
         ${HPCC_SOURCE_DIR}/esp/clients/ws_dfsclient
         ${HPCC_SOURCE_DIR}/esp/services/common
         ${HPCC_SOURCE_DIR}/dali/base
         ${HPCC_SOURCE_DIR}/dali/dfu
         ${HPCC_SOURCE_DIR}/dali/sasha
         ${HPCC_SOURCE_DIR}/common/thorhelper
         ${HPCC_SOURCE_DIR}/common/pkgfiles
         ${HPCC_SOURCE_DIR}/common/workunit
         ${HPCC_SOURCE_DIR}/rtl/include
         ${HPCC_SOURCE_DIR}/rtl/eclrtl
    )

ADD_DEFINITIONS( -D_USRDLL -DWS_DFS_EXPORTS -DWsDfs_API_LOCAL -DESP_SERVICE_WsDfs)

HPCC_ADD_LIBRARY( ws_dfsservice SHARED ${SRCS} )
add_dependencies ( ws_dfsservice espscm )
install ( TARGETS ws_dfsservice RUNTIME DESTINATION ${EXEC_DIR} LIBRARY DESTINATION ${LIB_DIR} )
target_link_libraries ( ws_dfsservice
         jlib
         mp
         dalibase
         dllserver
         workunit
         xmllib
         esphttp
         SMCLib
         ${COMMON_ESP_SERVICE_LIBS}
    )

IF (USE_OPENSSL)
    target_link_libraries ( ws_dfsservice
        securesocket
    )
ENDIF()
