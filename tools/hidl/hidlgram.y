%{
#ifdef _WIN32
#pragma warning(disable:4786)
#endif

#include "platform.h"

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdarg.h>
#include <set>
#include <string>
#include "hidl_utils.hpp"

#ifdef _WIN32
    #include <io.h>
    #include <fcntl.h>
    #include <share.h>
    #include <sys\stat.h>
#endif
#include "hidlcomp.h"

//#define YYDEBUG 1

void AddEspService();
void AddModule(void);
void AddEnum(void);
void AddMetaTag(MetaTagInfo *mti);
void AddEspInclude();
MetaTagInfo* getClearCurMetaTags();
void AddApi();
void AddEspMessage();
void AddEspProperty();

extern int yylex(void);
void yyerror(const char *s);

void check_param(void);

HIDLcompiler * hcp;

ModuleInfo * CurModule=NULL;
ProcInfo *   CurProc;
ParamInfo *  CurParam;
LayoutInfo * CurLayout;
EnumInfo *   CurEnum=NULL;
EnumValInfo *   CurEnumVal;
int EnumValue = 0;
ApiInfo * CurApi=NULL;
IncludeInfo *CurInclude=NULL;
//EspMethodInfo * CurMethod=NULL;

EspMessageInfo * CurEspMessage=NULL;
EspServInfo * CurService=NULL;
MetaTagInfo * CurMetaTags=NULL;

ModuleInfo * LastModule;
ProcInfo *   LastProc;
ParamInfo *  LastParam;
LayoutInfo * LastLayout;
EnumInfo *   LastEnum;
EnumValInfo *   LastEnumVal;
ApiInfo * LastApi=NULL;
IncludeInfo *LastInclude=NULL;

EspMessageInfo * LastEspMessage=NULL;
EspServInfo * LastService=NULL;
//EspMethodInfo * LastMethod=NULL;

std::string esp_def_export_tag;

bool rettype;
unsigned linenum=1;
unsigned errnum=0;
int  nCommentStartLine = -1;

%}

%token
  MODULE
  SCMAPI
  SCMEXPORTDEF
  SCMINTERFACE
  SCMENUM
  SCMEND
  ESPINCLUDE
  ESPSTRUCT
  ESPENUM
  ESPSTRUCTREF
  ESPENUMREF
  ESPREQUEST
  ESPRESPONSE
  ESPSERVICE
  ESPMETHOD
  ESPMETHODREF
  ESPVERSIONDEF
  ESPTEMPLATE
  ESPMOUNT
  ESPDEFEXPORT
  XSDTYPE
  _CONST
  _VOID
  _CHAR
  _BOOL
  _BYTE
  _INT
  _UNSIGNED
  _SHORT
  _LONG
  _FLOAT
  _DOUBLE
  _IN
  _OUT
  INOUT
  STRING
  _SIZE
  SIZEBYTES
  LAYOUT
  ASYNC
  _CALLBACK
  TIMEOUT
  VIRTUAL
  STAR
  UMBERSAND

  INTEGER_CONST
  STRING_CONST
  BOOL_CONST
  DOUBLE_CONST
  ID
  CONST_ID

%%

hidl
 : SectionList
 ;

SectionList
 : Section
 | SectionList Section
 ;

Section
 : Module
 | Enumeration
 | ExportDef
 | EspDefExport
 | Api
 | EspStruct
 | EspEnum
 | EspRequest
 | EspResponse
 | EspService
 | EspServiceMethod
 | EspVersionDef
 | EspInclude
  ;

ExportDef
 : SCMEXPORTDEF '(' ID ')' ';'
 {
    ExportDefInfo edi($3.getName());
    edi.write_cpp_header();
 }
 ;

EspDefExport
 : ESPDEFEXPORT '(' ID ')' ';'
 {
    esp_def_export_tag = $3.getName();
 }
 ;

EspService
 : EspServiceStart EspServiceBody ';'
 {
    AddEspService();
    //Now the default is sorted
    if (CurService->getMetaInt("sort_method",1)!=0)
        CurService->sortMethods();
    CurService->write_esp_interface();
    CurService->write_event_interface();
    CurService->write_client_interface();
    CurService=NULL;
 }
 ;

