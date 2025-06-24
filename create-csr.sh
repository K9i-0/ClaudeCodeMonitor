#!/bin/bash

# CSR作成スクリプト
# キーチェーンアクセスを使わずにコマンドラインでCSRを作成

echo "Creating Certificate Signing Request (CSR)..."

# CSRのための設定ファイルを作成
cat > csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
CN = Claude Code Monitor Developer ID
emailAddress = your-email@example.com
C = JP
ST = Tokyo
L = Tokyo
O = Your Organization Name
OU = Development
EOF

# 秘密鍵とCSRを生成
openssl req -new -newkey rsa:2048 -nodes \
    -keyout developerID.key \
    -out developerID.csr \
    -config csr.conf

echo "CSR created: developerID.csr"
echo "Upload this CSR file to Apple Developer portal"

# 一時ファイルを削除
rm csr.conf