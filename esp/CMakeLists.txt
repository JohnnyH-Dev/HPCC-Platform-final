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
include_directories (${SCM_GENERATED_DIR})
HPCC_ADD_SUBDIRECTORY (bindings)
HPCC_ADD_SUBDIRECTORY (clients)
HPCC_ADD_SUBDIRECTORY (eclwatch "PLATFORM")
HPCC_ADD_SUBDIRECTORY (files "PLATFORM")
if (NOT SKIP_ECLWATCH)
  HPCC_ADD_SUBDIRECTORY (src "PLATFORM")
endif()
HPCC_ADD_SUBDIRECTORY (platform "PLATFORM")
HPCC_ADD_SUBDIRECTORY (protocols)
HPCC_ADD_SUBDIRECTORY (scm)
HPCC_ADD_SUBDIRECTORY (services "PLATFORM")
HPCC_ADD_SUBDIRECTORY (smc "PLATFORM")
HPCC_ADD_SUBDIRECTORY (test "PLATFORM")
HPCC_ADD_SUBDIRECTORY (tools "CLIENTTOOLS")
HPCC_ADD_SUBDIRECTORY (xslt)
HPCC_ADD_SUBDIRECTORY (esdllib)
HPCC_ADD_SUBDIRECTORY (esdlscriptlib)
HPCC_ADD_SUBDIRECTORY (applications)
HPCC_ADD_SUBDIRECTORY (espcommon)
if (LOGGING_SERVICE)
  HPCC_ADD_SUBDIRECTORY (logging)
endif()
