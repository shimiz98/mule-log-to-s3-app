# Co-authored-by: Codex GPT-5.6 Luna
def my_same_key($a; $b):
  $a.groupId == $b.groupId
  and
  $a.assetId == $b.assetId;

if length != 2 then
  error("入力ファイルは2個指定してください")
elif (.[0] | type) != "array"
  or (.[1] | type) != "array" then
  error("入力ファイルの内容は配列である必要があります")
elif any(.[]; any(.[]; type != "object")) then
  error("配列の要素はobject型である必要があります")
else
  .[0] as $asis
  | .[1] as $tobe

  | reduce range(0; ($tobe | length)) as $tobeIndex
      ({used: [], output: []};

        . as $state
        | ([
            range(0; ($asis | length)) as $asisIndex
            | select(($state.used | index($asisIndex)) == null)
            | select(
                my_same_key(
                  $asis[$asisIndex];
                  $tobe[$tobeIndex]
                )
              )
            | $asisIndex
          ][0] // null) as $asisIndex

        | if $asisIndex == null then
            .output += [{
              action: "追加",
              configFilePath: $tobe[$tobeIndex].configFilePath
            }]
          else
            .used += [$asisIndex]
            | .output += [{
                action: "変更",
                apiPolicyId: $asis[$asisIndex].id,
                configFilePath: $tobe[$tobeIndex].configFilePath
              }]
          end
      )

  | . as $result
  | $result.output
    + [
        range(0; ($asis | length)) as $asisIndex
        | select(($result.used | index($asisIndex)) == null)
        | select(
            any(
              $tobe[];
              my_same_key($asis[$asisIndex]; .)
            )
          )
        | {
            action: "削除",
            apiPolicyId: $asis[$asisIndex].id,
            assetId:  $asis[$asisIndex].assetId
          }
      ]
end
