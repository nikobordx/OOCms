use oocsv
use oocgi
import oocsv
import oocgi
import structs/MultiMap
import io/FileReader
import structs/ArrayList
import addressParser

TemplateLoader : class // class that takes care of loading the template's database and then generating the template itself
{
    db : Database
    status : String = "200"
    contents : String
    base : String
    
    columnArrays := MultiMap<String,Column> new()
    countArrays := MultiMap<String,String> new()
    
    init : func()
    {
    }
    
    load : func(ap : AddressParser)
    {
        file := "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.thtml" : ap getParams get("subpage")+".thtml") // path of template html file to parse
        dbFile := "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.db" : ap getParams get("subpage")+".db") // path of database specification file to parse
        getDesign()
        parseDb(dbFile)// parse db file
        parseFile(file)// and thtml file =D
    }
    getDesign : func ()
    {
        base = ""
        freader := FileReader new("design/page.html")
        while(freader hasNext?())
        {
            base = (base == null) ? freader read() as String : base + freader read() as String
        }
    }
    parseDb : func (file : String) // parses .db file to import column and stuff :p
    {
        freader := FileReader new(file)
        data : String
        while(freader hasNext?())
        {
            data = (data == null) ? freader read() as String : data + freader read() as String
        }
        freader close()
    
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
                        db = Database new("databases/"+funcArgs get(0)+".csv")
                        if(funcArgs size > 1)
                        {
                            if(funcArgs get(1) startsWith?("DESCORDER"))
                            {
                                temp = funcArgs get(1) substring(10,funcArgs get(1) size-1) // and here we have our column name ;D
                                db sortDescending(temp)
                            }
                            else if(funcArgs get(1) startsWith?("ASCORDER"))
                            {
                                temp = funcArgs get(1) substring(9,funcArgs get(1) size-1)
                                db sortAscending(temp)
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
                            columnArrays[funcArgs get(0)] = db selectColumn(funcArgs get(1))
                        }
                    }
                }
                else if(funcName == "Count")
                {
                    if(funcArgs size > 0)
                    {
                        if(db columns != null)
                        {
                            countArrays[funcArgs get(0)] = ("%d" format(db columns get(0) fields size))
                        }
                    }
                }
                funcName = ""
                funcArgs clear()
            }
            else if(data[i] != '\r' && data[i] != '\n' && data[i] != ' ' && data[i] != null)
            {
                temp = (temp == null || temp == "") ? data[i] as String : temp + data[i] as String
            }
        }
    }
    
    parseFile : func (file : String)
    {
        freader := FileReader new(file)
        data : String
        while(freader hasNext?())
        {
            data = (data == null) ? freader read() as String : data + freader read() as String
        }
        freader close()
        // Method : Lookup for ~| ... |~ loops
        // In those loops, change the [...] into data
        // Outside these, find [...] and if they contain ARRAY[INT] types, replace data, else leave them be
        opens := data findAll("~|")
        closes := data findAll("|~")
        newData : String
        if(opens size == closes size) // if all loops are opened and closed
        {
            newData = parseChunk(data substring(0,opens get(0)),null,null)
            
            for(i in 0 .. opens size)
            {
                toParse := data substring(opens get(i)+2,closes get(i)) // get loop contents
                if(i-1 >= 0)
                {
                    newData += parseChunk(data substring(closes get(i-1),opens get(i)),null,null) // parse text between two loops
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
                    startIndex = countArrays get(start) toInt()
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
                    endIndex = countArrays get(end) toInt()
                }
                else
                {
                    endIndex = end toInt()
                }
                
                index := startIndex
                while(index != endIndex)
                {
                    moreData := parseChunk(toParse,toReplace,("%d" format(index)))
                    if(moreData != null)// parse the code chunk
                    {
                        newData += moreData
                    }
                    index = (index < endIndex) ? index+1 : index-1
                }
            }
            newData += parseChunk(data substring(closes get(closes size-1)+2),null,null)
        }
        else
        {
            newData = data
        }
        contents = base replaceAll("__[]__",newData)
    }
    
    parseChunk : func (chunk : String, toReplace,with : String = null) -> String
    {
        ret := chunk
        opens := chunk findAll("[")
        closes := chunk findAll("]")
        if(opens size == closes size)
        {
            for(i in 0 .. opens size)
            {
                littleReplace := chunk substring(opens get(i)+1,closes get(i))// get the string between brackets
                openParen := littleReplace find("(",0)// get index where parenthesis is opened
                closeParen := littleReplace find(")",0)// same with closed :)
                // get index number between parenthesis
                indexReplace := littleReplace substring(openParen+1,closeParen)
                if(indexReplace != littleReplace) // if we have an array expression
                {
                    if(toReplace != null && with != null)
                    {
                        indexReplace = indexReplace replaceAll(toReplace,with)// replace loop variable with number
                    }
                    index := indexReplace toInt()// get line index
                    colName := littleReplace substring(0,openParen)// get var name before parenthesis
                    col := columnArrays get(colName)// get column that is linked to that var name
                    if(col fields size > index)// overflow protection (you should be able to do 0->5 in template while there are only 1..4 items) ;D
                    {
                        value := col fields get(index) // and finally get the string we want :)
                        ret = ret replaceAll("["+littleReplace+"]",value data)//write our data
                    }
                    else
                    {
                        return null
                    }
                }
                else// check to see if there is a count variable named like littleReplace
                {
                    for(i in 0 .. countArrays size)
                    {
                        key := countArrays getKeys() get(i)
                        println(key)
                        if(key == littleReplace)// found a count variable named like that =D
                        {
                            value := countArrays get(key)
                            ret = ret replaceAll("["+littleReplace+"]",value)
                            break
                        }
                    }
                }
            }
        }
        ret
    }
}
