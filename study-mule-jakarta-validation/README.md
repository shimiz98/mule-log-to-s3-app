# study-mule-jakarta-validation
## 目的
json形式のHTTPリクエストボディに対して、Jakarta Bean Validationを用いて独自の入力チェックを行う。

## 実装のポイント

* javaメソッドの引数を`TypedValue<Object>` で受け取る。
   * TODO 以下の記事だと `TypedValue<InputStream>`で受け取れるはずだが、なぜかダメだったので、とりあえず `TypedValue<Object>` にしている。
   * [Java SDK > Advanced Parameter Handling > Special Parameters](https://docs.mulesoft.com/mule-sdk/latest/special-parameters#typedvaluetype)
* jackson data bind を使って、InputStreamからPOJOに変換する。
* Jakarta Bean Validation を使って、入力チェックする。
  * 3.0までは[Jakarta Bean Validation 3.0](https://beanvalidation.org/3.0/)で、3.1以降は「Bean」が消えて[Jakarta Validation 3.1](https://beanvalidation.org/3.1/)
