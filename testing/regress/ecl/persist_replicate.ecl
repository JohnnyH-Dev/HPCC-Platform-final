/*##############################################################################

    HPCC SYSTEMS software Copyright (C) 2012 HPCC Systems®.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
##############################################################################*/

//class=spray
//nothor
//nohthor

import Std.File;
import $.setup;
prefix := setup.Files(false, false).FilePrefix;

// Following gh-622's recipe
rec := RECORD
    string name;
    string city;
    string phone;
END;

ds := DATASET([{'foo', 'london',    '123456'},
               {'bar', 'cambridge', '321654'},
               {'baz', 'blackburn', '654321'}], rec);
o1 := OUTPUT(ds);

small_rec := RECORD
    string name;
END;

small_rec trans(rec r) := TRANSFORM
    SELF.name  := r.name;
END;

// In Thor, this created a file that could not be replicated
ds2 := PROJECT(ds, trans(LEFT)) : PERSIST(prefix + 'PersistReplicate', SINGLE);
o2 := OUTPUT(ds2);

// Now, replicate
r1 := File.Replicate(prefix + 'PersistReplicate');

del1 := File.DeleteLogicalFile(prefix + 'PersistReplicate', true);

sequential(del1, o1, o2, r1);
