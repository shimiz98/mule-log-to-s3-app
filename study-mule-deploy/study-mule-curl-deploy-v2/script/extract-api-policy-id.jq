# Co-authored-by: Codex GPT-5.6 Luna
def my_same_key($a; $b):
  $a.groupId == $b.groupId
  and
  $a.assetId == $b.assetId;

if length != 2 then
  error("入力ファイルは2個指定してください")
elif (.[0] | type) != "array" or (.[1] | type) != "array" then
  error("入力ファイルの内容は配列である必要があります")
elif any(.[]; any(.[]; type != "object")) then
  error("配列の要素はobject型である必要があります")
else
  .[0] as $asis
  | .[1] as $tobe

  | (
      $tobe
      | map(
          . as $tobeItem
          | ($asis | map(
              select(my_same_key(.; $tobeItem))
            )) as $matches

          | if ($matches | length) > 0 then
              $matches[]
              | {
                  type: "変更",
                  id: .id,
                  configFilePath: $tobeItem.configFilePath
                }
            else
              {
                type: "追加",
                configFilePath: $tobeItem.configFilePath
              }
            end
        )
    )
    +
    (
      $asis
      | map(
          . as $asisItem
          | select(
              ($tobe | any(.[]; my_same_key($asisItem; .))) | not
            )
          | {
              type: "削除",
              id: .id
            }
        )
    )
end
