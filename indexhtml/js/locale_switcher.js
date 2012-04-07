var temp = window.navigator.language.split("-")
var lang = temp[0];
var locale = temp.join("_");
var path_chunks = window.location.toString().split("/");
var docname = path_chunks.pop();
var active_locale = path_chunks.pop();
var prefix = "";
if (supported[active_locale])
{
    prefix = "../";
}
lang = lang.split("_")[0];
if (! window.location.toString().match(lang + "/" + docname + "$") && prefix == "")
{
    if (supported[locale])
    {
	window.location = prefix + locale + "/" + docname;
    }
    else if (supported[lang])
    {
        window.location = prefix + lang + "/" + docname;    
    }
}
