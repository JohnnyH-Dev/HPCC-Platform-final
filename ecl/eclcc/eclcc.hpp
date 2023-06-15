/*##############################################################################

    HPCC SYSTEMS software Copyright (C) 2015 HPCC Systems®.

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

#ifndef ECLCC_HPP
#define ECLCC_HPP

// The following is used by eclcc and eclcmd (ecl <command>).
// The primary intention is for eclcc and only a selection are also used by eclcmd for its eclcc options.
// The markers '!' and '?', present in either the first or first two columns, indicate that lines inclusion.
// e.g. '?' indicates inclusion in both eclcmd and eclcc).
//      '?!' indicates inclusion in the verbose usage for both.
//      '!' indicates inclusion in the verbose usage for eclcc only.
//      None of the above indicates inclusion in eclcc only.

const char * const helpText[] = {
    "",
    "Usage:",
    "    eclcc <options> queryfile.ecl",
    "",
    "General options:",
    "?   -I <path>     Add path to locations to search for ecl imports",
    "?   -L <path>     Add path to locations to search for system libraries",
    "    -o <file>     Specify name of output file (default a.out if linking to",
    "                  executable, or stdout)",
    "?   -manifest     Specify path to manifest file listing resources to add",
    "    -foption[=value] Set an ecl option (#option)",
    "    --main <ref>[@repo] Compile definition <ref> from the source collection, or specified git repo",
    "    -syntax       Perform a syntax check of the ECL",
    "    -platform=hthor Generate code for hthor executable",
    "    -platform=roxie Generate code for roxie cluster (default)",
    "    -platform=thor  Generate code for thor cluster",
    "",
    "Output control options",
    "    -E            Output preprocessed ECL in xml archive form",
    "!   -M            Output meta information for the ecl files",
    "!   -Md           Output dependency information",
    "!   -Me           eclcc should evaluate supplied ecl code rather than generating a workunit",
    "    -q            Save ECL query text as part of workunit",
    "    -qa           Save ECL query archive as part of workunit",
    "    -wu           Only generate workunit information as xml file",
    "",
    "c++ options",
    "    -S            Generate c++ output, but don't compile",
    "!   -c            compile only (don't link)",
    "?   -g, --debug   Enable debug symbols in generated code",
    "    -Wc,xx        Pass option xx to the c++ compiler",
    "!   -Wl,xx        Pass option xx to the linker",
    "!   -Wa,xx        Passed straight through to c++ compiler",
    "!   -Wp,xx        Passed straight through to c++ compiler",
    "!   -save-cpps    Do not delete generated c++ files (implied if -g)",
    "!   -save-temps   Do not delete intermediate files",
    "    -shared       Generate workunit shared object instead of a stand-alone exe",
    "",
    "File resolution options:",
    "    -dfs=ip       Use specified ip for DFS filename resolution",
    "    -scope=prefix Use specified scope prefix in DFS filename resolution",
    "    -cluster=name Use specified cluster when calculating graph resource allocation",
    "    -user=id      Use specified username in DFS filename resolution",
    "    -password=xxx Use specified password in DFS filename resolution (blank to prompt)",
    "",
    "Other options:",
    "!   -aoption[=value] Set an application option",
    "!   --allow=str   Allow use of named feature",
    "!   --allowsigned=str Allow use of named feature in signed modules",
    "!   -b            Batch mode.  Each source file is processed in turn.  Output",
    "!                 name depends on the input filename",
    "!   -checkVersion Enable/disable ecl version checking from archives",
    "?   -checkDirty   Report any modified attributes using git status",
    "?   --cleanrepos  Unconditionally delete any cached repositories associated with dependencies",
    "?   --cleaninvalidrepos Delete any incomplete cached repositories associated with dependencies",
    "!   --component   Set the name of the component this is executing on behalf of",
#ifdef _WIN32
    "!   -brk <n>      Trigger a break point in eclcc after nth allocation",
#endif
    "!   -Dname=value  Override the definition of a global attribute 'name'",
    "?!  --defaultgitprefix <prefix>  The default prefix used to access git repos when not specified in package.json",
    "?!  --defaultrepo=x  The default repo used to resolve code",
    "?!  --defaultrepoversion=x  The default repo version used (if not specified on --defaultrepo)",
    "!   --deny=all    Disallow use of all named features not specifically allowed using --allow",
    "!   --deny=str    Disallow use of named feature",
    "!   --expand <path> Expand the contents of an archive to a directory",
    "?!  --fastsyntax  Delay expanding functions when parsing.  May speed up processing for some queries",
    "?   --fetchrepos  Automatically download missing repositories associated with dependencies",
    "!   --gituser=x   Which user should be used for accessing git repositories (for servers)",
    "    -help, --help Display this message",
    "    -help -v      Display verbose help message",
    "!   --ignoresimplified Do not use simplified expressions when syntax checking",
    "!   --ignoreunknownimport Do not report an error on an unknown import",
    "!   -internal     Run internal tests",
    "!   --jobid=str   Set the name of the job id output in the logging",
    "?!  -legacy       Use legacy import and when semantics (deprecated)",
    "!   --leakcheck   Clean up memory since checking for memory leaks",
    "!   --keywords    Outputs the list of ECL reserved words to stdout (XML format)",
    "!   -legacyimport Use legacy import semantics (deprecated)",
    "!   -legacywhen   Use legacy when/side-effects semantics (deprecated)",
    "    --logfile <file> Write log to specified file",
    "!   --logdetail=n Set the level of detail in the log file",
    "?!  --mainrepo=x  The repo used to resolve --main (if not specified)",
    "?!  --mainrepoversion=x  The repo version used to resolve --main (if not specified on --mainrepo)",
    "!   --maxErrors=<n> Limit the number of errors, aborting on the nth (default = 5)",
    "    --metacache=x Specify directory to store distributed meta information",
    "!   --neversimplify=x Attributes/directory paths (comma separated list) that should not be simplified",
    "!   --nologfile   Do not write any logfile",
#ifdef _WIN32
    "!   -m            Enable leak checking",
#endif
    "!   --nogpg       Do not run gpg to check signatures on signed code",
    "    --nosourcepath Compile as if the source came from stdin",
    "?!  --nostdinc    Do not include the current directory in -I",
#ifndef _WIN32
    "!   -pch          Generate precompiled header for eclinclude4.hpp",
#endif
    "!   -P <path>     Specify the path of the output files (only with -b option)",
    "!   --prunearchive Do not include plugins and standard library in the archive (defaults on)",
    "?   -R<repo>[#version]=path Resolve repository references in directory 'path'",
    "!   --regeneratecache Force regeneration of cache (overwrite existing cache)",
    "!   -showpaths    Print information about the searchpaths eclcc is using",
    "    -specs file   Read eclcc configuration from specified file",
    "!   -split m:n    Process a subset m of n input files (only with -b option)",
    "!   --tracecache  Add details of whether cache entries are up to date to the log file",
    "?   --updaterepos Automatically update repositories associated with dependencies",
    "    -v --verbose  Output additional tracing information while compiling",
    "    -wxxxx=level  Set the severity for a particular warning code or category",
    "!                 -wall sets default severity for all warnings",
    "!                 level=ignore|log|warning|error|fail",
    "    --version     Output version information",
    "!   --timings     Output additional timing information",
    "!",
    "?!#options",
    "?!  -factivitiesPerCpp      Number of activities in each c++ file (requires -fspanMultipleCpp)",
    "?!  -fapplyInstantEclTransformations  Limit non-file outputs with a CHOOSEN",
    "?!  -fapplyInstantEclTransformationsLimit  Number of rows to limit outputs to",
    "?!  -fcheckAsserts          Check ASSERT() statements",
    "?!  -fcheckDuplicateThreshold=n Warn if SEQUENTIAL or workflow may duplicate more than n%% activities",
    "?!  -fexportDependencies    Generate information about inter-definition dependencies",
    "!   -fgenerateIR            Output the internal representation for the query to stdout",
    "?!  -fmaxCompileThreads     Number of compiler instances to compile the c++",
    "?!  -fmaxErrors             Maximum number of errors to report",
    "?!  -fnoteRecordSizeInGraph Add estimates of record sizes to the graph",
    "?!  -fpickBestEngine        Allow simple thor queries to be run without using thor",
    "?!  -fdiskReadsAreSimple    Count disk reads as simple when using pickBestEngine",
    "?!  -fobfuscateOutput       Remove details of the original ECL from output",
    "?!  -freportCppWarnings     Report warnings from c++ compilation",
    "?!  -fsaveCpp -fsaveCppTempFiles  Retain the generated c++ files",
    "?!  -fshowActivitySizeInGraph  Show estimates of generated c++ size in the graph",
    "?!  -fshowMetaInGraph       Add distribution/sort orders to the graph",
    "?!  -fshowRecordCountInGraph  Show estimates of record counts in the graph",
    "?!  -fspanMultipleCpp       Generate a work unit in multiple c++ files",
    "?!  -fsubgraphToRegenerate=n Regenerate the ECL for a particular subgraph",
    "?!  -ftimeParser            Add timings for parsing each ECL attribute",
    "?!  -ftimeTransforms        Add timings for internal transforms to the workunit",
    "?!  -faddDefaultBloom       Generate Bloom filter for first field of index if none specified",
    "?!  -ftraceActivities=n1,n2 Dump information about differences between activities",
    "?!  -ftraceWorkflows=n1,n2  Dump information about differences between workflow ids",
    "!",
    "!Features controlled by --allow, --allowsigned and --deny:",
    "!   all           Indicates all features not specifically overridden using one of the below",
    "!   userECL       User-supplied ECL code. If disallowed, only checked-in code is allowed",
    "!   datafile      Access to datafiles",
    "!   extern        Ability to define external code via SERVICE",
    "!   cpp           Ability to embed non-ECL code (c++, java etc)",
    "",
};

#endif
