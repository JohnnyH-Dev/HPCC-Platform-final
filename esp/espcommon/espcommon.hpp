/*##############################################################################
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

############################################################################## */

#pragma once

#include <memory>
#include "jmetrics.hpp"

#ifdef ESPCOMMON_EXPORTS
#define ESPCOMMON_API DECL_EXPORT
#else
#define ESPCOMMON_API DECL_IMPORT
#endif

ESPCOMMON_API std::shared_ptr<hpccMetrics::ScaledHistogramMetric> registerServiceMethodProfilingMetric(const char *processName, const char *serviceName, const char *methodName, const char *desc, const char *profilingOptions);
ESPCOMMON_API std::shared_ptr<hpccMetrics::ScaledHistogramMetric> registerProfilingMetric(const char *histogramMetricName, const char *desc, const char *profilingOptions);
