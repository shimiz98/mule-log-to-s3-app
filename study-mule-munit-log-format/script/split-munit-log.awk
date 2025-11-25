function funcOutputFileName(inputFileName, inputFileLineNum, testSuiteName, testCaseName) {
    return sprintf("%05d_%s.log", inputFileLineNum, testCaseName)
}
function funcRenameOutputFile(outputFile, testSuiteName, testCaseName, testCaseResult) {
    if (ENVIRON["X_DEBUG"] != "") {
        return
    } if (ENVIRON["X_NO_RESULT"] != "") {
        renamedOutputFile = sprintf("%05d_%s.log", 0, testCaseName)
    } else {
        renamedOutputFile = sprintf("%05d_%s_%s.log", 0, testCaseName, testCaseResult)
    }
    system(sprintf("mv '%s' '%s'", outputFile, renamedOutputFile))
}
# 入力ファイルの1行目で実行する処理
FNR == 1 { # gawk なら BEGINFILE でも良い
    outputFile = funcOutputFileName(FILENAME, FNR, "", "")
}
# Test Suite の開始ログ
/^=== Running suite: / {
    testSuiteName = gensub("^=== Running suite: (.*) *===$", "\\1", 1)
    print "==" "\t" testSuiteName
}
# Test Case の開始ログ
/^+ Running test: / {
    prevTestCaseName = testCaseName
    prevOutputFile = outputFile
    # 正規表現で最短一致が無い?
    # 正規表現でプラス記号をバックスラッシュでエスケープするとWARNING出た
    testCaseName = gensub("^+ Running test: (.*)$", "\\1", 1)
    testCaseName = gensub("^(.*[^ ]) *.$", "\\1", 1, testCaseName)
    testCaseName = gensub("^(.*[^ ]) - .*$", "\\1", 1, testCaseName)
    outputFile = funcOutputFileName(FILENAME, FNR, testSuiteName, testCaseName)
    print "--" "\t" testCaseName
}
# Test Suite の終了ログ
/^(INFO|ERROR) .* org.mule.munit.runner.model.Suite: .* - test: .* - Time elapsed: .* sec/ {
    # 正規表現を変数に代入する際はアットマーク@が必要
    tmpRegEx = @/^(INFO|ERROR) .* org.mule.munit.runner.model.Suite: (.*) - test: (.*) - Time elapsed: (.*) sec/
    testCaseResult = gensub(tmpRegEx, "\\2", 1)
    tmpTestCaseName = gensub(tmpRegEx, "\\3", 1)
    testCaseElapsed = gensub(tmpRegEx, "\\4", 1)
    print "----" "\t" tmpTestCaseName "\t" testCaseResult "\t" testCaseElapsed
    if (testCaseName != tmpTestCaseName) {
        # この行が、次のTestCaseの開始行の後に出力される場合があるため、特別扱いする
        print $0 >> prevOutputFile
        funcRenameOutputFile(prevOutputFile, testSuiteName, prevTestCaseName, testCaseResult)
    } else {
        print $0 >> outputFile
        funcRenameOutputFile(outputFile, testSuiteName, testCaseName, testCaseResult)
    }
    # この行は出力したので、この後は実行せず、次の行に進む
    next
}
# Test Suite の開始ログ
/^= Tests run: .* - Failed: .* - Errors: .* - Skipped: .* - Time elapsed: .* sec/ {
    outputFile = funcOutputFileName(FILENAME, FNR, testSuiteName, "")
    print "====" "\t" testSuiteName
}
# 入力された行を出力する(ただしawkの「next」で次に進んだ行は、ここに到達しないので、「next」の前に出力しておく)
{
    print $0 >> outputFile
}