EspServiceStart
 : ESPSERVICE EspMetaData ID
 {
    CurService=new EspServInfo($3.getName());
    if (CurService)
    {
        CurService->tags = getClearCurMetaTags();

        StrBuffer minPingVer;
        StrBuffer pingAuthFeature("none");
        for (MetaTagInfo* t = CurService->tags; t!=NULL; t = t->next)
        {
            if (streq("ping_min_ver",t->getName()))
            {
                if (minPingVer.length()==0)
                {
                    minPingVer.set(t->getString());
                }
            }
            else if (streq("ping_auth_feature", t->getName()))
            {
                pingAuthFeature.set(t->getString());
            }
        }

        VStrBuffer reqname("%sPingRequest", $3.getName());
        CurEspMessage = new EspMessageInfo(reqname.str(), EspMessageInfo::espm_request);
        CurEspMessage->write_cpp_interfaces();

        if(minPingVer.length()!=0)
        {
            CurMetaTags = NULL;
            AddMetaTag(new MetaTagInfo("min_ver", minPingVer.str()));
            CurEspMessage->tags = getClearCurMetaTags();
         }

        AddEspMessage();
        CurEspMessage=NULL;

        VStrBuffer respname("%sPingResponse", $3.getName());
        CurEspMessage = new EspMessageInfo(respname.str(), EspMessageInfo::espm_response);
        CurEspMessage->write_cpp_interfaces();
        if(minPingVer.length()!=0)
        {
            CurMetaTags = NULL;
            AddMetaTag(new MetaTagInfo("min_ver", minPingVer.str()));
            CurEspMessage->tags = getClearCurMetaTags();
         }

        AddEspMessage();

        EspMethodInfo *method=new EspMethodInfo("Ping", reqname.str(), respname.str());

        CurMetaTags = NULL;
        if(minPingVer.length()!=0)
        {
            AddMetaTag(new MetaTagInfo("min_ver", minPingVer.str()));
        }
        if (pingAuthFeature.length()!=0)
        {
            AddMetaTag(new MetaTagInfo("auth_feature", pingAuthFeature.str()));
        }
        method->tags = getClearCurMetaTags();

        method->next=CurService->methods;
        CurService->methods=method;

        CurMetaTags   = NULL;
        CurEspMessage = NULL;
    }
 }
 ;

EspServiceBody
 : '{' EspServiceEntryList '}'
 | '{' '}'
 ;

EspServiceEntryList
 : EspServiceEntry
 | EspServiceEntryList EspServiceEntry
 ;

EspServiceEntry
 : EspServiceMethod
 | EspServiceMount
 ;

EspServiceMethod
 : ESPMETHOD EspMetaData ID '(' ID ',' ID ')' ';'
 | ESPMETHODREF EspMetaData ID '(' ID ',' ID ')' ';'
 {
    if (CurService)
    {
        EspMethodInfo *method=new EspMethodInfo($3.getName(), $5.getName(), $7.getName());

        method->tags = getClearCurMetaTags();

        method->next=CurService->methods;
        CurService->methods=method;
    }
 }
 | ProcDef
 {
    if (CurService && CurProc)
    {
        CurEspMessage = new EspMessageInfo(EspMessageInfo::espm_request, CurProc);
        CurEspMessage->write_cpp_interfaces();
        AddEspMessage();
        CurEspMessage=NULL;

        CurEspMessage = new EspMessageInfo(EspMessageInfo::espm_response, CurProc);
        CurEspMessage->write_cpp_interfaces();
        AddEspMessage();
        CurEspMessage=NULL;

        EspMethodInfo *method = new EspMethodInfo(CurProc);
        CurProc=NULL;

        method->next=CurService->methods;
        CurService->methods=method;
    }
 }
 ;

EspServiceMount
 : ESPMOUNT EspMetaData ID '(' string_const ')' ';'
 {
    EspMountInfo *mount=new EspMountInfo($3.getName(), $5.getString());

    mount->tags = getClearCurMetaTags();

    mount->next=CurService->mounts;
    CurService->mounts=mount;
 }
 ;

EspStruct
 : EspStructStart OptionalExtends EspMessageBody ';'
 {
    CurEspMessage->write_cpp_interfaces();
    AddEspMessage();
    CurEspMessage=NULL;
 }
 ;

EspStructStart
 : ESPSTRUCT EspMetaData ID
 {
    CurEspMessage = new EspMessageInfo($3.getName(), EspMessageInfo::espm_struct);
    CurEspMessage->tags = getClearCurMetaTags();
    CurParam=NULL;
 }
 ;



EspEnum
 : EspEnumStart EnumBase EnumBody ';'
 {
    CurEspMessage->write_cpp_interfaces();
    AddEspMessage();
    CurEspMessage=NULL;
 }
 ;

EspEnumStart
 : ESPENUM EspMetaData ID
 {
    CurEspMessage = new EspMessageInfo($3.getName(), EspMessageInfo::espm_enum);
    CurEspMessage->tags = getClearCurMetaTags();
    CurParam=NULL;
 }
 ;

EnumBase
 : ':' EnumBaseType
 {
    if (CurEspMessage->getParentName())
        yyerror("parent is already specified by meta extends");
    CurEspMessage->setParentName($2.getName());
 }
 |
 {
    yyerror("base type must be specified for enumeration type");
 }
 ;

EnumBaseType
 : _INT
 {
    $$.setName("int");
 }
 | _SHORT
 {
    $$.setName("short");
 }
 | STRING
 {
    $$.setName("string");
 }
 | _DOUBLE
 {
    $$.setName("double");
 }
 ;

EnumBody
 : '{' EnumList OptionalComma '}'
 {
    CurParam=NULL;
    LastParam=NULL;
 }
 | '{' '}'
 {  yyerror("Enum can not be empty");  }
 ;

