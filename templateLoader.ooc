use oocsv
use oocgi
import oocsv
import oocgi
import structs/MultiMap
import io/File
import structs/ArrayList
import addressParser
import tokenizer

// NO SEGFAULTS, BUT MANY THINGS TO FIX :/ 

Function : class
{
    name : String
    callback : Func(ArrayList<String>,TemplateLoader) -> String
    
    init : func (=name,=callback)
    {
    }
}

StrListContainer : class
{
    array := ArrayList<String> new()
}

StrStrMapContainer : class
{
    map := MultiMap<String,String> new()
}

TemplateLoader : class // class that takes care of loading the template's database and then generating the template itself
{
    db : Database
    status : String = "200"
    contents : String
    base : String
    
    thtmlArrays := MultiMap<String,StrListContainer> new()
    thtmlVars := MultiMap<String,String> new()
    thtmlMaps := MultiMap<String,StrStrMapContainer> new()
    
    thtmlFunctions := ArrayList<Function> new()
    
    init : func()
    {
        // Create our thtmlFunctions :) (Note the kewl new way to do that :D)
        thtmlFunctions add(Function new("Add",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 3)
                            {
                                // arg 1 : resulting variable
                                // arg 2 : left part
                                // arg 3 : right part
                                rsv1 := tl resolveVariable(args get(1))
                                rsv2 := tl resolveVariable(args get(2))
                                thtmlVars[args get(0)] = rsv1 + rsv2
                            }
                            else
                            {
                                return "ERROR: Function Add takes three arguments."
                            }
                            ""
                }))
        thtmlFunctions add(Function new("Show",func(args : ArrayList<String>, tl : TemplateLoader) {
                            returned := ""
                            if(args size == 1)
                            {
                                returned = tl resolveVariable(args get(0))
                            }
                            else
                            {
                                returned = "ERROR: Function Show takes one argument."
                            }
                            returned
                }))
        
        thtmlFunctions add(Function new("ArrayPrint",func(args : ArrayList<String>, tl : TemplateLoader) {
                            ret := ""
                            if(args size == 1)// we have our argument :)
                            {
                                if(tl thtmlArrays != null && tl thtmlArrays get(args get(0)) array != null)//if there is an array with that name
                                {
                                    //print awaaay!!!
                                    array := tl thtmlArrays get(args get(0)) array
                                    
                                    for(i in 0 .. array size)
                                    {
                                        ret += array get(i) + "<br/>"
                                    }
                                }
                            }
                            else
                            {
                                ret = "ERROR: Function ArrayPrint takes one argument."
                            }
                            ret
                }))
        
        thtmlFunctions add(Function new("MapPrint",func(args : ArrayList<String>, tl : TemplateLoader) {
                        ret := ""
                        if(args size == 1)
                        {
                            rsv := tl resolveVariable(args get(0))
                            if(tl thtmlMaps get(rsv) map != null)
                            {
                                for(i in 0 .. tl thtmlMaps get(rsv) map size)
                                {
                                    key := tl thtmlMaps get(rsv) map getKeys() get(i)
                                    ret += key + " => " + tl thtmlMaps get(rsv) map get(key) + "<br/>"
                                }
                            }
                        }
                        else
                        {
                            ret = "ERROR: Function MapPrint takes one argument."
                        }
                        ret
                }))
        
        thtmlFunctions add(Function new("Execute",func(args : ArrayList<String>, tl : TemplateLoader) { // Executes thtml code passed as argument
                        // Can be pretty cool coupled with ReadFile, they can then act as includes
                        ret := ""
                        if(args size == 1)
                        {
                            code := tl resolveVariable(args get(0))
                            tokens := Tokenizer parse(code)
                            ret = Tokenizer execute(tokens,tl)
                        }
                        else
                        {
                            ret = "ERROR: Function Execute takes one argument."
                        }
                        ret
                }))
        
        thtmlFunctions add(Function new("ReadFile",func(args : ArrayList<String>, tl : TemplateLoader) { // Reads data from file and stocks it to a variable
                        ret := ""
                        if(args size == 2)
                        {
                            rsv := tl resolveVariable(args get(1))
                            file := File new(rsv)
                            if(file file?())
                            {
                                tl thtmlVars[args get(0)] = file read()
                            }
                            else
                            {
                                ret = "ERROR: Could not locate file " + rsv
                            }
                        }
                        else
                        {
                            ret = "ERROR: Function ReadFile takes two arguments."
                        }
                        ret
                        
                }))
        
        thtmlFunctions add(Function new("Replace",func(args : ArrayList<String>, tl : TemplateLoader) {
                        if(args size == 4) // Arg 1 : name of new variable, arg 2 : name of previous variable, arg 3 : what? , arg 4 : with
                        {
                            rsv1 := tl resolveVariable(args get(1))
                            rsv2 := tl resolveVariable(args get(2))
                            rsv3 := tl resolveVariable(args get(3))
                            
                            tl thtmlVars[args get(0)] = rsv1 replaceAll(rsv2,rsv3) // Replace all occurences of "what?" with "with" in "var"
                        }
                        else
                        {
                            return "ERROR: Function Replace takes four arguments."
                        }
                        ""
                }))
        
        thtmlFunctions add(Function new("Set",func(args : ArrayList<String>, tl : TemplateLoader) { // Sets a variable to a certain value
                        if(args size == 2)
                        {
                            rsv := tl resolveVariable(args get(1))
                            tl thtmlVars[args get(0)] = rsv
                        }
                        else
                        {
                            return "ERROR: Function Set takes two arguments."
                        }
                        ""
                }))
        
        thtmlFunctions add(Function new("SetArray",func(args : ArrayList<String>, tl : TemplateLoader) { // Set an array variable to a ceratin value
                        if(args size == 3)
                        {
                            index := tl resolveVariable(args get(0)) toInt()
                            name := tl resolveVariable(args get(1))
                            value := tl resolveVariable(args get(2))
                            
                            if(tl thtmlArrays get(name) != null)
                            {
                                if(index >= tl thtmlArrays get(name) array size)
                                {
                                    for(i in tl thtmlArrays get(name) array size .. index + 1)
                                    {
                                        tl thtmlArrays get(name) array add(i,null)
                                    }
                                }
                
                                tl thtmlArrays get(name) array add(index,value)
                            }
                            else
                            {
                                tl thtmlArrays[name] = StrListContainer new()
                                if(index >= tl thtmlArrays get(name) array size)
                                {
                                    for(i in tl thtmlArrays get(name) array size .. index + 1)
                                    {
                                        tl thtmlArrays get(name) array add(i,null)
                                    }
                                }
                
                                tl thtmlArrays get(name) array add(index,value)
                            }
                        }
                        else
                        {
                            return "ERROR: Function SetArray takes three arguments."
                        }
                        ""
                }))
        
        thtmlFunctions add(Function new("SetMap",func(args : ArrayList<String>, tl : TemplateLoader) { // Set a map variable to a certain value
                        if(args size == 3)
                        {
                            index := tl resolveVariable(args get(0))
                            name := tl resolveVariable(args get(1))
                            value := tl resolveVariable(args get(2))
                            
                            if(tl thtmlMaps get(name) != null)
                            {
                                tl thtmlMaps get(name) map[index] = value
                            }
                            else
                            {
                                tl thtmlMaps[name] = StrStrMapContainer new()
                                tl thtmlMaps get(name) map[index] = value
                            }
                        }
                        else
                        {
                            return "ERROR: Function SetMap takes three arguments."
                        }
                        ""
                }))
        
        thtmlFunctions add(Function new("EscapeHtml",func(args : ArrayList<String>, tl : TemplateLoader) { // Sets a variable with escaped html output of another variable
                        if(args size == 2)
                        {
                            rsv := tl resolveVariable(args get(1))
                            rsv = rsv replaceAll("<","&lt;")
                            rsv = rsv replaceAll(">","&gt;")
                            tl thtmlVars[args get(0)] = rsv
                        }
                        else
                        {
                            return "ERROR: Function EscapeHtml takes two arguments."
                        }
                        ""
                }))
        
        thtmlFunctions add(Function new("DescOrder",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                if(tl db != null)
                                {
                                    rsv := resolveVariable(args get(0))
                                    tl db sortDescending(rsv)
                                }
                            }
                            else
                            {
                                return "ERROR: Function DescOrder takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("AscOrder",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                if(tl db != null)
                                {
                                    rsv := resolveVariable(args get(0))
                                    tl db sortAscending(rsv)
                                }
                            }
                            else
                            {
                                return "ERROR: Function AscOrder takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("Database",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                rsv1 := tl resolveVariable(args get(0))
                                if(rsv1 != null)
                                {
                                    tl db = Database new("databases/"+rsv1+".csv")
                                }
                            }
                            else
                            {
                                return "ERROR: Function Database takes one argument"
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("Column",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 2)
                            {
                                rsv := tl resolveVariable(args get(1))
                                if(tl db selectColumn(rsv) != null)
                                {
                                    tempArray := ArrayList<String> new()
                                    if(rsv != null)
                                    {
                                        col := tl db selectColumn(rsv)
                                        for(j in 0 .. col fields size)
                                        {
                                            tempArray add(col fields get(j) data)
                                        }
                                        tempContainer := StrListContainer new()
                                        tempContainer array = tempArray
                                        tl thtmlArrays[args get(0)] = tempContainer
                                    }
                                }
                            }
                            else
                            {
                                return "ERROR: Function Column takes two arguments."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("LineCount",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                if(tl db columns != null)
                                {
                                    tl thtmlVars[args get(0)] = ("%d" format(tl db columns get(0) fields size))
                                }
                            }
                            else
                            {
                                return "ERROR: Function LineCount takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("ColumnCount",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                if(tl db columns != null)
                                {
                                    tl thtmlVars[args get(0)] = ("%d" format(tl db columns size))
                                }
                            }
                            else
                            {
                                return "ERROR: Function ColumnCount takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("DatabaseCount",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                databases := File new("databases")
                                count := databases getChildren() size
                                if(count > 0)
                                {
                                    tl thtmlVars[args get(0)] = ("%d" format(count))
                                }
                            }
                            else
                            {
                                return "ERROR: Function DatabaseCount takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("DatabaseNames",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                databases := File new("databases")
                                tempArray := databases getChildrenNames()
                                for(i in 0 .. tempArray size)
                                {
                                    tempArray[i] = tempArray get(i) substring(tempArray get(i) find("\\",0)+1, tempArray get(i) find(".",0))
                                }
                                tempContainer := StrListContainer new()
                                tempContainer array = tempArray
                                tl thtmlArrays[args get(0)] = tempContainer
                            }
                            else
                            {
                                return "ERROR: Function DatabaseNames takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("ColumnNames",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                if(tl db columns != null)
                                {
                                    tempArray := ArrayList<String> new()
                                    for(i in 0 .. tl db columns size)
                                    {
                                        tempArray[i] = tl db columns get(i) name
                                    }
                                    tempContainer := StrListContainer new()
                                    tempContainer array = tempArray
                                    tl thtmlArrays[args get(0)] = tempContainer
                                }
                            }
                            else
                            {
                                return "ERROR: Function ColumnNames takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("PrintDatabase",func(args : ArrayList<String>, tl : TemplateLoader) {
                            ret := ""
                            if(args size == 1)
                            {
                                countS := tl resolveVariable(args get(0))
                                if(countS != null && db != null)
                                {
                                    count := countS toInt()
                                    if(count > 0)
                                    {
                                        ret += "<table border=\"1\"><tr>"
                                        for(i in 0 .. tl db columns size)
                                        {
                                            ret += "<th>"+(tl db columns get(i) name)+"</th>"
                                        }
                                        ret += "</tr><tr>"
                                        for(i in 0 .. count)
                                        {
                                            for(j in 0 .. tl db columns size)
                                            {
                                                if(tl db columns get(j) fields get(i) data != null)
                                                {
                                                    ret += "<td>"+tl db columns get(j) fields get(i) data+"</td>"
                                                }
                                                else
                                                {
                                                    ret += "<td><em>Empty field</em></td>"
                                                }
                                            }
                                            ret += "</tr>"
                                        }
                                        ret += "</table>"
                                    }
                                }
                            }
                            else
                            {
                                ret = "ERROR: Function PrintDatabase takes one argument."
                            }
                            ret
                }))
        
        thtmlFunctions add(Function new("Line",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 3)
                            {
                                rsv1 := tl resolveVariable(args get(0))
                                rsv2 := tl resolveVariable(args get(1))
                                if(rsv1 != null && rsv2 != null)
                                {
                                    fields := tl db selectLine(rsv1,rsv2)
                                    if(fields != null && fields size > 0)
                                    {
                                        if(fields size == tl db columns size)
                                        {
                                            tempMap := StrStrMapContainer new()
                                            for(i in 0 .. fields size)
                                            {
                                                tempMap map[tl db columns get(i) name] = fields get(i) data
                                            }
                                            tl thtmlMaps[args get(2)] = tempMap
                                        }
                                    }
                                }
                            }
                            else
                            {
                                return "ERROR: Function Line takes three arguments."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("DeleteLine",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 1)
                            {
                                indexS := tl resolveVariable(args get(0))
                                if(indexS != null)
                                {
                                    index := indexS toInt()
                                    tl db deleteLine(index)
                                    tl db save()
                                }
                            }
                            else
                            {
                                return "ERROR: Function DeleteLine takes one argument."
                            }
                            ""
                }))
        
        thtmlFunctions add(Function new("EditField",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size == 3)
                            {
                                param1 := tl resolveVariable(args get(0))
                                param2 := tl resolveVariable(args get(1))
                                param3 := tl resolveVariable(args get(2))
                                if(param1 != null && param2 != null && param3 != null)
                                {
                                    lineIndex := param1 toInt()
                                    colIndex := param2 toInt()
                                    if(tl db columns != null)
                                    {
                                        if(tl db columns size > colIndex && tl db columns get(colIndex) fields size > lineIndex)//field already exists
                                        {
                                            tl db columns get(colIndex) fields get(lineIndex) data = param3
                                        }
                                        else if(tl db columns size > colIndex && tl db columns get(colIndex) fields size <= lineIndex)//create field =D
                                        {
                                            for(i in tl db columns get(colIndex) fields size .. lineIndex+1)
                                            {
                                                for(j in 0 .. tl db columns size)// Need to loop through all columns too, elsewise database may bug at saving
                                                {
                                                    temp := (i == lineIndex && j == colIndex) ? param3 : ""
                                                    tl db columns get(j) fields add(i,Field new(temp))
                                                }
                                            }
                                        }
                                    }
                                    tl db save()
                                }
                            }
                            else
                            {
                                return "ERROR: Function EditField takes three arguments."
                            }
                            ""
                }))
    }
    
    executeFunction : func(name : String, args : ArrayList<String>) -> String
    {
        for(i in 0 .. thtmlFunctions size)
        {
            if(thtmlFunctions get(i) name == name)
            {
                return thtmlFunctions get(i) callback(args,this)
            }
        }
        "Error: no such functon " + name
    }
    
    loadConfig : func() -> StrStrMapContainer
    {
        file := File new("config/oocms.cfg")
        data := file read()
        ret := StrStrMapContainer new()
        part1 : String
        temp : String = ""
        for(i in 0 .. data size)
        {
            if(data[i] == ':')
            {
                part1 = temp
                temp = ""
            }
            else if(data[i] == '\n' || i == data size - 1)
            {
                if(i == data size - 1 && data[i] != '\n')
                {
                    temp += data[i]
                }
                ret map[part1] = temp
                temp = ""
                part1 = ""
            }
            else if(data[i] != '\n' && data[i] != '\r')
            {
                temp += data[i]
            }
        }
        ret
    }
    
    load : func(ap : AddressParser)
    {
        tempGetMap := StrStrMapContainer new()
        for(i in 0 .. ap getParams size)
        {
            tempGetMap map[ap getParams getKeys() get(i)] = ap getParams get(ap getParams getKeys() get(i))
        }
        thtmlMaps["_GET"] = tempGetMap
        tempPostMap := StrStrMapContainer new()
        for(i in 0 .. ap postParams size)
        {
            tempPostMap map[ap postParams getKeys() get(i)] = ap postParams get(ap postParams getKeys() get(i))
        }
        thtmlMaps["_POST"] = tempPostMap
    
        thtmlMaps["_CONFIG"] = loadConfig()
    
        //thtmlMaps["_SESSION"] = loadSession()
    
        getDesign()
    
        replaceOpens := base findAll("__[")
        replaceCloses := base findAll("]__")
        if(replaceOpens size == replaceCloses size)
        {
            contents = base
            for(i in 0 .. replaceOpens size)
            {
                file := base substring(replaceOpens get(i)+3,replaceCloses get(i))
                ofile := ""
                if(file == "" || file == null)
                {
                    ofile = "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.thtml" : ap getParams get("subpage")+".thtml")
                }
                else
                {
                    ofile = "design/"+file+".thtml"
                }
                data := parseFile(ofile)
                contents = contents replaceAll("__["+file+"]__",data)
            }
        }
        
    }
    getDesign : func ()
    {
        base = ""
        freader := File new("design/page.html")
        if(freader exists?())
        {
            base = freader read()
        }
        else
        {
            status = "404"
        }
    }
    parseFile : func (file : String) -> String
    {
        freader := File new(file)
        if(freader exists?())
        {
            tokens := ArrayList<Token> new()
            if(File new(file+".tokens") file?())
            {
                tokens = Tokenizer readFromFile(file+".tokens")
            }
            else
            {
                data := freader read()
                tokens = Tokenizer parse(data)
                Tokenizer saveToFile(tokens,file+".tokens")
            }
            
            return Tokenizer execute(tokens,this)
        }
        else
        {
            status = "404"
            return "The page you aked for does not exist. (Error 404)"
        }
        ""
    }
    
    resolveVariable : func (var : String) -> String // code that takes the name of a variable and returns its value
    {
        if(var size > 0)
        {
            if(var[0] == '"' && var[var size-1] == '"') // Hey! this is a string! :)
            {
                return var substring(1,var size-1) // Return the contents of the string =)
            }
            else if((var toInt() != 0) || (var toInt() == 0 && var == "0")) // Hey! a number!!!
            {
                return var
            }
    
            for(i in 0 .. thtmlVars size)// search for it in our count variables
            {
                key := thtmlVars getKeys() get(i)
                if(key == var)// hey ! here it is!
                {
                    return thtmlVars get(key)
                }
            }
            
            // we didnt find it in count vars! :O
            //No problemo, just search in thtmlArrays :)
            index := var substring(var find("(",0)+1,var find(")",0))// get index of array
            varn := var substring(0,var find("(",0))// and name of array ;)
            
            if(index != varn)
            {
                nIndex := resolveVariable(index)
                
                // ok, now we have a number in there :p
                if(nIndex != null && thtmlArrays get(varn) != null)
                {
                    if((thtmlArrays get(varn) array size > nIndex toInt()))
                    {
                        if(thtmlArrays get(varn) array get(nIndex toInt()) != null) // if we do have an array named like that and a field at that index
                        {
                            return thtmlArrays get(varn) array get(nIndex toInt())// send back value
                        }
                    }
                    else if(nIndex toInt() >= thtmlArrays get(varn) array size) // this array exists, however we are overloading its buffer!
                    {
                        return null// return null ;)
                    }
                }
                
                if(thtmlMaps != null && thtmlMaps get(varn) != null)
                {
                    if(thtmlMaps get(varn) map get(index) != null)// search into thtmlMaps
                    {
                        return thtmlMaps get(varn) map get(index)
                    }
                    else if(thtmlMaps get(varn) map get(resolveVariable(index)) != null)// search into thtmlMaps
                    {
                        return thtmlMaps get(varn) map get(resolveVariable(index))
                    }
                    else// ow..there is a map, but no such element
                    {
                        return null // ~NULL FTW~
                    }
                }
            }
        }
    
        return null // No variable found, send back null ;( 
    }
    
    parseCondition : func (cond : String) -> Bool
    {
        if(cond[0] != '[' || cond[cond size-1] != ']')
        {
            return false
        }
        else
        {
            insides := cond substring(1,cond size-1)
            insides = insides replaceAll(" ","")// Remove spaces ;)
            insides = insides replaceAll("\n","")//And remove newlines =)
            if(insides findAll("==") size == 1)
            {
                if(resolveVariable(insides substring(0,insides find("==",0))) == resolveVariable(insides substring(insides find("==",0)+2)))
                {
                    return true
                }
                else
                {
                    return false
                }
            }
            else if(insides findAll("!=") size == 1)
            {
                if(resolveVariable(insides substring(0,insides find("!=",0))) != resolveVariable(insides substring(insides find("!=",0)+2)))
                {
                    return true
                }
                else
                {
                    return false
                }
            }
        }
        false
    }
    
    loop : func (loop : String, tokens : ArrayList<Token>) -> String
    {
        ret := ""
        if(loop[0] != '[' || loop[loop size-1] != ']')
        {
            return ret
        }
        else
        {
        
            insides := loop substring(1,loop size-1)
            insides = insides replaceAll(" ","")// Remove spaces ;)
            insides = insides replaceAll("\n","")//And remove newlines =)

            toReplace := insides substring(0,insides find(":",0))
            part2 := insides substring(insides find(":",0)+1)
            if(toReplace != insides && part2 != null)
            {
                start := resolveVariable(part2 substring(0,part2 find("..",0)))
                end := resolveVariable(part2 substring(part2 find("..",0)+2))
            
                index := start toInt()//get int values...
                endIndex := end toInt()//...to loop in
                while(index != endIndex)//...ooc loop ^^
                {
                    thtmlVars[toReplace] = ("%d" format(index))// create the loop variable
                    moreData := Tokenizer execute(tokens,this) // execute code
                    
                    thtmlVars remove(toReplace)// remove the loop variable :) 
                    if(moreData != null)
                    {
                        ret += moreData
                    }
                    index = (index < endIndex) ? index+1 : index-1
                }
            }
        }
        ret
    }
    
}
