use oocgi
import oocgi
import structs/MultiMap

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
            val := cgi getArray getAll(key)
            getParams[key] = val
        }
        postParams = cgi postArray
    }
}