EnumList
 : EnumItemDef
 | EnumList ',' EnumItemDef
 ;

EnumItemDef
 : ID '(' EnumConstValue ')'
 {
    CurParam = new ParamInfo;
    CurParam->name = strdup($1.getName());
    CurParam->kind = TK_ENUM;
    CurParam->tags = getClearCurMetaTags();
    AddEspProperty();
 }
 | ID '(' EnumConstValue ',' string_const ')'
 {
    CurParam = new ParamInfo;
    CurParam->name = strdup($1.getName());
    CurParam->kind = TK_ENUM;
    AddMetaTag(new MetaTagInfo("desc", $5.getString()));
    CurParam->tags = getClearCurMetaTags();;
    AddEspProperty();
 }
 | ID
 {
    CurParam = new ParamInfo;
    CurParam->name = strdup($1.getName());
    CurParam->kind = TK_ENUM;
    AddMetaTag(new MetaTagInfo("enum", VStrBuffer("\"%s\"", $1.getName()).str()));
    CurParam->tags = getClearCurMetaTags();

    AddEspProperty();
 }
 ;

OptionalComma
 : ','
 |
 ;

EnumConstValue
 : INTEGER_CONST
 {
    int val = $1.getInt();
    AddMetaTag(new MetaTagInfo("enum", val));
 }
 | DOUBLE_CONST
 {
    double val = $1.getDouble();
    AddMetaTag(new MetaTagInfo("enum", val));
 }
 | string_const
 {
    const char* val = $1.getString();
    AddMetaTag(new MetaTagInfo("enum", val));
 }
 ;

EspInclude
 : ESPINCLUDE '(' ID ')' ';'
 {
    CurInclude = new IncludeInfo($3.getName());
    CurInclude->write_cpp_interfaces();

    AddEspInclude();
    CurInclude=NULL;
 }
 ;

EspRequest
 : EspRequestStart OptionalExtends EspMessageBody ';'
 {
    CurEspMessage->write_cpp_interfaces();
    AddEspMessage();
    CurEspMessage=NULL;
 }
 ;

EspRequestStart
 : ESPREQUEST EspMetaData ID
 {
    CurEspMessage = new EspMessageInfo($3.getName(), EspMessageInfo::espm_request);
    CurEspMessage->tags = getClearCurMetaTags();
    CurParam=NULL;
 }
 ;


EspResponse
 : EspResponseStart OptionalExtends EspMessageBody ';'
 {
    CurEspMessage->write_cpp_interfaces();
    AddEspMessage();
    CurEspMessage=NULL;
 }
 ;

EspResponseStart
 : ESPRESPONSE EspMetaData ID
 {
    CurEspMessage = new EspMessageInfo($3.getName(), EspMessageInfo::espm_response);
    CurEspMessage->tags = getClearCurMetaTags();
    CurParam=NULL;
 }
 ;

OptionalExtends
 : ':' ID
 {
    if (CurEspMessage->getParentName())
        yyerror("parent is already specified by meta extends");
    CurEspMessage->setParentName($2.getName());
 }
 |
 ;

EspMessageBody
 : '{' EspPropertyList '}'
 {
    CurParam=NULL;
    LastParam=NULL;
 }
 | '{' '}'
 ;

EspPropertyList
 : EspPropertyDef
 | EspPropertyList EspPropertyDef
 ;

