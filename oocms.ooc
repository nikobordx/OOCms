use oocsv
use oocgi
import oocsv
import oocgi
import templateLoader
import addressParser

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