type GaijiConvertResult = {| "表示用の値": String, "登録用の値": String|}

// 外字を含む項目を変換する関数
fun convertSingleField(keyPrefix: String, value: String): GaijiConvertResult = {
	(keyPrefix ++ "<表示用>"): convertSingleValueForDisplay(value),
	(keyPrefix ++ "<登録用>"): convertSingleValueForSubmmit(value),   
}

// 外字を含む項目を戻す関数<入力データをObjectで指定する場合>
fun restoreSingleField(keyPrefix: String, data: Object): String = restoreSingleField(data[keyPrefix ++ "<登録用>"], data[keyPrefix ++ "<登録用>"])

// 外字を含む項目を戻す関数<入力データを2個のStringで指定する場合>
// TODO: 表示用と登録用が一致することの検証処理(validate)を実装する
fun restoreSingleField(valueForDisplay: String, valueForSubmmit: String): String = do {
	var originalValue = restoreSingleValueForSubmmit(valueForSubmmit)
	---
	dw::Runtime::failIf(originalValue, valueForDisplay != convertSingleValueForDisplay(originalValue))
}

// 外字を含む文字列を表示用に変換する関数
fun convertSingleValueForDisplay(value: String): String = value replace /\uE000/ with("髙")
// 外字を含む文字列を登録用に変換する関数
fun convertSingleValueForSubmmit(value: String): String = dw::core::Binaries::toBase64(dw::util::Coercions::toBinary(value, "UTF-8"))

// 外字を含む文字列を登録用に復元する関数
fun restoreSingleValueForSubmmit(value: String): String = dw::core::Binaries::fromBase64(value) dw::util::Coercions::toString "UTF-8"