EspPropertyDef
 : EspTemplateStart ESPTEMPLATE '<' EspTemplateParams '>' ID EspPropertyInit ';'
 {
    if (CurParam)
    {
        if (CurParam->name && ((CurParam->flags & PF_RETURN)==0))
        {
            if (CurParam->kind==TK_null)
            {
                CurParam->kind = TK_STRUCT;
                CurParam->typname = CurParam->name;
            }
            else
            {
                errnum = 9;
                yyerror("unknown/unexpected ID");
            }
        }

        CurParam->flags |= PF_TEMPLATE;
        CurParam->templ = strdup($2.getName());
        CurParam->name = strdup($6.getName());
        CurParam->tags = getClearCurMetaTags();
    }
    else
        CurMetaTags=NULL;
    AddEspProperty();
 }
 | EspTemplateStart ESPTEMPLATE '<' EspTemplateParams ',' ID '>' ID EspPropertyInit ';'
 {
    if (CurParam)
    {
        if (CurParam->name && ((CurParam->flags & PF_RETURN)==0))
        {
            if (CurParam->kind==TK_null)
            {
                CurParam->kind = TK_STRUCT;
                CurParam->typname = CurParam->name;
            }
            else
            {
                errnum = 21;
                yyerror("invalid type declaration in template");
            }
        }

        CurParam->flags |= PF_TEMPLATE;
        CurParam->templ = strdup($2.getName());
        CurParam->name = strdup($8.getName());

        AddMetaTag(new MetaTagInfo("item_tag", $6.getName()));

        CurParam->tags = getClearCurMetaTags();
    }
    else
        CurMetaTags=NULL;
    AddEspProperty();
 }
 | EspTemplateStart ESPTEMPLATE '<' EspType ID '>' ID ';'
 {
    if (CurParam)
    {
        CurParam->flags |= PF_TEMPLATE;
        CurParam->templ = strdup($2.getName());
        CurParam->name = strdup($5.getName());
        CurParam->typname = CurParam->name;
        CurParam->name = strdup($7.getName());
        CurParam->tags = getClearCurMetaTags();
    }
    else
        CurMetaTags=NULL;
    AddEspProperty();
 }
 | EspTemplateStart ESPTEMPLATE '<' EspType ID ',' ID '>' ID ';'
 {
    if (CurParam)
    {
        CurParam->flags |= PF_TEMPLATE;
        CurParam->templ = strdup($2.getName());
        CurParam->name = strdup($5.getName());
        CurParam->typname = CurParam->name;
        CurParam->name = strdup($9.getName());

        AddMetaTag(new MetaTagInfo("item_tag", $7.getName()));

        CurParam->tags = getClearCurMetaTags();
    }
    else
        CurMetaTags=NULL;
    AddEspProperty();
 }
 | EspPropertyStart StartParam ESPSTRUCTREF ID ID ';'
 {
    if (CurParam)
    {
        CurParam->name=strdup($5.getName());
        CurParam->typname=strdup($4.getName());
        CurParam->kind=TK_ESPSTRUCT;
        CurParam->tags = getClearCurMetaTags();
        AddEspProperty();
    }
 }
 | EspPropertyStart StartParam ESPENUMREF ID ID OptEspEnumInit ';'
 {
    if (CurParam)
    {
        CurParam->name=strdup($5.getName());
        CurParam->typname=strdup($4.getName());
        CurParam->kind=TK_ESPENUM;
        CurParam->tags = getClearCurMetaTags();
        AddEspProperty();
    }
 }
 | EspPropertyStart Param EspPropertyInit ';'
 {
    if (CurParam)
    {
        //special well known types
        if (CurParam->kind==TK_STRUCT)
        {
            if (!strcmp(CurParam->typname, "int64"))
                CurParam->kind=TK_INT;
        }
        CurParam->tags = getClearCurMetaTags();
        AddEspProperty();
    }
 }
 ;

OptEspEnumInit
 : '(' INTEGER_CONST ')'
 {
    AddMetaTag(new MetaTagInfo("default", $2.getInt()));
 }
 | '(' string_const ')'
 {
    AddMetaTag(new MetaTagInfo("default", $2.getString()));
 }
 |
 {
 }
 ;

EspPropertyInit
 : '(' INTEGER_CONST ')'
 {
    int val = $2.getInt();
    AddMetaTag(new MetaTagInfo("default", val));
 }
 | '(' '-' INTEGER_CONST ')'
 {
    int val = -$3.getInt();
    AddMetaTag(new MetaTagInfo("default", val));
 }
 | '(' DOUBLE_CONST ')'
 {
    double val = $3.getDouble();
    AddMetaTag(new MetaTagInfo("default", val));
 }
 | '(' '-' DOUBLE_CONST ')'
 {
    double val = -$3.getDouble();
    AddMetaTag(new MetaTagInfo("default", val));
 }
 | '(' BOOL_CONST ')'
 {
    AddMetaTag(new MetaTagInfo("default", $2.getInt()));
 }
 | '(' string_const ')'
 {
    AddMetaTag(new MetaTagInfo("default", $2.getString()));
 }
 | '(' ')'
 {
    AddMetaTag(new MetaTagInfo("default", 0));
 }
 |
 {
    //AddMetaTag(new MetaTagInfo("default", 0));
 }
 ;

EspTemplateStart
 : EspPropertyStart StartParam
 ;

EspTemplateParams
 : TypeModifiers TypeList
 {
 }
 | TypeModifiers
 {
 }
 /*
 | ESPSTRUCTREF ID
 {
 }
 |
 {
 }
 */
 ;
EspPropertyStart
 : EspMetaData
 ;

/*
EspTypeRef
 : ESPSTRUCTREF
 {  CurParam->kind = TK_ESPSTRUCT; }
 | ESPENUMREF
 {  CurParam->kind = TK_ESPENUM; }
 ;
*/

EspType
 : ESPSTRUCTREF
 | ESPENUMREF
 {  CurParam->kind = TK_ESPENUM; }
 ;

EspMetaData
 : '[' EspMetaPropertyList OptionalComma ']'
 | '[' ']'
 |
 ;

EspMetaPropertyList
 : EspMetaProperty
 | EspMetaPropertyList ',' EspMetaProperty
 ;

