xquery version "1.0-ml";


(:~ Simple multipart utils :)

module namespace mp = "http://noslogan.org/components/smartlogic/multipart";

declare option xdmp:mapping "false";

(:~
 : Create a multipart encoded node suitable for HTTP POST as form data. Content will not 
 : be base 64 encoded.
 : @param $content - a sequence of maps (one for each item) with keys of content, filename, name and content-type
 : 	(only the first is required)
 : @param $boundary - the MIME part boundary string to use
 : @return 
:)
declare function mp:multipart-encode($content as map:map*, $boundary as xs:string) as binary() {
	mp:multipart-encode($content, $boundary, "form-data", false() )
};


declare function mp:multipart-encode(
	$content as map:map*,
	$boundary as xs:string,
	$disposition as xs:string,
	$base64-encoded as xs:boolean
) as binary() {
	xdmp:multipart-encode(
		$boundary,
		element manifest {
			$content ! mp:create-part(., $disposition, $base64-encoded)
		},
		$content ! mp:encode-content(map:get(., 'content'), $base64-encoded)
	)
};

declare function mp:create-part($part as map:map, $disposition as xs:string, $base64-encoded as xs:boolean) as element(part) {
	element part {
		element headers {
				mp:content-disposition($part, $disposition),
				mp:content-type($part),
				mp:content-transfer-encoding($part, $base64-encoded)
		}
	}
};

declare function mp:content-disposition($part as map:map, $disposition as xs:string?) as element(Content-Disposition) {
	element Content-Disposition {
		fn:string-join(
			(
				mp:disposition-type($part, $disposition),
				mp:disposition-name($part),
				mp:disposition-filename($part)
			), '; ')
	}
};

declare function mp:disposition-type($part as map:map, $disposition as xs:string?) as xs:string {
	($disposition, if (map:get($part, 'content') instance of binary()) then 'attachment' else 'inline')[1]
};

declare function mp:disposition-name($part as map:map) as xs:string? {
	map:get($part, 'name') ! ('name="' || . || '"')
};

declare function mp:disposition-filename($part as map:map) as xs:string? {
	map:get($part, 'filename') ! ('filename="' || . || '"')
};

declare function mp:content-type($part as map:map) as element(Content-Type)? {
	map:get($part, 'content-type') ! element Content-Type { . }
};

declare function mp:content-transfer-encoding($part as map:map, $base64-encoded as xs:boolean) as element(Content-Transfer-Encoding) {
	element Content-Transfer-Encoding {
		if (map:get($part, 'content') instance of binary()) 
			then if ($base64-encoded) then "base64" else "binary"
			else "quoted-printable"		
	}
};

declare function mp:encode-content($content as item(), $base64-encoded as xs:boolean) as node() {
		if ($base64-encoded  
			and (
				$content instance of binary() 
				or 
				($content instance of document-node() and $content/binary())
			)) 
			
			then document { xs:base64Binary($content) }
			else if ($content instance of node())
				then $content
				else document { $content } (: multipart encode requires nodes as input :)
};
