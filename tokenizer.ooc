import structs/ArrayList
import io/File
import text/StringTokenizer
import templateLoader

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
        
        
                //CHANGE BASIC TOKENIZATION ALGORITHM
                // do something like
                // characters := ArrayList<Char> new() .add(' ') .add('{') .add('}') .add('[') etc..
                // Then go through string
                // Each time we "hit" one of these characters, split into a new token :) 
                // Much quicker and more effective ;D
        
                symbols := ArrayList<Char> new() .add(' ') .add('{') .add('}') .add('[') .add(']') .add(';') .add(':') .add('\n') .add('\r') .add('\t') .add(',') .add('"') .add('(') .add(')')
        
                temp := ""
                for(character in string)
                {
                    if(symbols indexOf(character) != -1)
                    {
                        tokens add(Token new(temp))
                        tokens add(Token new(character as String))
                        temp = ""
                    }
                    else
                    {
                        temp += character
                    }
                }
                tokens add(Token new(temp))
                
                
                // edit the tokens
                for(i in 0 .. tokens size)
                {
                    if(tokens get(i) value == ":")
                    {
                        indx := getLeftToken(tokens,i)
                        if(indx != -1)
                        {
                            tokens get(indx) type = "function"
                            indx2 := getRightToken(tokens,i)
                            if(indx2 != -1)
                            {
                                tokens get(indx2) type = (tokens get(indx2) type == null ) ? "argument" : tokens get(indx2) type
                            }
                        }
                    }
                    else if(tokens get(i) value == "[")
                    {
                        if(getLeftToken(tokens,i) != -1)
                        {
                            left := getLeftToken(tokens,i)
                            mergeTokens(tokens,i,findRightToken(tokens,i,"]"))
                            if(tokens get(left) value == "if")
                            {
                                tokens get(i) type = "condition"
                            }
                            else if(tokens get(left) value == "for")
                            {
                                
                                tokens get(i) type = "loop"
                            }
                            else if(tokens get(left) value == "def")
                            {
                                tokens get(i) type = "funcDecl"
                            }
                        }
                    }
                    else if(tokens get(i) value == "\"")
                    {
                        a := i
                        while(findRightToken(tokens,a,"\"") != -1)
                        {
                            ind := findRightToken(tokens,a,"\"")
                            if(tokens get(ind-1) value endsWith?("\\"))
                            {
                                tokens get(ind-1) value = tokens get(ind-1) value trimRight('\\')
                                a = ind
                            }
                            else
                            {
                                mergeTokens(tokens,i,ind)
                                tokens get(i) type = "string"
                                break
                            }
                        }
                    }
                    else if(tokens get(i) value == "(")
                    {
                        if(getLeftToken(tokens,i) != -1)
                        {
                            mergeTokens(tokens,getLeftToken(tokens,i),findNested(tokens,i,"(",")")+1)
                            tokens get(getLeftToken(tokens,i)) type = "argument"
                        }
                    }
                    else if(tokens get(i) value == ";")
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
        else
        {
            tokens add(Token new(str,"HTML"))
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
            if(tokens get(currentIndex) value != "\t" && tokens get(currentIndex) value != " " && tokens get(currentIndex) value != "\n" && tokens get(currentIndex) value != "\r" && tokens get(currentIndex) value != "")
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
            if(tokens get(i) value != "\t" && tokens get(i) value != " " && tokens get(i) value != "\n" && tokens get(i) value != "\r" && tokens get(i) value != "")
            {
                return i
            }
        }
        -1
    }
    
    execute : static func(nTokens : ArrayList<Token>, tl : TemplateLoader) -> String
    {
        tokens := nTokens clone()
    
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
                        return "Error: expected ':' after a function token ( found " + tokens get(indx) value + " )"
                    }
                }
                else
                {
                    return "Error: expected ':' after a function token ( function followed by nothing? oO Have you been changing .tokens files lately? xD )"
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
                        return "Error: expected a block after if keyword. Found " + tokens get(openIndx) value + " in the place of '{'"
                    }
                }
                else
                {
                    return "Error: expected a condition after if keyword. (Did you forget '[' or ']' ?) , ( Found " + tokens get(cond) value + " at the place of a condition )"
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
                        return "Error: expected a block after for keyword. Found " + tokens get(openIndx) value + " in the place of '{'"
                    }
                }
                else
                {
                    return "Error: expected a loop after for keyword. (Did you forget '[' or ']' ?) , ( Found " + tokens get(loop) value + " at the place of a loop )"
                }
            }
            else if(tokens get(i) value == "def")
            {
                decl := getRightToken(tokens,i)
                if(tokens get(decl) type == "funcDecl")
                {
                    openIndx := getRightToken(tokens,decl)
                    if(tokens get(openIndx) value == "{")
                    {
                        closeIndx := findNested(tokens,openIndx,"{","}")
                        if(closeIndx != -1)
                        {
                            tl makeFunction(tokens get(decl) value, tokens slice(openIndx+1 .. closeIndx-1))
                            tokens = deleteTokens(tokens,i,closeIndx)
                        }
                        else
                        {
                            return "Error: block not closed. (Did you forget '}' ?)"
                        }
                    }
                    else
                    {
                        return "Error: expected a block after for keyword. Found " + tokens get(openIndx) value + " in the place of '{'"
                    }
                }
                else
                {
                    return "Error: expected a function declaration after for keyword. (Did you forget '[' or ']' ?) , ( Found " + tokens get(decl) value + " at the place of a function declaration )"
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
    
    saveToFile : static func (tokens : ArrayList<Token>, fileName : String)
    {
        fsave := File new(fileName)
        toWrite := ""
        
        for(token in tokens)
        {
            toWrite += "¤"+token value+((token type != null) ? "ͳ"+token type : "")+"¤"
        }
        
        fsave write(toWrite)
    }
    
    readFromFile : static func (fileName : String) -> ArrayList<Token>
    {
        tokens := ArrayList<Token> new()
        
        file := File new(fileName)
        if(file file?())
        {
            data := file read()
            parts := data split("¤")
            for(part in parts)
            {
                if(part findAll("ͳ") size > 0)
                {
                    value := part substring(0,part find("ͳ",0))
                    type := part substring(part find("ͳ",0)+2) // I dont know why, but i need to do +2 instead of +1 for ͳ character, must have something to do with unicode :p
                    tokens add(Token new(value,type))
                }
                else
                {
                    tokens add(Token new(part))
                }
            }
        }
        tokens
    }
}

