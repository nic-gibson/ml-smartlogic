xquery version "1.0-ml";

(: Functions to handle results from Semaphore classification server :)

module namespace smr = "http://noslogan.org/components/semaphore/results";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace redact="http://noslogan.org/semaphore/redact";


declare variable $smr:fact-extraction-stylesheet := 'get-facts.xslt';
declare variable $smr:strip-keys-stylesheet := 'strip-keys.xslt';
declare variable $smr:merge-keys-stylesheet := 'merge-keys.xslt';
declare variable $smr:redaction-stylesheet := 'redact.xslt';

declare option xdmp:mapping "false";



(:~
 : Get the namespaces from the SmartLogic output. Namespaces are embedded in the
 : result content as normal attributes. It's simpler to rebuild the output if they
 : are in a map.
 : @param $doc - the SmartLogic output
 : @return - a map of prefix against URI
:)
declare function smr:extract-namespaces($results as document-node()) as map:map {

    map:new(($results//FIELD[starts-with(@NAME, '@xmlns')] !
        map:entry(substring-after(@NAME, ':'), string-join(.//text()[normalize-space()], ''))))

};


(:~
: Given the SmartLogic output, rebuild the facts listed in that doc (META elements
: into a more useful structure.
: Facts which are not used in output are filtered out.
: @param $doc - the SmartLogic output
: @return - the facts restructured into a map of maps
:)
declare function smr:extract-facts($doc as document-node()) as map:map {
    map:map(xdmp:xslt-invoke($smr:fact-extraction-stylesheet, $doc)/node())
};


(:~
 : Given the resulting XML document, remove KEY elements which are not part of the output structure (if they
 : are not present in the extracted facts, we don't use them) and merge consecutive sequences of the
 : KEY elements with the same id.
 : @param $doc - the XML document rebuilt from SmartLogic content
 : @param $facts - the extracted facts
 : @return the input XML document with unwanted KEY elements removed and sequences of the same KEY element merged.
:)
declare function smr:clean-redaction-keys($doc as document-node(), $facts as map:map) as document-node() {
        let $stripped-keys := xdmp:xslt-invoke($smr:strip-keys-stylesheet, $doc,
            map:new() => map:with(
                xdmp:key-from-QName(fn:QName('http://noslogan.org/components/semaphore', 'required-keys')), map:keys($facts)))
        return xdmp:xslt-invoke($smr:merge-keys-stylesheet, $stripped-keys)
};

(:~
 : Given the cleaned up document and the final key set, redact the content. Redacted text in elements is
 : indicated by <smr:redacted> elements and attribute redaction is indicated by [ ... ] around the redaction
 : marker text and an addition @smr:redacted attribute on the parent element. 
 : Fine control over redaction can be added by $keeper function. This function is called for each key and
 : should return fn:true() if the redaction should be skipped. The KEY element is passed to the function. 
 : @param $doc the document to be redacted
 : @param $facts facts to be used when redacting (if a key is not found it is not redacted)
 : @param $keeper a function to be passed in the stylesheet which can be used to indicate that
 :   a field should not be redacted.
 :)
declare function smr:redact-document($doc as document-node(), $facts as map:map, $keeper as function(element(KEY)) as xs:boolean) as document-node() {
    xdmp:xslt-invoke(
            $smr:redaction-stylesheet,
            $doc,
            map:new() 
                => map:with(xdmp:key-from-QName(xs:QName('redact:facts')), $facts)
                => map:with(xdmp:key-from-QName(xs:QName('redact:keeper')), $keeper)
        )
};

(:~
 : Given the cleaned up document and the final key set, redact the content. Redacted text in elements is
 : indicated by <smr:redacted> elements and attribute redaction is indicated by [ ... ] around the redaction
 : marker text and an addition @smr:redacted attribute on the parent element. 
 : @param $doc the document to be redacted
 : @param $facts facts to be used when redacting (if a key is not found it is not redacted)
 :)
declare function smr:redact-document($doc as document-node(), $facts as map:map) as document-node() {
    smr:redact-document($doc, $facts, function($x as element(KEY)) { fn:false() })
};