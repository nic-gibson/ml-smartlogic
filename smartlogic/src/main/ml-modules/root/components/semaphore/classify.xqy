xquery version "1.0-ml";

module namespace sm = "http://noslogan.org/components/semaphore/classify";

import module namespace mp = "http://noslogan.org/components/smartlogic/multipart" at "/components/smartlogic/multipart.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace http = "xdmp:http";
declare namespace html = "http://www.w3.org/1999/xhtml";


declare option xdmp:mapping "false";

(:~
: Return a Semaphore classification server request document to be passed
: with our document to configure classification
: @return a <request/> element
:)
declare function sm:generate-request() as element(request) {
	<request op="CLASSIFY">
		<document>
			<body type="HTML"/>
			<!--char_count_cutoff>500000</char_count_cutoff-->
			<clustering type="RMS" threshold="20"/>
			<feedback/>
			<language>Default</language>
			<min_average_article_pagesize>1.0</min_average_article_pagesize>
			<operation_mode>None</operation_mode>
			<output type="xml"/>
			<path/>
			<singlearticle/>
			<threshold>60</threshold>
		</document>
	</request>
};

(:~
: Call the classification server and return the classified document. Note that two documents
: are returned from the request and we want the second
: @param $server-uri - the URI to which we post the request
: @param $filename - the name of the file we are uploading
: @param $file - the content of the file we are uploading
: @param $request - the classification server configuration request
: @return the classified document in Smartlogic's STRUCTUREDOCUMENT format.
:)
declare function sm:classify(
	$server-uri as xs:string,
	$filename as xs:string,
	$file as document-node(),
	$request as element(request)
) as item()? {
	let $boundary := concat("----------boundary-", xdmp:random())

	let $multipart := mp:multipart-encode(
		$boundary,
		(
			map:new() => map:with('name', 'UploadFile') => map:with('filename', $filename) => map:with('content-type', "text/plain") => map:with('content', $file),
			map:new() => map:with('name', 'XML_INPUT') => map:with('filename', 'request.xml') => map:with('content-type', 'text/xml') => map:with('content', $request),
			map:new() => map:with('name', "method") => map:with('content', "docs.upload")
		)
	)

	let $response := xdmp:http-post(
		$server-uri,
		<options xmlns="xdmp:http">
			<headers>
				<Content-Type>multipart/form-data; boundary={$boundary}</Content-Type>
			</headers>
		</options>,
		$multipart
	)

	let $code := $response/http:code/fn:string()

	return if (fn:starts-with($code, '2')) then $response[2]
	else fn:error(xs:QName('sm:error'), "Error code from Semaphore", xdmp:quote($response))
};

