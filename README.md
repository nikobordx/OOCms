OOCms Version 0.7
=================

GENERAL
-------
OOCms is a CMS(Content Management System) wich can run as a CGI application(thanks to OOCgi) on any server that supports parsed header output. It is completely customizable, 
thanks to a "template" system described below. When you load the CGI page with your browser, OOCms parses the query string that you pass in the address bar. It looks for a "page" 
argument, wich passes the name of the template to open and a "subpage" argument wich passes the name of the thtml and db file to parse. For example, oocms.cgi?page=news&subpage=allNews 
would make oocms look for a template named "news" and open the allNews.thtml and allNews.db file located in the templates/news/. If no subpage argument is passed, index is guessed. 
Similarly, if no page argument is passed, IndexTemplate is guessed.

THTML Language
---------------
To write templates for oocms, you must use THTML code.
THTML files are just like normal HTML files but in addition to that, they contain the THTML code wich will be parse by oocms.
After the code is parsed and the dynamic content is generated, oocms will look for design/page.html file and replace any occurence of __[]__ with the content previously generated.
There are two major features in THTML. First, you can open up databases and show their contents. Second, you can loop through some code, with loops and conditions.
All code found between <% and %> will be barsed by oocms. But first, lets talk about variables. THTML variables are just like variables in other languages. They are typed and can be
used by functions. The variable types that currently exist are: Int,String,Map and Array. Array and Map use String variables exclusively. To get a String value out of an Array, you just
have to do:
    
    ArrayName(num)
    
where num is an Int variable or a number. Similarly, to do that with a Map, you do:

    MapName(str)

where str is a String variable or a string (no need for quoted in THTML). You can also "fusion" variables of Int and String type by doing someThing{blah}someThingElse. This will parse 
someThing, get its value (wether its a variable, Int or String, or a string) and replace the whole {blah} section of the expression with the returned value.
Then, there are functions. In THTML, functions are used by writing:

    FuncName: funcArg1,funcArg2,...
    
All variable declarations are done through functions. There are two types of functions. Those who handle a database and those who show and print variables.
Lets see the current variable handling functions.

    Database: dbName,ordering
dbName: The name of the database to open
ordering: It should be either ASCORDER[colname] or DESCORDER[colname]. Enables sorting the database in ascending or descending order based on the column specified in colname.

    Column: varName,colName
Specifies a variable of type Array named varName, wich contains the values of the fields found in column colName.

    Line: colName,value,varName
Specifies a variable of type Map named varName, wich contains the values of the line of the databases who matches the criteria: Column[colName] = value

    
    LineCount: varName
Specifies a variable of type Int named varName, wich contains the number of lines found in the database

That are the database handling functions. Soon (hopefully), DeleteLine and EditField will be added.
Now lets see the rest of the functions.

    Show: varName
Prints the value of the variable varName (if it is NULL, nothing will be printed)

    ArrayPrint: arrayName
Prints the values of the array named varName (if it is NULL, nothing will be printed)

In addition to these, there should be MapPrint coming soon.
If you wish to write multiple functions in one line of thtml code, you can use the ';' symbol. For example. you can do:

    Show: something(0); ArrayPrint: something
    
The semicolon can of course be used for a single function but is optional.

OOCms sets three variables by default, of type Map, named _GET, _POST and _CONFIG. The first two contain the get and post HTTP request parameters.
The third one contains values declared in the file config/oocms.cfg. To declare a variable through this file, you just have to open it up and write
    
    VarName:VarValue
    AnotherVarName:AnotherVarValue
    ...
    
Note that spaces used before or after ':' will be included in the variable name/value of this field.
By default, there are three variables specified in this file. The first and second one are adminName and adminPass, wich are used by the admin template and
you __MUST__ change them upon getting your copy of oocms, so as not to be hacked. The third one is version, wich just contains the number of the current oocms
version.

Also, there is a special variable named NULL, wich is used for conditions and is the same as the NULL keyword is in other languages and another one named '
wich counted as a space (spaces are stripped on parsing, so i made this little helper ;p)
Finaly, there is one more interesting feature in THTML, blocks.
Blocks are either loops or conditions.
A block starts with { and ends with } and doesnt need to be surrounded by <% and %>
Also, after the ~| there MUST be a [ character. Then comes the condition/loop and finally the ]. To set a condition, you must write
[ SomeValue == SomeOtherValue ] or [ SomeValue != SomeOtherValue ]. If the condition is true, the block will be executed one time. For example, here
is an interesting thing you can do using a condition

    {[ _POST(user) != NULL ]
        <p>Hello, <% Show: _POST(user) %></p>
    |~
    {[ _POST(user) == NULL ]
        <p>Please login</p>
    }

Then, there are loops. When you write a loop, you actually specify a new, temporary, Int variable. Any variable already holding this name will be overwriten.
To specify a loop, you must do [ TempVar: StartValue .. EndValue]. For example, here is how you can loop through the all posts in a news database

    {[ i: 0..NewsCount ]
        <h1><% Show: Title(i) %></h1><br/>
        <em><p>Posted at <% Show: Date(i) %></p></em><br/>
        <p><% Show: Contents(i) %></p>
    |~

Note that nested blocks are possible (finally! [but after a lot of headaches -__-']), and that the starting value of a loop can be greater than its ending value ;)
That's all for now =D

Note: You should use password protection on templates and design subfolders but __MUST__ use password protection on databases and config subfolders. Password protection
is host/server specific, so nothing is included within a standard oocms distribution.

Note: from version 0.5, there are no longer .db files.

Note: there are more functions available, just look into sources, i will write a complete doc once a stable version is reached :)