EspMetaProperty
 : ID '(' INTEGER_CONST ')'
 {
    AddMetaTag(new MetaTagInfo($1.getName(), $3.getInt()));
 }
 | ID '(' string_const ')'
 {
    AddMetaTag(new MetaTagInfo($1.getName(), $3.getString()));
 }
 | ID '(' DOUBLE_CONST ')'
 {
    AddMetaTag(new MetaTagInfo($1.getName(), $3.getDouble()));
 }
 | ID '(' CONST_ID ')'
 {
    AddMetaTag(new MetaTagInfo($1.getName(), $3.getName(),true));
 }
 | ID
 {
    AddMetaTag(new MetaTagInfo($1.getName(), 1));
 }
 ;

Module
 : ModuleStart ModuleVersion ModuleBody ';'
 {
    if (CurModule) {
        CurModule->write_header_class();
    }
    AddModule();
    CurModule = NULL;
 }
 ;


ModuleStart
 : SCMINTERFACE ID
 {
   CurModule = new ModuleInfo($2.getName());
   CurModule->isSCMinterface = true;
   LastProc = NULL;
 }
 ;


ModuleVersion
 :'(' INTEGER_CONST ')'
 {
   CurModule->version = $2.getInt();
   if ((CurModule->version>255)||(CurModule->version<0))
   {
        errnum = 5;
        yyerror("version must be in range 0-255");
   }
 }
 | '(' ID ')'
 {
   CurModule->base = strdup($2.getName());
 }
 |
 ;

ModuleBody
 : '{' ProcDefList '}'
 | '{' '}'
 ;


Enumeration
 : EnumerationStart EnumerationBody ';'
 {
    if (CurEnum) {
        CurEnum->write_header_enum();
    }
    AddEnum();
    CurEnum = NULL;
 }
 ;


EnumerationStart
 : SCMENUM ID
 {
   EnumValue = 0;
   CurEnum = new EnumInfo($2.getName());
   LastEnumVal = NULL;
 }
 ;

EnumerationBody
 : '{' EnumDefList '}'
 ;


EnumDefList
 : EnumDef
 {
   if (CurEnumVal)
   {
     if (LastEnumVal)
       LastEnumVal->next = CurEnumVal;
     else
       CurEnum->vals = CurEnumVal;
     LastEnumVal = CurEnumVal;
   }
 }
 | EnumDefList ',' EnumDef
 {
   if (CurEnumVal)
   {
     LastEnumVal->next = CurEnumVal;
     LastEnumVal = CurEnumVal;
   }
 }
 ;

EnumDef
 : ID '=' INTEGER_CONST
 {
    EnumValue = $3.getInt();
    CurEnumVal = new EnumValInfo($1.getName(),EnumValue);
    EnumValue++;
 }
 | ID '=' '-' INTEGER_CONST
 {
    EnumValue = - $4.getInt();
    CurEnumVal = new EnumValInfo($1.getName(),EnumValue);
    EnumValue++;
 }
 | ID
 {
    CurEnumVal = new EnumValInfo($1.getName(),EnumValue);
    EnumValue++;
 }
 ;


Api
 : ApiStart ProcAttrList RetParam '(' ParamList ')' ';'
 {
   if (CurApi)
   {
      CurApi->proc = CurProc;
       AddApi();
      CurApi->write_header_method();

       CurApi = NULL;
      CurProc = NULL;
      LastParam = NULL;
   }
 }
 ;

EspVersionDef
 : ESPVERSIONDEF '(' ID ',' DOUBLE_CONST ')' ';'
 {
    outf(0, "const double %s = %f;", $3.getName(), $5.getDouble());
 }
 ;

ApiStart
 : SCMAPI
 {
   CurApi = new ApiInfo(hcp->getPackageName());
   CurProc = new ProcInfo();
    CurModule = NULL;
   LastProc = NULL;
   if (esp_def_export_tag.empty())
     esp_def_export_tag.append(hcp->getPackageName()).append("_API");
 }
 | SCMAPI '(' ')'
 {
   CurApi = new ApiInfo(hcp->getPackageName());
   CurProc = new ProcInfo();
    CurModule = NULL;
   LastProc = NULL;
   if (esp_def_export_tag.empty())
     esp_def_export_tag.append(hcp->getPackageName()).append("_API");
 }
 | SCMAPI '(' ID ')'
 {
   CurApi = new ApiInfo($3.getName());
   CurProc = new ProcInfo();
    CurModule = NULL;
   LastProc = NULL;
   if (esp_def_export_tag.empty())
     esp_def_export_tag.append($3.getName()).append("_API");
 }
 ;


ProcDefList
 : ProcDef
 {
   if (CurProc)
   {
     if (LastProc)
       LastProc->next = CurProc;
     else
       CurModule->procs = CurProc;
     LastProc = CurProc;
   }
 }
 | ProcDefList ProcDef
 {
   if (CurProc)
   {
     LastProc->next = CurProc;
     LastProc = CurProc;
   }
 }
 ;

ProcDef
 : StartProc ProcAttrList RetParam '(' ParamList ')' ConstFunc Abstract ';'
 {
   LastParam = NULL;
 }
 ;


