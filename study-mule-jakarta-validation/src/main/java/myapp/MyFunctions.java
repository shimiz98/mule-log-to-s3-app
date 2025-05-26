package myapp;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.mule.runtime.api.metadata.TypedValue;
import org.mule.runtime.api.streaming.bytes.CursorStream;
import org.mule.runtime.api.streaming.bytes.CursorStreamProvider;
import org.mule.sdk.api.annotation.metadata.fixed.InputJsonType;
import org.mule.sdk.api.runtime.parameter.Literal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import myapp.dto.AbcReq;

public class MyFunctions {
	private static final Logger LOGGER = LoggerFactory.getLogger(MyFunctions.class);

	/**
	 * データをjavaの型「InputStream」で受け取り、ログ出力する。
	 * @see <a href='https://docs.mulesoft.com/mule-sdk/latest/binary-streaming#binary-streaming-in-operations'>
	 *      Java SDK > Streaming > Binary Streaming in Operations</a>
	 */
	public static String acceptInputStream(InputStream content) {
		LOGGER.info("payload javaClass={}", content.getClass().getName());
		return "dummy-value";
	}
	
	/**
	 * データをアノテーション「@InputJsonType」付きjavaの型「InputStream」で受け取り、ログ出力する。
	 * @see <a href='https://docs.mulesoft.com/mule-sdk/latest/define-parameters'>
	 *      Java SDK > Best Practices > Defining Parameters</a>
	 */
	public static String acceptInputJsonTypeInputStream(@InputJsonType(schema = "myapp/my-schema.json") InputStream content) {
		LOGGER.info("payload javaClass={}", content.getClass().getName());
		return "dummy-value";
	}

	/**
	 * データをjavaの型「Object」で受け取り、ログ出力する。
	 */
	public static String acceptObject(Object content) {
		LOGGER.info("payload javaClass={} value={}", content.getClass().getName(), toString(content));
		return "dummy-value";
	}

	/**
	 * データをjavaの型「TypedValue&lt;Object>」で受け取り、ログ出力する。
	 * @see <a href='https://docs.mulesoft.com/mule-sdk/latest/special-parameters#typedvaluetype'>
	 *      Java SDK > Advanced Parameter Handling > Special Parameters</a>
	 */
	public static String acceptTypedValueObject(TypedValue<Object> content) {
		LOGGER.info("payload javaClass={} value={} dataType={} byteLength={}", content.getClass().getName(), toString(content.getValue()), content.getDataType(), content.getByteLength());
		if (content.getValue() instanceof CursorStreamProvider) {
			CursorStreamProvider csp = (CursorStreamProvider) content.getValue();
			try (CursorStream cs = csp.openCursor()) {
				String s = new String(cs.readAllBytes(), StandardCharsets.UTF_8);
				LOGGER.info("CursorStream={}", s);
			} catch (IOException e) {
				new UncheckedIOException(e);
			}
		}
		return "dummy-value";
	}

	/**
	 * データをjavaの型「Literal&lt;Object>」で受け取り、ログ出力する。
	 * @see <a href='https://docs.mulesoft.com/mule-sdk/latest/special-parameters#literal'>Literal&lt;Type></a>
	 */
	public static String acceptLiteralInputStream(Literal<InputStream> literal) {
		LOGGER.info("payload javaClass={} literal.literalValue={} literal.type={}", literal.getClass().getName(), literal.getLiteralValue().get(), literal.getType());
		return "dummy-value";
	}
	

	/**
	 * MapとListを含むネストしたデータ構造を文字列に変換する。
	 * @param obj
	 * @return
	 */
	public static String toString(Object obj) {
		if (obj instanceof Map) {
			Map<?,?> map = (Map<?,?>) obj;
			return map.entrySet().stream().map(e -> toString(e.getKey()) + ":" + toString(e.getValue())).collect(Collectors.joining(",", "{", "}"));
		} else if (obj instanceof List) {
			List<?> list = (List<?>) obj;
			return list.stream().map(e -> toString(e)).collect(Collectors.joining(",", "[", "]"));
		} else if (obj instanceof Object[]) {
			return toString(Arrays.asList(obj));
		} else {
			return obj.toString();
		}

	}

	/**
	 * Object型のデータを入力チェックする。
	 */	
	public static Object validateObject(Object inputValue) {
		
		//https://qiita.com/5zm/items/89b7198cab74f2d0f4a1
		
        // 1. create validator
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        Validator validator = factory.getValidator();

        // 2. create target object
		@SuppressWarnings("unchecked")
		Map<String, Object> map = (Map<String, Object>) inputValue;
		AbcReq data = new AbcReq();
		data.setA((String)map.get("a")); // TODO implement other field.
		data.setB((String)map.get("b"));

        // 3. validate
        Set<ConstraintViolation<AbcReq>> constraintViolations = validator.validate(data);

        // 4. check result
        int errorCount = constraintViolations.size();
        System.out.println("validate error count : " + errorCount);
        if (errorCount > 0) {
            // showErrorDetails(constraintViolations);
            constraintViolations.stream().forEach(System.out::println);
        }
        
        return inputValue;
	}
	
	/**
	 * InputStream型のデータを入力チェックする。
	 * TODO 以下の記事だと TypedValue<InputStream>だが、なぜか呼び出されなかったので、とりあえず TypedValue<Object> にしたのを改良する。
	 * https://docs.mulesoft.com/mule-sdk/latest/special-parameters#typedvaluetype
	 */
	public static TypedValue<Object> validateInputStream(TypedValue<Object> inputValue) {
		
		//https://qiita.com/5zm/items/89b7198cab74f2d0f4a1
		
        // 1. create validator
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        Validator validator = factory.getValidator();

        // 2. create target object
        if (!(inputValue.getValue() instanceof CursorStreamProvider)) {
        	throw new RuntimeException("Unexpected class: expected=" + CursorStreamProvider.class.getName() + " actual=" + inputValue.getClass().getName());
        }
        AbcReq data;
		try (CursorStream cs = ((CursorStreamProvider)inputValue.getValue()).openCursor()){
	        ObjectMapper mapper = new ObjectMapper();  // TODO create once, reuse			
			data = mapper.readValue(cs, AbcReq.class);
		} catch (IOException e) {
			throw new UncheckedIOException(e);
		}

        // 3. validate
        Set<ConstraintViolation<AbcReq>> constraintViolations = validator.validate(data);

        // 4. check result
        int errorCount = constraintViolations.size();
        System.out.println("validate error count : " + errorCount);
        if (errorCount > 0) {
            // showErrorDetails(constraintViolations);
            constraintViolations.stream().forEach(System.out::println);
        }
        
        return inputValue;
	}
}
