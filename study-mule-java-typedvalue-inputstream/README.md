# study-mule-payload-typed-value
## 目的


## 概要

1. InputStream
    * [Java SDK > Streaming > Binary Streaming in Operations](https://docs.mulesoft.com/mule-sdk/latest/binary-streaming#binary-streaming-in-operations)
    * 結果: エラー「You called the function 'acceptInputStream' with these arguments:～」詳細なエラーは口述。
2. Object
    * 結果: ネストしたMap型になった。
3. TypedValue<InputStream>
    * 結果: 成功した。
4. @InputJsonType
    * [Java SDK > Best Practices > Defining Parameters](https://docs.mulesoft.com/mule-sdk/latest/define-parameters)
    * 結果: 未検証

## 補足 TypedValue に必要な pom.xml の dependency
TypedValue<InputStream>を使用するために、pom.xmlに以下のdependencyを追加した。
```xml
<dependency>
  <groupId>org.mule.runtime</groupId>
  <artifactId>mule-api</artifactId>
  <version>1.9.5</version>
  <scope>provided</scope>
</dependency>
```

なお[Release Your Custom Connector](https://docs.mulesoft.com/mule-sdk/latest/customer-connector-upgrade#release-your-custom-connector)
および[Specify Java Compatibility](https://docs.mulesoft.com/mule-sdk/latest/java-version-support#specify-java-compatibility)
に記載された以下のdependencyでは、TypeValuedの型が解決できなかった。

```xml
<dependency>
  <groupId>org.mule.sdk</groupId>
  <artifactId>mule-sdk-api</artifactId>
  <version>0.10.1</version>
</dependency>
```

代わりに、[Java SDK > Getting Started with the Mule SDK for Java](https://docs.mulesoft.com/mule-sdk/latest/getting-started#explore-the-generated-project)を参照して、別途Custom Mule Connectorを作成してTypeValued型が含まれているjarファイルを調べたところ、`org.mule.runtime:mule-api`だった。

```xml
<parent>
  <groupId>org.mule.extensions</groupId>
  <artifactId>mule-modules-parent</artifactId>
  <version>1.9.0</version>
</parent>
```

> * The parent POM defines the minimum Mule version, which must be compatible with the target Mule version. 
> * The Mule runtime version you use determines the version of the mule-modules-parent. 
> * For example, if you use Mule runtime 4.6.0, you must use mule-modules-parent 1.6.0. 
> * If you must compile your connector with Java 17, you must use mule-modules-parent 1.9.0. 

## 補足 javaメソッドの引数を InputStream 型にした場合のエラー
```
Message               : "You called the function 'acceptInputStream' with these arguments: 
  1: Object ({root: {a: {aa1 @(q1: "1", q2: "2"): "AA1",aa2 @(q1: "1", q2: "2"): "AA2"},b:...)

But it expects arguments of these types:
  1: Binary | Null


1| output application/java --- java!myapp::MyFunctions::acceptInputStream(payload)
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

```
Message               : "You called the function 'acceptInputStream' with these arguments: 
  1: Object ({a: [{aa1: "AA1",aa2: "AA2"}],b: "B",c: "C"} as Object {encoding: "UTF-8", me...)

But it expects arguments of these types:
  1: Binary | Null


1| output application/java --- java!myapp::MyFunctions::acceptInputStream(payload)
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```


## 補足 HTTPボディが誤ったxml形式の場合のエラー
入力データ
```xml
<root>
    <a>
        <aa1 q1='1' q2='2'>AA1</aa1>
        <aa2 q1='1' q2='2'>AA2</aa2>
    </a>
    <b>B</b>
    <c>B</c>
<!--</root>-->
```

エラーメッセージ
```
Message               : "Unexpected EOF; was expecting a close tag for element <root>
 at [row,col {unknown-source}]: [8,14], while reading `payload` as Xml.
 [row,col]: [8,14]" evaluating expression: "output application/java --- java!myapp::MyFunctions::acceptInputStream(payload)".
```

DataWeave`output application/dw --- payload`で出力している箇所は、異なるエラーメッセージだった。
```
Message               : "java.io.IOException - Stream is closed
java.io.IOException: Stream is closed
	at org.mule.runtime.core@4.9.0/org.mule.runtime.core.internal.streaming.bytes.AbstractCursorStream.assertNotDisposed(AbstractCursorStream.java:82)
～以下略～
```

## 補足 HTTPボディがjson形式の場合のエラー

入力データ
```json
{
    "a": [ {"aa1": "AA1", "aa2": "AA2"} ],
    "b": "B",
    "c": "C"
```

エラーメッセージ
```
Message               : "Unexpected end-of-input at payload@[5:1] (line:column), expected '}', while reading `payload` as Json.
 
5| 
   ^" evaluating expression: "output application/java --- java!myapp::MyFunctions::acceptInputStream(payload)".
```

## 補足 リクエストヘッダ`content-type: application/octet-stream`の場合は、InputStream型になる

※ リクエストヘッダに`content-type:`が無い場合も、同様だった。

```
INFO payload javaClass=org.mule.weave.v2.core.io.ByteArraySeekableStream
INFO payload javaClass=org.mule.runtime.core.internal.streaming.bytes.ManagedCursorStreamProvider value=org.mule.runtime.core.internal.streaming.bytes.ManagedCursorStreamProvider@61796651
INFO "PHJvb3Q+PC9yb290Pg==" as Binary {base: "64"} as Binary {encoding: "UTF-8", mediaType: "*/*; charset=UTF-8", mimeType: "*/*", class: "org.mule.runtime.core.internal.streaming.bytes.ManagedCursorStreamProvider", contentLength: 13}
INFO payload 
    javaClass=org.mule.runtime.api.metadata.TypedValue 
    value=org.mule.runtime.core.internal.streaming.bytes.ManagedCursorStreamProvider@61796651 
    dataType=SimpleDataType{type=org.mule.runtime.core.internal.streaming.bytes.ManagedCursorStreamProvider, mimeType='*/*; charset=UTF-8'} 
    byteLength=OptionalLong[13]
INFO CursorStream=<root></root>
```

## 補足 javaメソッドの呼び出し方法
1. DataWeave
    * `java!${パッケージ名}::${クラス名}::${メソッド名}(${引数})` ← staticメソッド
    * `java!${パッケージ名}::${クラス名}::new(${引数})` ← コンストラクタ
    * https://docs.mulesoft.com/dataweave/latest/dataweave-cookbook-java-methods
    * https://docs.mulesoft.com/mule-runtime/latest/intro-java-integration
2. Javaモジュール
    * https://docs.mulesoft.com/java-module/latest/
3. Java SDK
    * https://docs.mulesoft.com/mule-sdk/latest/getting-started

## 補足 Java EE ライブラリ

|Mule Runtime|java 8|java 11|java 17|
|-|-|-|-|
|Mule 4.4.0 系 |○含む|○含む|―動作しない|
|Mule 4.5 Edge |＾|＾|＾|
|Mule 4.6 Edge |△含む(互換のため)|△含む(互換のため)|×含まない|
|Mule 4.7 LTS |＾|＾|＾|
|Mule 4.8 Edge|＾|＾|＾|
|Mule 4.9 LTS |―動作しない|―動作しない|×含まない|

https://docs.mulesoft.com/mule-sdk/latest/java-ee-libraries


> In the first Mule runtime version that exclusively supports Java 17 (Mule 4.9.0), connectors can no longer include Java EE libraries. 

> To ensure backward compatibility, Mule versions 4.6.0 through 4.9.0 continue to export Java EE libraries as part of the Container API only when Mule runtime runs on Java 8 or Java 11. 

> However, if Mule runtime runs on Java 17 or higher, you must include the Java EE libraries manually. 

> For connectors that support multiple Java versions, such as Java 11 and Java 17, the Java EE libraries must match the versions included in Mule runtime.

> Because Mule 4.6.x exposes Java EE libraries differently than earlier Mule versions, you must add the BOM dependency to your connector and, if applicable, exclude the provided conflicting library. 
> You can also add the libraries in the BOM dependency separately.
