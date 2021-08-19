/*##############################################################################

    HPCC SYSTEMS software Copyright (C) 2021 HPCC Systems®.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
############################################################################## */

#ifdef _USE_CPPUNIT

#include <cppunit/TestFixture.h>
#include "unittests.hpp"
#include <algorithm>

#include "jmetrics.hpp"

using namespace hpccMetrics;

class MetricFrameworkTestSink : public MetricSink
{
public:
    explicit MetricFrameworkTestSink(const char *name) :
        MetricSink(name, "test") { }

    ~MetricFrameworkTestSink() override = default;

    void startCollection(MetricsManager *_pManager) override
    {
        pManager = _pManager;
        isCollecting = true;
    }

    void stopCollection() override
    {
        isCollecting = false;
    }

    std::vector<std::shared_ptr<IMetric>> getReportMetrics() const
    {
        return pManager->queryMetricsForReport(name);
    }

public:
    bool isCollecting = false;
};


class MetricFrameworkTests : public CppUnit::TestFixture
{
public:
    MetricFrameworkTests()
    {
        pTestSink = new MetricFrameworkTestSink("testsink");
        frameworkTestManager.addSink(pTestSink, "testsink");
    }

    ~MetricFrameworkTests() = default;

    CPPUNIT_TEST_SUITE(MetricFrameworkTests);
        CPPUNIT_TEST(Test_counter_metric_increments_properly);
        CPPUNIT_TEST(Test_gauge_metric_updates_properly);
        CPPUNIT_TEST(Test_custom_metric);
        CPPUNIT_TEST(Test_manager_calls_sink_to_start_and_stop_collection);
        CPPUNIT_TEST(Test_manager_manages_metrics_properly);
        CPPUNIT_TEST(Test_scoped_gauge_updater_classes);
    CPPUNIT_TEST_SUITE_END();

protected:


    void Test_counter_metric_increments_properly()
    {
        std::shared_ptr<CounterMetric> pCounter = std::make_shared<CounterMetric>("test-counter", "description");
        CPPUNIT_ASSERT_EQUAL(0, static_cast<int>(pCounter->queryValue()));

        //
        // Test default increment (by 1)
        pCounter->inc();
        int counterValue = pCounter->queryValue();
        CPPUNIT_ASSERT_EQUAL(1, counterValue);

        //
        // Test increment by > 1
        pCounter->inc(2);
        counterValue = pCounter->queryValue();
        CPPUNIT_ASSERT_EQUAL(3, counterValue);
    }


    void Test_gauge_metric_updates_properly()
    {
        std::shared_ptr<GaugeMetric> pGauge = std::make_shared<GaugeMetric>("test-gauge", "description");
        int gaugeValue = pGauge->queryValue();
        CPPUNIT_ASSERT_EQUAL(0, gaugeValue);

        //
        // Test initial setting of gauge
        pGauge->set(25);
        gaugeValue = pGauge->queryValue();
        CPPUNIT_ASSERT_EQUAL(25, gaugeValue);

        //
        // Test updating gauge
        pGauge->adjust(10);
        gaugeValue = pGauge->queryValue();
        CPPUNIT_ASSERT_EQUAL(35, gaugeValue);

        pGauge->adjust(-5);
        gaugeValue = pGauge->queryValue();
        CPPUNIT_ASSERT_EQUAL(30, gaugeValue);
    }


    void Test_custom_metric()
    {
        int customCounter = 0;
        std::shared_ptr<CustomMetric<int>> pCustomCounter = std::make_shared<CustomMetric<int>>("custom-counter", "description", METRICS_COUNTER, customCounter);
        int customCounterValue = pCustomCounter->queryValue();
        CPPUNIT_ASSERT_EQUAL(0, customCounterValue);

        customCounter++;
        customCounterValue = pCustomCounter->queryValue();
        CPPUNIT_ASSERT_EQUAL(1, customCounterValue);
    }


    void Test_manager_calls_sink_to_start_and_stop_collection()
    {
        frameworkTestManager.startCollecting();
        CPPUNIT_ASSERT_EQUAL(true, pTestSink->isCollecting);
        frameworkTestManager.stopCollecting();
        CPPUNIT_ASSERT_EQUAL(false, pTestSink->isCollecting);
    }


    void Test_manager_manages_metrics_properly()
    {
        int numAdded;
        std::shared_ptr<CounterMetric> pCounter = std::make_shared<CounterMetric>("test-counter", "description");
        std::shared_ptr<GaugeMetric> pGauge = std::make_shared<GaugeMetric>("test-gauge", "description");
        frameworkTestManager.addMetric(pCounter);
        frameworkTestManager.addMetric(pGauge);
        numAdded = 2;

        frameworkTestManager.startCollecting();

        //
        // Make sure the initial list is correct
        int numMetrics = frameworkTestManager.queryMetricsForReport("testsink").size();
        CPPUNIT_ASSERT_EQUAL(numAdded, numMetrics);

        //
        // Add a metric while reporting is enabled and make sure it is returned
        std::shared_ptr<CounterMetric> pNewCounter = std::make_shared<CounterMetric>("test-newcounter", "description");
        frameworkTestManager.addMetric(pNewCounter);
        numAdded++;

        numMetrics = frameworkTestManager.queryMetricsForReport("testsink").size();
        CPPUNIT_ASSERT_EQUAL(numAdded, numMetrics);

        //
        // Destroy a metric and ensure it is no longer in the list of report metrics
        pNewCounter = nullptr;
        numAdded--;

        numMetrics = frameworkTestManager.queryMetricsForReport("testsink").size();
        CPPUNIT_ASSERT_EQUAL(numAdded, numMetrics);

        frameworkTestManager.stopCollecting();
    }


    void Test_scoped_gauge_updater_classes()
    {
        std::shared_ptr<GaugeMetric> pGauge = std::make_shared<GaugeMetric>("test-gauge", "description");
        CPPUNIT_ASSERT_EQUAL(0, static_cast<int>(pGauge->queryValue()));

        //
        // Test the scoped updater with a value of 1. Should increment in the block, and return
        // to 0 when exiting the block
        {
            ScopedGaugeUpdater gaugeUpdater(*pGauge, 1);
            CPPUNIT_ASSERT_EQUAL(1, static_cast<int>(pGauge->queryValue()));
        }
        CPPUNIT_ASSERT_EQUAL(0, static_cast<int>(pGauge->queryValue()));

        //
        // Same test, but a value > 1
        {
            ScopedGaugeUpdater gaugeUpdater(*pGauge, 3);
            CPPUNIT_ASSERT_EQUAL(3, static_cast<int>(pGauge->queryValue()));
        }
        CPPUNIT_ASSERT_EQUAL(0, static_cast<int>(pGauge->queryValue()));

        //
        // Test the scoped decrementer
        pGauge->adjust(1);
        CPPUNIT_ASSERT_EQUAL(1, static_cast<int>(pGauge->queryValue()));
        {
            ScopedGaugeDecrementer gaugeDecrementer(*pGauge, 1);
        }
        CPPUNIT_ASSERT_EQUAL(0, static_cast<int>(pGauge->queryValue()));

    }

protected:
    MetricsManager frameworkTestManager;
    MetricFrameworkTestSink *pTestSink;

};

CPPUNIT_TEST_SUITE_REGISTRATION( MetricFrameworkTests );
CPPUNIT_TEST_SUITE_NAMED_REGISTRATION( MetricFrameworkTests, "MetricFrameworkTests" );

#endif