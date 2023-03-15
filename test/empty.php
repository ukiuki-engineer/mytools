<?php
// 空判定・null判定について
// if(!empty($v))とif($v)の比較
print "空判定・null判定について\n";
print 'if(!empty($v))とif($v)の比較' . "\n";

/**
 * 空文字
 */
print "\n";
print "[空文字]\n";
$v = "";
print '  !empty($変数)は';
test(!empty($v));
print '  $変数は';
test($v);

/**
 * 0
 */
print "\n";
print "[0]\n";
$v = 0;
print '  !empty($変数)は';
test(!empty($v));
print '  $変数は';
test($v);

/**
 * null
 */
print "\n";
print "[null]\n";
$v = null;
print '  !empty($変数)は';
test(!empty($v));
print '  $変数は';
test($v);

/**
 * 変数が存在しない場合
 */
print "\n";
print "[変数が存在しない場合]\n";
print '  !empty($変数)は';
test(!empty($w));
print '  $変数は';
test($w);

/**
 * 空配列
 */
print "\n";
print "[空配列]\n";
$v = [];
print '  !empty($変数)は';
test(!empty($v));
print '  $変数は';
test($v);

/**
 * 要素が空文字の配列
 */
print "\n";
print "[要素が空文字の配列]\n";
$v = [""];
print '  !empty($変数)は';
test(!empty($v));
print '  $変数は';
test($v);

/**
 * 要素が0の配列
 */
print "\n";
print "[要素が0の配列]\n";
$v = [0];
print '  !empty($変数)は';
test(!empty($v));
print '  $変数は';
test($v);

/**
 * 要素がnullの配列
 */
print "\n";
print "[要素がnullの配列]\n";
$v = [null];
print '  !empty($変数)は';
test(!empty($v));
print '  $変数は';
test($v);

function test($v)
{
    if ($v) {
        print "\"真\"\n";
    } else {
        print "\"偽\"\n";
    }
}
