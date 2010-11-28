import structs/ArrayList
import text/StringTokenizer
import templateLoader

//Still problems with split, fix them :/

Token : class
{
    value : String
    type : String // change this to an enum or something, dont know how to do that yet :/
    init : func ~withtype(=value,=type)
    init : func ~withouttype(=value)
}

Tokenizer : class
{
    parse : static func(str : String) -> ArrayList<Token>
    {
        tokens := ArrayList<Token> new()
        opens := str findAll("<%")
        closes := str findAll("%>")
        if(opens size == closes size && opens size > 0)
        {
            tokens add(Token new(str substring(0,opens get(0)),"HTML")) // first html token
            for(i in 0 .. opens size)
            {
                if(i > 0) 
                {
                    tokens add(Token new(str substring(closes get(i-1)+2,opens get(i)),"HTML")) // add the HTML token between two thtml blocks
                }
        
                string := str substring(opens get(i)+2,closes get(i))
                splitBuff := ArrayList<String> new()
                splitBuff add(string)
                splitBuff = split(splitBuff,' ')
                splitBuff = split(splitBuff,'{')
                splitBuff = split(splitBuff,'}')
                splitBuff = split(splitBuff,'[')
                splitBuff = split(splitBuff,']')
                splitBuff = split(splitBuff,';')
                splitBuff = split(splitBuff,':')
                splitBuff = split(splitBuff,'\n')
                splitBuff = split(splitBuff,'\r')
                splitBuff = split(splitBuff,',')
                splitBuff = split(splitBuff,'"')
                // Split the string into basic token strings...
        
                for(i in 0 .. splitBuff size)
                {
                    tokens add(Token new(splitBuff get(i)))// turn string into tokens :) 
                }
                
                // edit the tokens
                for(i in 0 .. tokens size)
                {
                    if(tokens get(i) value == ":")
                    {
                        indx := getLeftToken(tokens,i)
                        if(indx != -1)
                        {
                            tokens get(indx) type = "function"
                        }
                    }
                    else if(tokens get(i) value == "[")
                    {
                        if(findLeftToken(tokens,i,"if") != -1)
                        {
                            mergeTokens(tokens,i,findRightToken(tokens,i,"]"))
                            tokens get(i) type = "condition"
                        }
                        else if(findLeftToken(tokens,i,"for") != -1)
                        {
                            mergeTokens(tokens,i,findRightToken(tokens,i,"]"))
                            tokens get(i) type = "loop"
                        }
                    }
                    else if(tokens get(i) value == "\"")
                    {
                        if(findRightToken(tokens,i,"\"") != -1)
                        {
                            mergeTokens(tokens,i,findRightToken(tokens,i,"\""))
                            tokens get(i) type = "string"
                        }
                    }
                    else if(tokens get(i) value == ";" || tokens get(i) value == "\n" || tokens get(i) value == "\r")
                    {
                        if(tokens get(getLeftToken(tokens,i)) type == null)
                        {
                            tokens get(getLeftToken(tokens,i)) type = "argument"
                        }
                    }
                    else if(tokens get(i) value == ",")
                    {
                        if(tokens get(getLeftToken(tokens,i)) type == null)
                        {
                            tokens get(getLeftToken(tokens,i)) type = "argument"
                        }
                        if(tokens get(getRightToken(tokens,i)) type == null)
                        {
                            tokens get(getRightToken(tokens,i)) type = "argument"
                        }
                    }
                }
            }
            tokens add(Token new(str substring(closes last()+2),"HTML")) // last html token :p
        }
        tokens
    }
    
    mergeTokens : static func(tokens: ArrayList<Token>, startIndex, endIndex : Int) -> ArrayList<Token> // merges tokens 
    {
        value := ""
        for(i in startIndex .. endIndex+1)
        {
            value += tokens get(i) value
        }
        tokens = deleteTokens(tokens,startIndex,endIndex)
        token := Token new(value)
        tokens add(startIndex,token)
        tokens
    }
    
    deleteTokens : static func(tokens : ArrayList<Token>, startIndex, endIndex : Int) -> ArrayList<Token> // deletes tokens x)
    {
        nods := endIndex+1-startIndex
        for(i in 0 .. nods)
        {
            tokens removeAt(startIndex)
        }
        tokens
    }
    
    findRightToken : static func(tokens : ArrayList<Token>, currentIndex : Int, value : String) -> Int
    {
        for(i in currentIndex+1 .. tokens size)
        {
            if(tokens get(i) value == value)
            {
                return i
            }
        }
        -1
    }
    
    findLeftToken : static func(tokens : ArrayList<Token>, currentIndex : Int, value : String) -> Int
    {
        while(currentIndex > 0)
        {
            currentIndex -= 1
            if(tokens get(currentIndex) value == value)
            {
                return currentIndex
            }
        }
        -1
    }
    
    getLeftToken : static func(tokens : ArrayList<Token>, currentIndex : Int) -> Int // Returns the index of the first token to the left that is not whitespace or newline
    {
        while(currentIndex > 0)
        {
            currentIndex -= 1
            if(tokens get(currentIndex) value != " " && tokens get(currentIndex) value != "\n" && tokens get(currentIndex) value != "\r")
            {
                return currentIndex
            }
        }
        -1
    }
    
    getRightToken : static func(tokens : ArrayList<Token>, currentIndex : Int) -> Int
    {
        for(i in currentIndex+1 .. tokens size)
        {
            if(tokens get(i) value != " " && tokens get(i) value != "\n" && tokens get(i) value != "\r")
            {
                return i
            }
        }
        -1
    }
    
    split : static func(strs : ArrayList<String>, delim : Char) -> ArrayList<String>// NEEDS SOME MORE FIXES :/
    {
        ret := ArrayList<String> new()
        for(i in 0 .. strs size)
        {
            temp := strs get(i) split(delim,true)
            if(temp size > 0)
            {
                for(j in 0 .. temp size)
                {
                    if(temp get(j) == "")
                    {
                        ret add(delim as String)
                    }
                    else
                    {
                        ret add(temp get(j))
                        if(j < temp size-1) { if(temp get(j+1) != "") {ret add(delim as String) } }
                    }
                }
            }
            else
            {
                ret add(strs get(i))
            }
        }
        ret
    }
    
    execute : static func(nTokens : ArrayList<Token>, tl : TemplateLoader) -> String // -> add a templateLoader argument here
    {
        tokens := nTokens clone()
        // FIX SPLIT, ADD " MANAGEMENT TO RESOLVE_VARIABLE AND WERE READY TO GO =D
        // Maybe add up a saveToFile and a loadFromFile method, to be able to kinda cache the tokens into files, for quicker execution
        // This would be done by using a syntax like [tokenValue:tokenType], thus getting series like [<html>:HTML][ ][if][[1==1]:condition][{][ ][Show:function][:][ ]["Hello world!":string][}][ ][</html>:HTML]
        // Just let that for later :p 
    
        for(i in 0 .. tokens size)
        {
            if(tokens get(i) type == "function")
            {
                indx := getRightToken(tokens,i)
                if(indx != -1)
                {
                    if(tokens get(indx) value == ":")
                    {
                        indx1 := findRightToken(tokens,indx,";")
                        indx2 := findRightToken(tokens,indx,"\n")
                        ind := tokens size
                        if(indx1 != -1 && indx2 != -1)
                        {
                            ind = (indx1 < indx2) ? indx1 : indx2
                        }
                        else if(indx1 != -1)
                        {
                            ind = indx1
                        }
                        else if(indx2 != -1)
                        {
                            ind = indx2
                        }

                        funcArgs := ArrayList<String> new()
                        for(j in indx+1 .. ind)
                        {
                            if(tokens get(j) type == "argument" || tokens get(j) type == "string")
                            {
                                funcArgs add(tokens get(j) value)
                            }
                        }
                        ret := tl executeFunction(tokens get(i) value,funcArgs) // execute function :)
                        tokens = deleteTokens(tokens,i,ind)
                        
                        tokens add(i,Token new(ret,"HTML"))
                    }
                    else
                    {
                        return "Error: expected ':' after a function token"
                    }
                }
                else
                {
                    return "Error: expected ':' after a function token"
                }
            }
            else if(tokens get(i) value == "if") // verify this with nested blocks, i think there are some problems, maybe related to split
            {
                cond := getRightToken(tokens,i)
                if(tokens get(cond) type == "condition")
                {
                    openIndx := getRightToken(tokens,cond)
                    if(tokens get(openIndx) value == "{")
                    {
                        closeIndx := findNested(tokens,openIndx,"{","}")
                        if(closeIndx != -1)
                        {
                            ret := ""
                            if(tl parseCondition(tokens get(cond) value))
                            {
                                ret = execute(tokens slice(openIndx+1 .. closeIndx-1),tl)
                            }
                            tokens = deleteTokens(tokens,i,closeIndx)
                            tokens add(i,Token new(ret,"HTML"))
                        }
                        else
                        {
                            return "Error: block not closed. (Did you forget '}' ?)"
                        }
                    }
                    else
                    {
                        return "Error: expected a block after if keyword. (Did you forget '{' ?)"
                    }
                }
                else
                {
                    return "Error: expected a condition after if keyword. (Did you forget '[' or ']' ?)"
                }
            }
            else if(tokens get(i) value == "for")
            {
                loop := getRightToken(tokens,i)
                if(tokens get(loop) type == "loop")
                {
                    openIndx := getRightToken(tokens,loop)
                    if(tokens get(openIndx) value == "{")
                    {
                        closeIndx := findNested(tokens,openIndx,"{","}")
                        if(closeIndx != -1)
                        {
                            ret := tl loop(tokens get(loop) value,tokens slice(openIndx+1 .. closeIndx-1)) // -> call the templateLoader loop function, loops and executes :)
                            tokens = deleteTokens(tokens,i,closeIndx)
                            tokens add(i,Token new(ret,"HTML"))
                        }
                        else
                        {
                            return "Error: block not closed. (Did you forget '}' ?)"
                        }
                    }
                    else
                    {
                        return "Error: expected a block after for keyword. (Did you forget '{' ?)"
                    }
                }
                else
                {
                    return "Error: expected a loop after for keyword. (Did you forget '[' or ']' ?)"
                }
            }
        }
        // Final phase, just merge everything =)
        tokens = mergeTokens(tokens,0,tokens size-1)
        tokens first() value
    }
    
    findNested : static func(tokens : ArrayList<Token>, openIndex : Int , openSign,closeSign : String) -> Int
    {
        if(tokens get(openIndex) value != openSign)
        {
            return -1
        }
        else
        {
            opens := 1
            closes := 0
            for(i in openIndex+1 .. tokens size - 1)
            {
                if(tokens get(i) value == openSign)
                {
                    opens += 1
                }
                else if(tokens get(i) value == closeSign)
                {
                    closes += 1
                }
                
                if(opens == closes)
                {
                    return i
                }
            }
        }
        -1
    }
}

