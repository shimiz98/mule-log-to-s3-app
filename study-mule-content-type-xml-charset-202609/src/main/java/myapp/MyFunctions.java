package myapp;

import org.mule.runtime.api.metadata.DataType;
import org.mule.runtime.api.metadata.MediaType;
import org.mule.runtime.api.metadata.TypedValue;
import org.mule.sdk.api.runtime.operation.Result;

public class MyFunctions {
	// 期待値 Set-Payloadに固定文字列だと、以下のとおり mediaTypeが「*/*」になって、Content-Type無しでレスポンスされる。
	// "<xxx></xxx>" as String {encoding: "UTF-8", mediaType: "*/*", mimeType: "*/*", class: "java.lang.String", contentLength: 11}

	// NG 「class」がResultになってしまった
	public static Result<String, Void> getStringWithoutMimeType1(String arg) {
		// https://docs.mulesoft.com/mule-sdk/latest/result-object#setting-the-mime-type
		// In the example above, the MediaType class is not the @MediaType annotation but Mule API’s org.mule.runtime.api.metadata.MediaType.
		// org.mule.runtime.api.metadata.MediaType
		return Result.<String, Void>builder()
				.output(arg)
				.mediaType(MediaType.ANY)
				.build();
	}

	// NG
	@org.mule.sdk.api.annotation.param.MediaType(value =  "*/*", strict = false)
	public static String getStringWithoutMimeType2(String arg) {
		return arg;
	}

	// NG 「class」がTypedValueになってしまった
	// "<qqq></qqq>" as String {encoding: "UTF-8", mediaType: "*/*", mimeType: "*/*", class: "org.mule.runtime.api.metadata.TypedValue", contentLength: 11}
	public static TypedValue<String> getStringWithoutMimeType3(TypedValue<String> arg) {
		//DataType dataType = arg.getDataType();
		return new TypedValue(arg, DataType.builder().mediaType(MediaType.ANY).build());
	}

}
