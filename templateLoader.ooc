use oocsv
use oocgi
import oocsv
import oocgi
import structs/MultiMap
import io/File
import structs/ArrayList
import addressParser

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
    
    arrays := MultiMap<String,StrListContainer> new()
    countVars := MultiMap<String,String> new()
    maps := MultiMap<String,StrStrMapContainer> new()
    
    functions := ArrayList<Function> new()
    
    init : func()
    {
        // Create our functions :) (Note the kewl new way to do that :D)
        functions add(Function new("Show",func(args : ArrayList<String>, tl : TemplateLoader) {
                            returned := (args size > 0) ? tl resolveVariable(args get(0)) : null
                            returned
                }))
        
        functions add(Function new("ArrayPrint",func(args : ArrayList<String>, tl : TemplateLoader) {
                            ret := ""
                            if(args size > 0)// we have our argument :)
                            {
                                if(tl arrays != null && tl arrays get(args get(0)) array != null)//if there is an array with that name
                                {
                                    //print awaaay!!!
                                    array := tl arrays get(args get(0)) array
                                    
                                    for(i in 0 .. array size)
                                    {
                                        ret += array get(i) + "<br/>"
                                    }
                                }
                            }
                            ret
                }))
        
        functions add(Function new("Database",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 0)
                            {
                                rsv1 := tl resolveVariable(args get(0))
                                if(rsv1 != null)
                                {
                                    tl db = Database new("databases/"+rsv1+".csv")
                                    if(args size > 1)
                                    {
                                        if(args get(1) startsWith?("DESCORDER"))
                                        {
                                            temp := args get(1) substring(10,args get(1) size-1) // and here we have our column name ;D
                                            rsv2 := tl resolveVariable(temp)
                                            if(rsv2 != null)
                                            {
                                                tl db sortDescending(rsv2)
                                            }
                                        }
                                        else if(args get(1) startsWith?("ASCORDER"))
                                        {
                                            temp := args get(1) substring(9,args get(1) size-1)
                                            rsv2 := tl resolveVariable(temp)
                                            if(rsv2 != null)
                                            {
                                                tl db sortAscending(rsv2)
                                            }
                                        }
                                    }
                                }
                            }
                            ""
                }))
        
        functions add(Function new("Column",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 1)
                            {
                                if(tl db selectColumn(args get(1)) != null)
                                {
                                    tempArray := ArrayList<String> new()
                                    rsv := tl resolveVariable(args get(1))
                                    if(rsv != null)
                                    {
                                        col := tl db selectColumn(rsv)
                                        for(j in 0 .. col fields size)
                                        {
                                            tempArray add(col fields get(j) data)
                                        }
                                        tempContainer := StrListContainer new()
                                        tempContainer array = tempArray
                                        tl arrays[args get(0)] = tempContainer
                                    }
                                }
                            }
                            ""
                }))
        
        functions add(Function new("LineCount",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 0)
                            {
                                if(tl db columns != null)
                                {
                                    tl countVars[args get(0)] = ("%d" format(tl db columns get(0) fields size))
                                }
                            }
                            ""
                }))
        
        functions add(Function new("ColumnCount",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 0)
                            {
                                if(tl db columns != null)
                                {
                                    tl countVars[args get(0)] = ("%d" format(tl db columns size))
                                }
                            }
                            ""
                }))
        
        functions add(Function new("DatabaseCount",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 0)
                            {
                                databases := File new("databases")
                                count := databases getChildren() size
                                if(count > 0)
                                {
                                    tl countVars[args get(0)] = ("%d" format(count))
                                }
                            }
                            ""
                }))
        
        functions add(Function new("DatabaseNames",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 0)
                            {
                                databases := File new("databases")
                                tempArray := databases getChildrenNames()
                                for(i in 0 .. tempArray size)
                                {
                                    tempArray[i] = tempArray get(i) substring(tempArray get(i) find("\\",0)+1, tempArray get(i) find(".",0))
                                }
                                tempContainer := StrListContainer new()
                                tempContainer array = tempArray
                                tl arrays[args get(0)] = tempContainer
                            }
                            ""
                }))
        
        functions add(Function new("ColumnNames",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 0)
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
                                    tl arrays[args get(0)] = tempContainer
                                }
                            }
                            ""
                }))
        
        functions add(Function new("PrintDatabase",func(args : ArrayList<String>, tl : TemplateLoader) {
                            ret := ""
                            if(args size > 0)
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
                            ret
                }))
        
        functions add(Function new("Line",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 2)
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
                                            tl maps[args get(2)] = tempMap
                                        }
                                    }
                                }
                            }
                            ""
                }))
        
        functions add(Function new("DeleteLine",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 0)
                            {
                                indexS := tl resolveVariable(args get(0))
                                if(indexS != null)
                                {
                                    index := indexS toInt()
                                    tl db deleteLine(index)
                                    tl db save()
                                }
                            }
                            ""
                }))
        
        functions add(Function new("EditField",func(args : ArrayList<String>, tl : TemplateLoader) {
                            if(args size > 2)
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
                            ""
                }))
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
        file := "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.thtml" : ap getParams get("subpage")+".thtml") // path of template html file to parse
    
        tempGetMap := StrStrMapContainer new()
        for(i in 0 .. ap getParams size)
        {
            tempGetMap map[ap getParams getKeys() get(i)] = ap getParams get(ap getParams getKeys() get(i))
        }
        maps["_GET"] = tempGetMap
        tempPostMap := StrStrMapContainer new()
        for(i in 0 .. ap postParams size)
        {
            tempPostMap map[ap postParams getKeys() get(i)] = ap postParams get(ap postParams getKeys() get(i))
        }
        maps["_POST"] = tempPostMap
    
        maps["_CONFIG"] = loadConfig()
    
        getDesign()
        parseFile(file)// parse thtml file =D
        
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
    parseFile : func (file : String)
    {
        freader := File new(file)
        if(freader exists?())
        {
            data := freader read()
            newData := parseChunk(data)
            contents = base replaceAll("__[]__",newData)
        }
        else
        {
            status = "404"
        }
    }
    
    resolveVariable : func (var : String) -> String // code that takes the name of a variable and returns its value
    {
        //TODO: add contencation using {} (for example hell{o} will give hello and then hello will be resolved or _POST(colIndex{i}), where i is loop var will give _POST(colIndex0),_POST(colIndex1),...
        openFusion := var find("{",0)//get the opening fusion symbol index
        closeFusion : SSizeT = -1
        closeFusions := var findAll("}")
        // this is basically for nested blocks but i reuse it here for nested fusions :)
        if(openFusion != -1 && var findAll("{") size == closeFusions size)
        {
            for(i in 0 .. closeFusions size)// we iterate the closing fusion symbols
            {
                test := var substring(openFusion+1,closeFusions get(i))//we make a substring out of the fusion symbols
                if(test findAll("{") size == test findAll("}") size)// if there is the same number of opening and closing fusion symbols in this substring
                {
                    closeFusion = closeFusions get(i)// this means we have a valid fusion =) 
                    break// break the loop :)
                }
            }
        
            if(closeFusion != -1)
            {
                fusionRet := resolveVariable(var substring(openFusion+1,closeFusion)) // get the var returned by fusion
                left := var substring(0,openFusion) // get the var on the left of the fusion
                right := var substring(closeFusion+1) // and the one on the right
                var = left// add
                var = (var == null) ? fusionRet : var+fusionRet// them
                var = (var == null) ? right : var+right// up
            }
        }
    
        for(i in 0 .. countVars size)// search for it in our count variables
        {
            key := countVars getKeys() get(i)
            if(key == var)// hey ! here it is!
            {
                return countVars getAll(key)
            }
        }
        
        // we didnt find it in count vars! :O
        //No problemo, just search in arrays :)
        index := var substring(var find("(",0)+1,var find(")",0))// get index of array
        varn := var substring(0,var find("(",0))// and name of array ;)
        
        if(index != varn)
        {
            nIndex := (index toInt() == 0 && index != "0") ? resolveVariable(index) : index
            
            // ok, now we have a number in there :p
            if(nIndex != null && arrays get(varn) != null)
            {
                if((arrays get(varn) array size > nIndex toInt()))
                {
                    if(arrays get(varn) array get(nIndex toInt()) != null) // if we do have an array named like that and a field at that index
                    {
                        return arrays get(varn) array get(nIndex toInt())// send back value
                    }
                }
                else if(nIndex toInt() >= arrays get(varn) array size) // this array exists, however we are overloading its buffer!
                {
                    return null// return null ;)
                }
            }
            
            if(maps != null && maps get(varn) != null)
            {
                if(maps get(varn) map get(index) != null)// search into maps
                {
                    return maps get(varn) map get(index)
                }
                else if(maps get(varn) map get(resolveVariable(index)) != null)// search into maps
                {
                    return maps get(varn) map get(resolveVariable(index))
                }
                else// ow..there is a map, but no such element
                {
                    return null // ~NULL FTW~
                }
            }
        }
        
        var = (var == "NULL") ? null : var // NULL keyword ;D
        var = (var == "'") ? " " : var // ' pseudo-variable 
    
        return var // else just send back the string that was passed to be resolved (String type :p)
    }
    // TODO: Maybe->add if and for keywords (instead of {[ i : 0 .. 5 ] ... } for[ i : 0 .. 5]{ ... }, instead of {[ _GET(thing) == _CONFIG(thing) ] ... } if[ _ GET(thing) == _CONFIG(thing) ] { ... }
    parseChunk : func (chunk : String) -> String
    {
        ret := chunk
        openLoop := chunk find("{",0)//get the opening block symbol index
        closeLoop : SSizeT = -1
        closeLoops := chunk findAll("}")
        // this is basically for nested blocks ;)
        if(openLoop != -1 && chunk findAll("{") size == closeLoops size)
        {
            for(i in 0 .. closeLoops size)// we iterate the closing block symbols
            {
                test := chunk substring(openLoop+1,closeLoops get(i))//we make a substring out of the opening block - closing block
                if(test findAll("{") size == test findAll("}") size)// if there is the same number of opening and closing blocks in this substring
                {
                    closeLoop = closeLoops get(i)// this means we have a valid block 
                    break// break the loop :)
                }
            }

        }
        
        
        if(openLoop != -1 && closeLoop != -1 && chunk[openLoop+1] == '[') // if we DO have a block
        {
            insides := chunk substring(openLoop+2,chunk find("]",openLoop+1))//get the loop declaration
            insides = insides replaceAll(" ","")// Remove spaces ;)
            insides = insides replaceAll("\n","")//And remove newlines =)
        
            toReplace := insides substring(0,insides find(":",0))
            part2 := insides substring(insides find(":",0)+1)
            if(toReplace != insides && part2 != null)
            {
                begin := parseChunk(chunk substring(0,openLoop))
                start := resolveVariable(part2 substring(0,part2 find("..",0)))
                end := resolveVariable(part2 substring(part2 find("..",0)+2))
        
                loopReturn : String
            
                index := start toInt()//get int values...
                endIndex := end toInt()//...to loop in
                while(index != endIndex)//...ooc loop ^^
                {
                    countVars[toReplace] = ("%d" format(index))// create the loop variable 
                    moreData := parseChunk(chunk substring(chunk find("]",openLoop+1)+1,closeLoop))// parse the insides of the loop
                    
                    countVars remove(toReplace)// remove the loop variable :) 
                    if(moreData != null)
                    {
                        loopReturn = (loopReturn == null) ? moreData : loopReturn+moreData
                    }
                    index = (index < endIndex) ? index+1 : index-1
                }
                close := parseChunk(chunk substring(closeLoop+1))
                ret = (begin != null) ? begin : null
                ret = (loopReturn != null) ? ((ret != null) ? ret + loopReturn : loopReturn) : ret
                ret = (close != null) ? ((ret != null) ? ret + close : close) : ret
                return ret
            }
            else // maybe its a condition D:
            {
                // TODO : CHANGE THIS, TOO MUCH REPETITION
                insides := chunk substring(openLoop+2,chunk find("]",openLoop+1))//get the loop declaration
                insides = insides replaceAll(" ","")// Remove spaces ;)
                insides = insides replaceAll("\n","")//And remove newlines =)
                if(insides findAll("==") size == 1)
                {
                    if(resolveVariable(insides substring(0,insides find("==",0))) == resolveVariable(insides substring(insides find("==",0)+2)))
                    {
                        // execute block! :) 
                        begin := parseChunk(chunk substring(0,openLoop))
                        close := parseChunk(chunk substring(closeLoop+1))
                        loopReturn := parseChunk(chunk substring(chunk find("]",openLoop+1)+1,closeLoop))// parse the insides of the block
                        ret = (begin != null) ? begin : null
                        ret = (loopReturn != null) ? ((ret != null) ? ret + loopReturn : loopReturn) : ret
                        ret = (close != null) ? ((ret != null) ? ret + close : close) : ret
                        return ret
                    }
                    else
                    {
                        begin := parseChunk(chunk substring(0,openLoop))
                        close := parseChunk(chunk substring(closeLoop+1))
                        ret = (begin != null) ? begin : null
                        ret = (close != null) ? ((ret != null) ? ret + close : close) : ret
                        return ret
                    }
                }
                else if(insides findAll("!=") size == 1)
                {
                    if(resolveVariable(insides substring(0,insides find("!=",0))) != resolveVariable(insides substring(insides find("!=",0)+2)))
                    {
                        // execute block! :) 
                        begin := parseChunk(chunk substring(0,openLoop))
                        close := parseChunk(chunk substring(closeLoop+1))
                        loopReturn := parseChunk(chunk substring(chunk find("]",openLoop+1)+1,closeLoop))// parse the insides of the block
                        ret = (begin != null) ? begin : null
                        ret = (loopReturn != null) ? ((ret != null) ? ret + loopReturn : loopReturn) : ret
                        ret = (close != null) ? ((ret != null) ? ret + close : close) : ret
                        return ret
                    }
                    else
                    {
                        begin := parseChunk(chunk substring(0,openLoop))
                        close := parseChunk(chunk substring(closeLoop+1))
                        ret = (begin != null) ? begin : null
                        ret = ((close != null) ? ((ret != null) ? ret + close : close) : ret)
                        return ret
                    }
                }
            }
        }
    
        opens := chunk findAll("<%")
        closes := chunk findAll("%>")
        if(opens size == closes size && opens != 0)
        {
            for(j in 0 .. opens size)
            {
                data := chunk substring(opens get(j)+2,closes get(j))
                result : String
                inFuncName := true
                inFuncArgs := false
                funcName : String
                funcArgs := ArrayList<String> new()
                temp : String
                
                for(i in 0 .. data size)
                {
                    if(data[i] == ':' && inFuncName)
                    {
                        inFuncName = false
                        inFuncArgs = true
                        funcName = temp
                        temp = ""
                    }
                    else if(data[i] == ',' && inFuncArgs)
                    {
                        funcArgs add(temp)
                        temp = ""
                    }
                    else if((data[i] == '\n' || i == data size-1 || data[i] == ';') && inFuncArgs)
                    {
                        temp = (i == data size - 1 && data[i] != '\n' && data[i] != '\r' && data[i] != ' ') ? temp+data[i] : temp
                        funcArgs add(temp)
                        temp = ""
                        inFuncArgs = false
                        inFuncName = true
            
                        for(k in 0 .. functions size)
                        {
                            if(functions get(k) name == funcName)
                            {
                                returned := functions get(k) callback(funcArgs,this)// execute function
                                if(returned != null)
                                {
                                    result = (result == null) ? returned : result+returned // add callback return to return string
                                }
                                break
                            }
                        }
                        funcName = ""
                        funcArgs clear()
                    }
                    else if(data[i] != '\r' && data[i] != '\n' && data[i] != ' ' && data[i] != '\t' && data[i] != ';')
                    {
                        temp = (temp == null || temp == "") ? data[i] as String : temp + data[i] as String
                    }
                }
                //TODO: CHANGE THIS TO A BETTER METHOD, NOT TO OVERRIDE SIMILAR PASSAGES :/ 
                ret = (result != null) ? ret replaceAll("<%"+data+"%>",result) : ret replaceAll("<%"+data+"%>","")
            }
        }
        ret
    }
}
