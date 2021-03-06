xquery version "1.0-ml";

import module namespace pager = "http://marklogic.com/roxy/pager-lib" at "/app/views/helpers/pager-lib.xqy";

import module namespace test="http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

test:assert-not-exists(pager:previous-page(1, 10, 50, "", "")),

let $actual := pager:previous-page(11, 10, 50, "/search", "index")
return (
  test:assert-exists($actual/xhtml:a),
  test:assert-equal("/search?index=1", $actual/xhtml:a/@href/fn:string())
),

let $actual := pager:previous-page(21, 10, 50, "/search?a=b", "index")
return (
  test:assert-exists($actual/xhtml:a),
  test:assert-equal("/search?a=b&amp;index=11", $actual/xhtml:a/@href/fn:string())
),

let $actual := pager:previous-page(21, 10, 50, "/search?index=21&amp;a=b", "index")
return (
  test:assert-exists($actual/xhtml:a),
  test:assert-equal("/search?index=11&amp;a=b", $actual/xhtml:a/@href/fn:string())
),

let $actual := pager:previous-page(21, 10, 50, "/search?a=b&amp;index=21", "index")
return (
  test:assert-exists($actual/xhtml:a),
  test:assert-equal("/search?a=b&amp;index=11", $actual/xhtml:a/@href/fn:string())
),

let $actual := pager:previous-page(21, 10, 50, "/search?index=21", "index")
return (
  test:assert-exists($actual/xhtml:a),
  test:assert-equal("/search?index=11", $actual/xhtml:a/@href/fn:string())
)


