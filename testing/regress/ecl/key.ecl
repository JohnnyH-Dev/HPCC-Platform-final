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
############################################################################## */

import std.system.thorlib;
import $.setup;
prefix := setup.Files(false, false).IndexPrefix + WORKUNIT + '::';

trec := RECORD
 unsigned1 key;
 string v;
 unsigned2 node := 0;
END;

tmp := DATASET([{1, 'a'}, {2, 'b'}, {3, 'c'}, {4, 'd'}, {5, 'e'}], trec);

trec addNodeNum(trec L, unsigned4 c) := transform
    SELF.node := c;
    SELF := L;
  END;

norm := NORMALIZE(tmp, thorlib.nodes(), addNodeNum(LEFT, counter));

disttmp := DISTRIBUTE(norm, node);

trec func(trec L, unsigned4 c) := TRANSFORM
    SELF := L;
  END;
norm2 := NORMALIZE(disttmp, 5000, func(LEFT, counter));

o1 := OUTPUT(norm2, , prefix + 'test.d00', OVERWRITE);

rec := RECORD
 trec;
 unsigned8 filepos {virtual(fileposition)};
END;

d := DATASET(prefix + 'test.d00', rec, FLAT);

iRec := RECORD
 d.key;
 d.filepos;
END;


// NB: avoid reusing same key file (see bug #13112)
idx := INDEX(d, iRec, prefix + 'test.idx');
idx2 := INDEX(d, iRec, prefix + 'test2.idx');
idx3 := INDEX(d, iRec, prefix + 'test3.idx');
idx4 := INDEX(d, iRec, prefix + 'test4.idx');
idx5 := INDEX(d, iRec, {d}, prefix + 'test5.idx');
idx6 := INDEX(d, iRec, prefix + 'test6.idx');
idx7 := INDEX(d, iRec, prefix + 'test7.idx');

thornodes := MAX(CHOOSEN(tmp, 1), thorlib.nodes()) : global;  // Force it to calculate nodes() on thor not hthor

SEQUENTIAL(
o1,
BUILDINDEX(idx, OVERWRITE), 
OUTPUT((unsigned)(COUNT(idx(key>3))/thornodes)),
BUILDINDEX(idx2, OVERWRITE, FEW),
OUTPUT((unsigned)(COUNT(idx2(key<3))/thornodes)),
BUILDINDEX(idx3, OVERWRITE),
OUTPUT((unsigned)(COUNT(idx3(key=5))/thornodes)),
BUILDINDEX(idx4, OVERWRITE, FEW),
OUTPUT((unsigned)(COUNT(idx4(key<>2))/thornodes)),
BUILDINDEX(idx5, COMPRESSED(FIRST), OVERWRITE),
OUTPUT((unsigned)(COUNT(idx5(key<>2))/thornodes)),
BUILDINDEX(idx6, COMPRESSED(ROW), OVERWRITE),
OUTPUT((unsigned)(COUNT(idx6(key<>2))/thornodes)),
BUILDINDEX(idx7, COMPRESSED('POC'), OVERWRITE),
OUTPUT((unsigned)(COUNT(idx7(key<>2))/thornodes)),
OUTPUT(CHOOSEN(idx, 10)),
OUTPUT(CHOOSEN(idx2, 10)),
OUTPUT(CHOOSEN(idx3, 10)),
OUTPUT(CHOOSEN(idx4, 10)),
OUTPUT(CHOOSEN(idx5, 10), { key, v, filepos }),
OUTPUT(CHOOSEN(idx6, 10)),
OUTPUT(CHOOSEN(d, 10), { key, v, filepos }),
OUTPUT(CHOOSEN(idx7, 10))
);
