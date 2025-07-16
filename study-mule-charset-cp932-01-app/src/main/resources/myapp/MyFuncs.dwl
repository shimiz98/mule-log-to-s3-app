%dw 2.0
// HELPME もっと簡単な方法ありそう
// https://docs.mulesoft.com/dataweave/latest/dw-core-types#:~:text=expression%20(regex)%20type.-,Result,-type%20Result%20%3D%20%7B%20success
fun mySuccessResult(result) : Result = {success: true, result: result}
fun myErrorResult(error) : Result = {success: false, error: error}

// content-type が「application/json charset=shift-jis」以外ならばエラーを返却する関数
fun checkContentType(httpReqAttr) : Result = do {
	var contentType = httpReqAttr.headers."content-type"
    var mimeType = dw::module::Mime::fromString(contentType)
    //var mimeType = {success:true, result: {"type":"application", subtype:"json", parameters:{charset:"shift-JIS"}}} 
    ---
    if (!mimeType.success)
        dw::Runtime::fail(mimeType.error)
    else mimeType.result match {
        case x if x."type" != "application" -> myErrorResult("mime type is not application: " ++ contentType)
        case x if x."subtype" != "json" -> myErrorResult("mime subtype is not json: " ++ contentType)
        case x if lower(x.parameters.charset) != "shift-jis" -> myErrorResult("mime charset is not shift-jis: " ++ contentType)
        else -> mySuccessResult(mimeType.result)
    }
}