ProcAttr
 : Virtual
 | Callback
 | Async
 | Timeout
 ;

ProcAttrList
 : ProcAttr ProcAttrList
 |
 ;


RetParam
 : StartRetParam TypeModifiers TypeList
 {
    if (CurParam)
   {
     if (CurProc->async && CurParam)
     {
       errnum = 6;
       yyerror("Return not allowed");
     }
     if (CurProc->name)
        free(CurProc->name);
     CurProc->name = CurParam->name;
     CurParam->name = strdup(RETURNNAME);
   }
   CurProc->rettype = CurParam;
   CurParam = NULL;
 }
 ;

ParamList
 : Param
 {
   if (LastParam)
     LastParam->next = CurParam;
   else
     CurProc->params = CurParam;
   LastParam = CurParam;
 }
 | ParamList ',' Param
 {
   LastParam->next = CurParam;
   LastParam = CurParam;
 }
 ;


Param
 : StartParam TypeModifiers TypeList
 {
   if ((CurParam->flags&(PF_IN|PF_OUT))==0)
     CurParam->flags |= PF_IN;
 }
 |
 ;

TypeModifiers
 : TypeModifier TypeModifiers
 |
 ;

TypeModifier
 : InOut
 | String
 | SizeInfo
 | Layout
 ;



Layout
 : LAYOUT '(' LayoutParams ')'
 {
   LastLayout = NULL;
 }
 ;

LayoutParams
 : LayoutValue
 {
   if (LastLayout)
     LastLayout->next = CurLayout;
   else
     CurParam->layouts = CurLayout;
   LastLayout = CurLayout;
 }
 | LayoutParams ',' LayoutValue
 {
   LastLayout->next = CurLayout;
   LastLayout = CurLayout;
 }
 ;

LayoutValue
 : LayoutSizeVal CountVal
 ;

CountVal
 : STAR IntOrId
 {
   CurLayout->count = strdup($2.getName());
 }
 |
 ;

LayoutSizeVal
 : StartLayout INTEGER_CONST
 {
   CurLayout->size = strdup($2.getName());
 }
 | StartLayout '+' INTEGER_CONST
 {
   CurLayout->size = strdup($3.getName());
 }
 | StartLayout '-' INTEGER_CONST
 {
   CurLayout->size = (char*)malloc(strlen($3.getName())+2);
   strcpy(CurLayout->size, "-");
   strcat(CurLayout->size, $3.getName());
 }
 ;

StartLayout
 :
 {
   CurLayout = new LayoutInfo;
 }
 ;

String
 : STRING
 {
   CurParam->flags |= PF_STRING;
    CurParam->setXsdType($1.getName());
 }
 ;


InOut
 : _IN
 {
   CurParam->flags |= PF_IN;
 }
 | _OUT
 {
   CurParam->flags |= PF_OUT;
 }
 | INOUT
 {
   CurParam->flags |= (PF_IN|PF_OUT);
 }
 ;

StartRetParam
 : StartParam
 {
   rettype = true;
 }
 ;

StartParam
 :
 {
   CurParam = new ParamInfo;
   rettype = false;
 }
 ;

SizeInfo
 : _SIZE '(' IntOrId ')'
 {
   CurParam->flags |= PF_VARSIZE;
   CurParam->size = strdup($3.getName());
 }
 | SIZEBYTES '(' IntOrId ')'
 {
   CurParam->flags |= PF_VARSIZE;
   CurParam->sizebytes = strdup($3.getName());
 }
 ;

IntOrId
 : INTEGER_CONST
 {
   $$.setNameF("%d", $1.getInt());
 }
 | ID
 {
   $$.setName($1.getName());
 }
 ;

TypeList
 : Type
 | TypeList Type
 ;

