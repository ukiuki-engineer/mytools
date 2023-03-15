<?php
// 空判定・null判定について
// if(!empty($v))とif($v)の比較
print '////////////////////////////////////////////////////////////////////////////' . "\n";
print "// 空判定・null判定について\n";
print '// if(!empty($v))とif($v)の比較' . "\n";
print '////////////////////////////////////////////////////////////////////////////' . "\n";
$output = null;
exec("php -v", $output);
print_r($output);

/**
 * 空文字
 */
print "\n";
print "[空文字]\n";
$v = "";
testEmpty(!empty($v));
testValue($v);

/**
 * 0
 */
print "\n";
print "[0]\n";
$v = 0;
testEmpty(!empty($v));
testValue($v);

/**
 * null
 */
print "\n";
print "[null]\n";
$v = null;
testEmpty(!empty($v));
testValue($v);

/**
 * 変数が存在しない場合
 */
print "\n";
print "[変数が存在しない場合]\n";
testEmpty(!empty($w));
testValue($w);

/**
 * 空配列
 */
print "\n";
print "[空配列]\n";
$v = [];
testEmpty(!empty($v));
testValue($v);

/**
 * 要素が空文字の配列
 */
print "\n";
print "[要素が空文字の配列]\n";
$v = [""];
testEmpty(!empty($v));
testValue($v);

/**
 * 要素が0の配列
 */
print "\n";
print "[要素が0の配列]\n";
$v = [0];
testEmpty(!empty($v));
testValue($v);

/**
 * 要素がnullの配列
 */
print "\n";
print "[要素がnullの配列]\n";
$v = [null];
testEmpty(!empty($v));
testValue($v);

////////////////////////////////////////////////////////////////////////////
// function
////////////////////////////////////////////////////////////////////////////
function testEmpty($v)
{
    print '  !empty($変数)は';
    test($v);
}

function testValue($v)
{
    print '  $変数は';
    test($v);
}

function test($v)
{
    if ($v) {
        print "\"真\"\n";
    } else {
        print "\"偽\"\n";
    }
}
