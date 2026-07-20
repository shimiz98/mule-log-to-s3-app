# 2つのJSONを比較して、json patch形式で差分を出力するjqスクリプト
# v2: 配列は完全一致比較。一部でも異なれば配列全体を置換。
      ただし、トップレベル配列は、完全一致ではなく、要素毎のkey項目の値で突合して比較する。

# JSON Pointer用エスケープ
# "~" → "~0"
# "/" → "~1"
def pointer_escape:
  gsub("~"; "~0")
  | gsub("/"; "~1");

def child_path($path; $key):
  $path + "/" + ($key | pointer_escape);

# 配列要素から比較キーを取り出す。
#
# arrayCompareKeys = ["id"] の場合:
#   {"id": 1, "name": "Alice"} → [1]
#
# arrayCompareKeys = ["type", "id"] の場合:
#   {"type": "user", "id": 1} → ["user", 1]
def array_compare_key($item):
  [
    $arrayCompareKeys[] as $key
    | $item[$key]
  ];

# 指定した比較キーを持つ要素を配列から取得する。
# 存在しない場合は null。
def find_by_compare_key($array; $compareKey):
  first(
    $array[]
    | select(array_compare_key(.) == $compareKey)
  ) // null;

# 指定した比較キーを持つ要素のインデックスを取得する。
# 存在しない場合は null。
def find_index_by_compare_key($array; $compareKey):
  first(
    range(0; $array | length) as $index
    | select(
        array_compare_key($array[$index]) == $compareKey
      )
    | $index
  ) // null;

# トップレベル配列のJSON Patchを生成する。
#
# 出力順:
# 1. beforeの順番で変更
# 2. beforeの後ろから削除
# 3. afterの順番で追加
#
# removeを後ろから処理することで、
# 配列インデックスのずれを防ぐ。
def top_level_array_patch($before; $after):
  (
    # 同じ比較キーが存在し、内容が変わった要素
    $before
    | to_entries[]
    | . as $beforeEntry
    | array_compare_key($beforeEntry.value) as $compareKey
    | find_by_compare_key($after; $compareKey) as $afterItem
    | select($afterItem != null)
    | select($beforeEntry.value != $afterItem)
    | {
        op: "replace",
        path: "/" + ($beforeEntry.key | tostring),
        value: $afterItem
      }
  ),

  (
    # beforeにしか存在しない要素
    # インデックスがずれないよう、後ろから削除する
    [
      $before
      | to_entries[]
      | . as $beforeEntry
      | array_compare_key($beforeEntry.value) as $compareKey
      | select(
          find_index_by_compare_key($after; $compareKey) == null
        )
      | $beforeEntry.key
    ]
    | sort
    | reverse[]
    | {
        op: "remove",
        path: "/" + tostring
      }
  ),

  (
    # afterにしか存在しない要素
    # afterの記載順で配列末尾に追加する
    $after[]
    | . as $afterItem
    | array_compare_key($afterItem) as $compareKey
    | select(
        find_index_by_compare_key($before; $compareKey) == null
      )
    | {
        op: "add",
        path: "/-",
        value: $afterItem
      }
  );

def json_patch($before; $after; $path):
  if $before == $after then
    empty

  # トップレベルが配列の場合は、要素単位で比較する
  elif $path == ""
   and ($before | type) == "array"
   and ($after  | type) == "array"
   and all($before[]; type == "object")
   and all($after[]; type == "object") then

    top_level_array_patch($before; $after)

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
        | select(
            . as $property
            | $before
            | has($property)
            | not
          )
      )
    ) as $property

    | if ($before | has($property) | not) then
        {
          op: "add",
          path: child_path($path; $property),
          value: $after[$property]
        }

      elif ($after | has($property) | not) then
        {
          op: "remove",
          path: child_path($path; $property)
        }

      else
        json_patch(
          $before[$property];
          $after[$property];
          child_path($path; $property)
        )
      end

  # トップレベル以外の配列は完全一致比較
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
      value: $after
    }
  end;

. |
[
  json_patch($before[0]; $after[0]; "")
]