Type
 : _CHAR
 {
   switch(CurParam->kind)
   {
     case TK_UNSIGNED:
       CurParam->kind = TK_UNSIGNEDCHAR;
       break;
     case TK_null:
       CurParam->kind = TK_CHAR;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | _BYTE
 {
   switch(CurParam->kind)
   {
     case TK_null:
       CurParam->kind = TK_BYTE;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | _BOOL
 {
   switch(CurParam->kind)
   {
     case TK_null:
       CurParam->kind = TK_BOOL;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | _SHORT
 {
   switch(CurParam->kind)
   {
     case TK_UNSIGNED:
       CurParam->kind = TK_UNSIGNEDSHORT;
       break;
     case TK_null:
       CurParam->kind = TK_SHORT;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | _VOID
 {
   CurParam->kind = TK_VOID;
 }
 | _INT
 {
   switch(CurParam->kind)
   {
     case TK_UNSIGNED:
       break;
     case TK_SHORT:
       CurParam->kind = TK_SHORT;
       break;
     case TK_LONG:
       CurParam->kind = TK_LONG;
       break;
     case TK_null:
       CurParam->kind = TK_INT;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | _UNSIGNED
 {
   switch(CurParam->kind)
   {
     case TK_null:
       CurParam->kind = TK_UNSIGNED;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | _LONG
 {
   switch(CurParam->kind)
   {
     case TK_LONG:
       CurParam->kind = TK_LONGLONG;
       break;
     case TK_UNSIGNED:
       CurParam->kind = TK_UNSIGNEDLONG;
       break;
     case TK_UNSIGNEDLONG:
       CurParam->kind = TK_UNSIGNEDLONGLONG;
       break;
     case TK_null:
       CurParam->kind = TK_LONG;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | STAR
 {
    if (CurParam->flags&(PF_PTR|PF_REF))
    {
        errnum = 8;
        yyerror("parameter type not supported");
    }
    else
    {
        CurParam->flags|=PF_PTR;
    }
 }
 | UMBERSAND
 {
    if (CurParam->flags&(PF_REF))
    {
        errnum = 8;
        yyerror("parameter type not supported");
    }
    else
    {
        CurParam->flags|=PF_REF;
    }
 }
 | _CONST
 {
    CurParam->flags |= PF_CONST;
 }
 | _DOUBLE
 {
   switch(CurParam->kind)
   {
     case TK_null:
       CurParam->kind = TK_DOUBLE;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | _FLOAT
 {
   switch(CurParam->kind)
   {
     case TK_null:
       CurParam->kind = TK_FLOAT;
       break;
     default:
     {
       errnum = 7;
       yyerror("invalid type");
     }
   }
 }
 | XSDTYPE
 {
    CurParam->setXsdType($1.getName());
 }
 | ID
 {
   if (rettype)
   {
     if (!CurParam)
     {
       errnum = 9;
       yyerror("unknown/unexpected ID");
     }
     else if (CurParam->kind==TK_null)
     {
       CurParam->kind = TK_STRUCT;
       CurParam->typname = strdup($1.getName());
     }
     else if ((CurParam->kind==TK_VOID)&&((CurParam->flags&PF_PTR)==0))
     {
       CurProc->name = strdup($1.getName());
       delete CurParam;
       CurParam = NULL;
     }
     else
     {
       CurParam->flags |= (PF_OUT|PF_RETURN);
       check_param();
     }
   }
   if (CurParam)
   {
     if (CurParam->name && ((CurParam->flags&PF_RETURN)==0))
     {
       if (CurParam->kind==TK_null)
       {
         CurParam->kind = TK_STRUCT;
         CurParam->typname = strdup(CurParam->name);
       }
       else
       {
         errnum = 9;
         yyerror("unknown/unexpected ID");
       }
     }
     if (CurParam->name)
        free(CurParam->name);
     CurParam->name = strdup($1.getName());
   }
 }
// | ESPTEMPLATE
 ;

StartProc
 :
 {
   CurProc = new ProcInfo();
   if (CurModule!=NULL && CurModule->isSCMinterface)
      CurProc->virt = 2;
 }
 ;

Virtual
 : VIRTUAL
 {
   if (CurProc->virt==0)
      CurProc->virt = 1;
 }
 ;

Abstract
 : '=' INTEGER_CONST
 {
   if (CurProc->virt && ($2.getInt()==0))
     CurProc->virt = 2;
   else
   {
     errnum = 10;
     yyerror("abstract not allowed on non-virtual");
   }
 }
 |
 ;

ConstFunc
 : _CONST
 {
   CurProc->constfunc = 1;
 }
 |
 ;

Callback
 : _CALLBACK
 {
   CurProc->callback = 1;
 }
 ;

Async
 : ASYNC
 {
   CurProc->async = 1;
 }
 ;

Timeout
 : TIMEOUT '(' IntOrId ',' IntOrId ')'
 {
    CurProc->conntimeout = strdup($3.getName());
    CurProc->calltimeout = strdup($5.getName());
 }
 ;

string_const
 : STRING_CONST
 | string_const STRING_CONST
 {
    //note: we return {"string"} with quotes on both sides
     size_t len1 = strlen($1.getString());
     size_t len2 = strlen($2.getString());
     char* s = (char*)malloc(len1+len2-1);
     memcpy(s, $1.getString(), len1-1);
     memcpy(s+len1-1, $2.getString()+1, len2);
     $$.setVal(s);
 }
 ;

/************************  END OF RULES  **********************/

%%

void AddModule()
{
   if (CurModule)
   {
     if (LastModule)
       LastModule->next = CurModule;
     else
       hcp->modules = CurModule;
     LastModule = CurModule;
   }
}

void TestOut(const char *str)
{
    outs(str);
}

void AddApi()
{
   if (CurApi)
   {
     if (LastApi)
       LastApi->next = CurApi;
     else
       hcp->apis = CurApi;
     LastApi = CurApi;
   }
}

void AddEspMessage()
{
   if (CurEspMessage)
   {
     if (LastEspMessage)
       LastEspMessage->next = CurEspMessage;
     else
       hcp->msgs = CurEspMessage;
     LastEspMessage = CurEspMessage;
   }
}

void AddEspProperty()
{
   if (CurParam)
   {
     if (LastParam)
       LastParam->next = CurParam;
     else
       CurEspMessage->setParams(CurParam);
     LastParam = CurParam;
   }
}

void AddEspService()
{
   if (CurService)
   {
     if (LastService)
       LastService->next = CurService;
     else
       hcp->servs = CurService;
     LastService = CurService;
   }
}

void AddEspInclude()
{
   if (CurInclude)
   {
     if (LastInclude)
       LastInclude->next = CurInclude;
     else
       hcp->includes = CurInclude;
     LastInclude = CurInclude;
   }
}

void AddMetaTag(MetaTagInfo *mti)
{
    mti->next=CurMetaTags;
    CurMetaTags=mti;
}

MetaTagInfo* getClearCurMetaTags()
{
    // no dup; max_ver, depr_ver can not both appear
    std::set<std::string> tagNames;
    for (MetaTagInfo* t = CurMetaTags; t!=NULL; t = t->next)
    {
        // alias
        if (streq("deprecated_ver",t->getName()))
            t->setName("depr_ver");

        if (tagNames.find(t->getName())!= tagNames.end())
        {
            VStrBuffer msg("Attribute '%s' are declared more than once", t->getName());
            yyerror(msg.str());
        }
        else
        {
            if ( (streq("depr_ver",t->getName()) && tagNames.find("max_ver")!=tagNames.end())
              || (streq("max_ver",t->getName()) && tagNames.find("depr_ver")!=tagNames.end()) )
                yyerror("max_ver and depr_ver can not be used together");

            tagNames.insert(t->getName());
        }
    }

    MetaTagInfo* ret = CurMetaTags;
    CurMetaTags = NULL;
    return ret;
}

void AddEnum()
{
   if (CurEnum)
   {
     if (LastEnum)
       LastEnum->next = CurEnum;
     else
       hcp->enums = CurEnum;
     LastEnum = CurEnum;
   }
}


extern char *yytext;
void yyerror(const char *s)
{
    if (!errnum)
      errnum = 99;
    if (yytext[0] == '\n')
    {
      yytext = (char*)strdup("EOL");
    }
    // the following error format work with Visual Studio double click.
    printf("%s(%d) : syntax error H%d : %s near \"%s\"\n",hcp->filename, linenum, errnum, s, yytext);
    outf("*** %s(%d) syntax error H%d : %s near \"%s\"\n",hcp->filename, linenum, errnum, s, yytext);
    errnum = 0;
}

void invalid_return_type();

void check_param(void)
{
    if (isSCM) {
        if ((CurParam->flags&PF_PTR)&&(CurParam->kind==TK_CHAR))
            CurParam->flags |= PF_STRING;
    }
    if ((CurProc->async)&&(CurParam->flags&(PF_OUT|PF_RETURN)))
    {
        errnum = 1;
        yyerror("out parameters not allowed on async procedure");
    }
    if ((CurParam->flags&(PF_CONST&PF_OUT))==(PF_CONST|PF_OUT))
    {
        errnum = 2;
        yyerror("const not allowed on out parameter");
    }
    switch (CurParam->flags&(PF_IN|PF_OUT|PF_STRING|PF_VARSIZE|PF_PTR|PF_REF|PF_RETURN))
    {
        case PF_IN:                                 // int T
        case (PF_IN|PF_REF):                        // in T&
        case (PF_IN|PF_OUT|PF_REF):                 // inout T&
        case (PF_OUT|PF_REF):                       // out T&
        case (PF_IN|PF_PTR|PF_VARSIZE):             // in size() T*
        case (PF_OUT|PF_PTR|PF_VARSIZE):            // out size() T*
        case (PF_IN|PF_OUT|PF_PTR|PF_VARSIZE):      // inout size() T*
        case (PF_OUT|PF_PTR|PF_REF|PF_VARSIZE):     // inout size() T*&
        case (PF_IN|PF_PTR|PF_STRING):              // in string const char *
        case (PF_OUT|PF_PTR|PF_REF|PF_STRING):      // out string char *&
        case (PF_OUT|PF_RETURN):                    // return simple
        case (PF_OUT|PF_PTR|PF_VARSIZE|PF_RETURN):  // return size() T*
        case (PF_OUT|PF_PTR|PF_STRING|PF_RETURN):   // return out string char *
            break;
        case (PF_OUT|PF_PTR|PF_RETURN):                 // return T*
        case (PF_OUT|PF_REF|PF_RETURN):                 // return T&
            if (!isSCM)
            {
                invalid_return_type();
            }
            break;
        default:
            invalid_return_type();
            break;
    }
}

void invalid_return_type()
{
    // printf("Parameter flags %x\n",p->flags);
    if (CurParam->flags&PF_RETURN )
    {
        errnum = 3;
        printf("type = %d\n",CurParam->flags);
        yyerror("Invalid return type");
    }
    else
    {
        errnum = 4;
        yyerror("Invalid parameter combination");
    }
}
