# 2つのJSONを比較して、json patch形式で差分を出力するjqスクリプト
# v1: 配列は完全一致比較。一部でも異なれば配列全体を置換

# JSON Pointer用エスケープ
# "~" → "~0"
# "/" → "~1"
def pointer_escape:
  gsub("~"; "~0")
  | gsub("/"; "~1");

def child_path($path; $key):
  $path + "/" + ($key | pointer_escape);

def my_normalize($path; $value):
  if ($path | IN($unordered[]))
     and ($value | type) == "array"
  then
    ($value | sort)
  else
    $value
  end;

def json_patch($before; $after; $path):
  #TMP if $before == $after then
  if my_normalize($path; $before) == my_normalize($path; $after) then
    empty

  # 両方がオブジェクトなら、キーごとに再帰比較
  elif ($before | type) == "object"
   and ($after  | type) == "object" then

    (
      # beforeのキー順を優先
      ($before | keys_unsorted[]),

      # afterにしかないキーは、afterのキー順で最後に処理
      (
        $after
        | keys_unsorted[]
        | select(. as $key | $before | has($key) | not)
      )
    ) as $key

    | if ($before | has($key) | not) then
        {
          op: "add",
          path: child_path($path; $key),
          value: $after[$key]
        }

      elif ($after | has($key) | not) then
        {
          op: "remove",
          path: child_path($path; $key)
        }

      else
        json_patch(
          $before[$key];
          $after[$key];
          child_path($path; $key)
        )
      end

  # 配列は完全一致比較。一部でも異なれば配列全体を置換
  elif ($before | type) == "array"
    or ($after  | type) == "array" then
    {
      op: "replace",
      path: $path,
      value: $after
    }

  # 型変更またはスカラー値の変更
  else
    {
      op: "replace",
      path: $path,
      _before: $before,
      value: $after
    }
  end;

#[
#  json_patch($before[0]; $after[0]; "")
#]
$before[0] | debug | json_patch($before[0]; $after[0]; "")
