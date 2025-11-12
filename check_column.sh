#!/bin/bash
# check_column.sh - コラム配信前検証スクリプト

COLUMN_FILE=$1

if [ -z "$COLUMN_FILE" ]; then
    echo "使用法: $0 <コラムファイル>"
    exit 1
fi

if [ ! -f "$COLUMN_FILE" ]; then
    echo "エラー: ファイル '$COLUMN_FILE' が見つかりません"
    exit 1
fi

echo "========================================="
echo "   コラム配信前検証"
echo "========================================="
echo ""

# 文字数チェック
echo "【文字数チェック】"
CHAR_COUNT=$(sed -n '/【今日の金融トピック】/,/#HVMC_Morningcolumn/p' "$COLUMN_FILE" | grep -v '#HVMC_Morningcolumn' | tr -d '\n' | wc -m)
echo "  文字数: ${CHAR_COUNT}文字"

if [ $CHAR_COUNT -lt 600 ]; then
    echo "  ❌ 文字数不足（600文字未満）"
    PASS=false
elif [ $CHAR_COUNT -gt 800 ]; then
    echo "  ❌ 文字数超過（800文字超）"
    PASS=false
else
    echo "  ✅ 文字数OK（600-800文字）"
fi
echo ""

# 必須要素チェック
echo "【必須要素チェック】"
grep -q "【今日の金融トピック】" "$COLUMN_FILE" && echo "  ✅ 【今日の金融トピック】あり" || { echo "  ❌ 【今日の金融トピック】なし"; PASS=false; }
grep -q "〜" "$COLUMN_FILE" && echo "  ✅ 情報源（〜）あり" || { echo "  ❌ 情報源（〜）なし"; PASS=false; }
grep -q "↑" "$COLUMN_FILE" && echo "  ✅ 導入部（↑）あり" || { echo "  ❌ 導入部（↑）なし"; PASS=false; }
grep -q "#HVMC_Morningcolumn" "$COLUMN_FILE" && echo "  ✅ ハッシュタグあり" || { echo "  ❌ ハッシュタグなし"; PASS=false; }
echo ""

# 絵文字チェック
echo "【絵文字チェック】"
EMOJI_COUNT=$(grep -oP '[\x{1F300}-\x{1F9FF}]' "$COLUMN_FILE" | wc -l)
echo "  絵文字: ${EMOJI_COUNT}個"
if [ $EMOJI_COUNT -eq 0 ]; then
    echo "  ⚠️  絵文字が使用されていません"
else
    echo "  ✅ 絵文字あり"
fi
echo ""

# 改行チェック
echo "【改行チェック】"
BLANK_LINES=$(grep -c '^$' "$COLUMN_FILE")
echo "  空行: ${BLANK_LINES}行"
if [ $BLANK_LINES -lt 3 ]; then
    echo "  ⚠️  空行が少ない（読みやすさに影響）"
else
    echo "  ✅ 適切な改行あり"
fi
echo ""

echo "========================================="
if [ "$PASS" = "false" ]; then
    echo "  ❌ 検証失敗: 修正が必要です"
    echo "========================================="
    exit 1
else
    echo "  ✅ 検証合格: 配信可能です"
    echo "========================================="
    exit 0
fi
