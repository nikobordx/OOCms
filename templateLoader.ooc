use oocsv
use oocgi
import oocsv
import oocgi
import structs/MultiMap
import io/File
import structs/ArrayList
import addressParser

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
    
    init : func()
    {
    }
    
    load : func(ap : AddressParser)
    {
        file := "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.thtml" : ap getParams get("subpage")+".thtml") // path of template html file to parse
        dbFile := "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.db" : ap getParams get("subpage")+".db") // path of database specification file to parse
    
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
    
        getDesign()
        parseDb(dbFile)// parse db file
        parseFile(file)// and thtml file =D
        
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
    parseDb : func (file : String) // parses .db file to import column and stuff :p
    {
        freader := File new(file)
        if(freader exists?())
        {
            data := freader read()
        
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
                else if((data[i] == '\n' || i == data size-1) && inFuncArgs)
                {
                    funcArgs add(temp)
                    temp = ""
                    inFuncArgs = false
                    inFuncName = true
                    if(funcName == "Database")
                    {
                        if(funcArgs size > 0)
                        {
                            db = Database new("databases/"+resolveVariable(funcArgs get(0))+".csv")
                            if(funcArgs size > 1)
                            {
                                if(funcArgs get(1) startsWith?("DESCORDER"))
                                {
                                    temp = funcArgs get(1) substring(10,funcArgs get(1) size-1) // and here we have our column name ;D
                                    db sortDescending(resolveVariable(temp))
                                }
                                else if(funcArgs get(1) startsWith?("ASCORDER"))
                                {
                                    temp = funcArgs get(1) substring(9,funcArgs get(1) size-1)
                                    db sortAscending(resolveVariable(temp))
                                }
                            }
                            temp = ""
                        }
                    }
                    else if(funcName == "Column")
                    {
                        if(funcArgs size > 1)
                        {
                            if(db selectColumn(funcArgs get(1)) != null)
                            {
                                tempArray := ArrayList<String> new()
                                for(j in 0 .. db selectColumn(resolveVariable(funcArgs get(1))) fields size)
                                {
                                    tempArray add(db selectColumn(resolveVariable(funcArgs get(1))) fields get(j) data)
                                }
                                tempContainer := StrListContainer new()
                                tempContainer array = tempArray
                                arrays[funcArgs get(0)] = tempContainer
                            }
                        }
                    }
                    else if(funcName == "Count")
                    {
                        if(funcArgs size > 0)
                        {
                            if(db columns != null)
                            {
                                countVars[funcArgs get(0)] = ("%d" format(db columns get(0) fields size))
                            }
                        }
                    }
                    else if(funcName == "Line")
                    {
                        if(funcArgs size > 2)
                        {
                            fields := db selectLine(resolveVariable(funcArgs get(0)),resolveVariable(funcArgs get(1)))
                            if(fields != null && fields size > 0)
                            {
                                if(fields size == db columns size)
                                {
                                    tempMap := StrStrMapContainer new()
                                    for(i in 0 .. fields size)
                                    {
                                        tempMap map[db columns get(i) name] = fields get(i) data
                                    }
                                    maps[funcArgs get(2)] = tempMap
                                }
                            }
                        }
                    }
                    funcName = ""
                    funcArgs clear()
                }
                else if(data[i] != '\r' && data[i] != '\n' && data[i] != ' ')
                {
                    temp = (temp == null || temp == "") ? data[i] as String : temp + data[i] as String
                }
            }
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
            // Method : Lookup for ~| ... |~ loops
            // In those loops, change the [...] into data
            // Outside these, find [...] and if they contain ARRAY[INT] types, replace data, else leave them be
            opens := data findAll("~|")
            closes := data findAll("|~")
            newData : String
            if(opens size == closes size) // if all loops are opened and closed
            {
                newData = parseChunk(data substring(0,opens get(0)))
                
                for(i in 0 .. opens size)
                {
                    toParse := data substring(opens get(i)+2,closes get(i)) // get loop contents
                    if(i-1 >= 0)
                    {
                        newData += parseChunk(data substring(closes get(i-1)+2,opens get(i))) // parse text between two loops
                    }
                    // loop =D
                    times := toParse substring(toParse find("[",0)+1,toParse find("]",0)) // get first [...] chunk, should contain loop times
                    toParse = toParse substring(toParse find("]",0)+1) // remove this chunk from being parsed
                    toReplace := times substring(0,times find("->",0))// get the loop's "variable" name
                    loopCount := times substring(times find("->",0)+2)//get loopcount data
                    start := loopCount substring(0,loopCount find("->",0))
                    startIndex : Int
                    if(start toInt() == 0 && start != "0") // if this is not an Int value
                    {
                        //It SHOULD be a count variable
                        startIndex = resolveVariable(start) toInt()
                    }
                    else
                    {
                        startIndex = start toInt()
                    }
                    end := loopCount substring(loopCount find("->",0)+2)
                    endIndex : Int
                    if(end toInt() == 0 && end != "0") // if this is not an Int value
                    {
                        //It SHOULD be a count variable
                        endIndex = resolveVariable(end) toInt()
                    }
                    else
                    {
                        endIndex = end toInt()
                    }
                    
                    index := startIndex
                    while(index != endIndex)
                    {
                        countVars[toReplace] = ("%d" format(index))// create a temp variable for the loop variable 
                        moreData := parseChunk(toParse)
                        countVars remove(toReplace)
                        if(moreData != null)// parse the code chunk
                        {
                            newData += moreData
                        }
                        index = (index < endIndex) ? index+1 : index-1
                    }
                }
                newData += parseChunk(data substring(closes get(closes size-1)+2))
            }
            else
            {
                newData = data
            }
            contents = base replaceAll("__[]__",newData)
        }
        else
        {
            status = "404"
        }
    }
    
    resolveVariable : func (var : String) -> String // code that takes the name of a variable and returns its value
    {
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
            nIndex : String
            
            if(index toInt() == 0 && index != "0" && index != resolveVariable(index))
            {
                // variable in index :p 
                nIndex = resolveVariable(index)
            }
            else if(index toInt() != 0)
            {
                nIndex = index
            }
            // ok, now we have a number in there :p
            if(nIndex != null)
            {
                if((arrays get(varn) array size > nIndex toInt()))
                {
                    if(arrays get(varn) array get(nIndex toInt()) != null) // if we do have an array named like that and a field at that index
                    {
                        return arrays get(varn) array get(nIndex toInt())// send back value
                    }
                }
            }
            
            if(maps != null && maps get(varn) != null)
            {
                if(maps get(varn) map get(index) != null)// search into maps
                {
                    return maps get(varn) map get(index)
                }
                else
                {
                    if(maps get(varn) map get(resolveVariable(index)) != null)
                    {
                        return maps get(varn) map get(resolveVariable(index))
                    }
                }
            }
        }
        
        return var // else just send back the string that was passed to be resolved
    }
    
    parseChunk : func (chunk : String) -> String
    {
        ret := chunk
        opens := chunk findAll("__{")
        closes := chunk findAll("}__")
        if(opens size == closes size)
        {
            for(j in 0 .. opens size)
            {
                data := chunk substring(opens get(j)+3,closes get(j))
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
                    else if((data[i] == '\n' || i == data size-1) && inFuncArgs)
                    {
                        temp = (i == data size - 1 && data[i] != '\n' && data[i] != '\r' && data[i] != ' ') ? temp+data[i] : temp
                        funcArgs add(temp)
                        temp = ""
                        inFuncArgs = false
                        inFuncName = true
                        if(funcName == "Show")// Show function
                        {
                            if(funcArgs size > 0)// If we have our argument ;)
                            {
                                result = (result == null) ? resolveVariable(funcArgs get(0)) : result+resolveVariable(funcArgs get(0)) // add variable value to return string
                            }
                        }
                        else if(funcName == "ArrayPrint")// arrayPrint function
                        {
                            if(funcArgs size > 0)// we have our argument :)
                            {
                                if(arrays != null && arrays get(funcArgs get(0)) array != null)//if there is an array with that name
                                {
                                    //print awaaay!!!
                                    array := arrays get(funcArgs get(0)) array
                                    for(i in 0 .. array size)
                                    {
                                        result = (result == null) ? array get(i) + "<br/>" : result + array get(i) + "<br/>"
                                    }
                                }
                            }
                        }
                        funcName = ""
                        funcArgs clear()
                    }
                    else if(data[i] != '\r' && data[i] != '\n' && data[i] != ' ')
                    {
                        temp = (temp == null || temp == "") ? data[i] as String : temp + data[i] as String
                    }
                }
                ret = ret replaceAll("__{"+data+"}__",result)
            }
        }
        ret
    }
}
