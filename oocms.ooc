use oocsv
use oocgi
import oocsv
import oocgi
import structs/MultiMap
import io/FileReader

TemplateLoader : class // class that takes care of loading the template's database and then generating the template itself
{
    db : Database
    status : String = "200"
    contents : String
    
    columnArrays := MultiMap<String,Column> new()
    countArrays := MultiMap<String,String> new()
    
    init : func()
    {
    }
    
    load : func(ap : AddressParser)
    {
        file := "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.thtml" : ap getParams get("subpage")+".thtml") // path of template html file to parse
        dbFile := "templates/"+ap template+"/"+((ap getParams get("subpage") == null) ? "index.db" : ap getParams get("subpage")+".db") // path of database specification file to parse
        parseDb(dbFile)// parse db file
        parseFile(file)// and thtml file =D
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
    
        tmpColumn : String
        temp : String
        inDatabase := false
        inOrder := false
        inColumn := false
        inDbColumn := false
        inCount := false
        for(i in 0 .. data size)
        {
            if(temp == "Database:" && data[i] == ' ' && !inDatabase && !inOrder && !inColumn && !inDbColumn && !inCount) // database keyword
            {
                inDatabase = true
                temp = ""
            }
            else if((data[i] == ',' || data[i] == '\n' || data[i] == '\r' || i == data size-1) && inDatabase) // database keyword implementation :P
            {
                inDatabase = false
                inOrder = (data[i] == ',')
                db = Database new("databases/"+temp+".csv")
                temp = ""
            }
            else if((data[i] == '\n' || data[i] == '\r' || i == data size-1) && inOrder) // database ordering implementation
            {
                if(temp startsWith?("DESCORDER"))
                {
                    temp = temp substring(10,temp size-1) // and here we have our column name ;D
                    db sortDescending(temp)
                }
                else if(temp startsWith?("ASCORDER"))
                {
                    temp = temp substring(9,temp size-1)
                    db sortAscending(temp)
                }
                inOrder = false
                temp = ""
            }
            else if(temp == "Column:" && data[i] == ' ' && !inDatabase && !inOrder && !inColumn && !inDbColumn && !inCount) // column keyword
            {
                inColumn = true
                temp = ""
            }
            else if(data[i] == ',' && inColumn)
            {
                inColumn = false
                inDbColumn = true
                tmpColumn = temp
                temp = ""
            }
            else if((data[i] == '\r' || data[i] == '\n' || i == data size-1) && inDbColumn)
            {
                inDbColumn = false
                columnArrays[tmpColumn] = db selectColumn(temp)
                temp = ""
                tmpColumn = ""
            }
            else if(temp == "Count:" && data[i] == ' ' && !inDatabase && !inOrder && !inColumn && !inDbColumn && !inCount) //count keyword
            {
                inCount = true
                temp = ""
            }
            else if((data[i] == '\r' || data[i] == '\n' || i == data size-1) && inCount)
            {
                inCount = false
                countArrays[temp] = ("%d" format(db columns get(0) fields size))
                temp = ""
            }
            else if(data[i] != '\r' && data[i] != '\n' && data[i] != null)
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
        contents = newData
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

AddressParser : class // class that parses the query passed to CGI object and stores the name of the template to open and the variables to pass to it
{
    template : String
    getParams := MultiMap<String,String> new()
    postParams := MultiMap<String,String> new()
    init : func ()
    {
    }
    parse : func (cgi : CGI)
    {
        if(cgi getArray get("page") == null || cgi getArray get("page") == "index")
        {
            template = "IndexTemplate"
        }
        else
        {
            template = cgi getArray get("page")
        }
        
        for(i in 0 .. cgi getArray size)
        {
            key := cgi getArray getKeys() get(i)
            if(key != "page")
            {
                val := cgi getArray getAll(key)
                getParams[key] = val
            }
        }
        postParams = cgi postArray
    }
}

main : func -> Int
{
    cgi := CGI new()
    ap := AddressParser new()
    tl := TemplateLoader new()
    
    ap parse(cgi)
    tl load(ap)
    cgi setBody(tl contents)
    cgi setHeader("Status",tl status)
    
    cgi setHeader("Content-type","text/html")
    
    cgi forgeResponse()
    cgi response print()
    0
}