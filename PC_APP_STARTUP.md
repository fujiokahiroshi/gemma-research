# AI NAS Manager PC App: Windows起動手順

## 初回取得

\`\`\`powershell
git clone --recursive https://github.com/fujiokahiroshi/gemma-research.git
cd gemma-research
\`\`\`

\`--recursive\` を付けずにcloneした場合:

\`\`\`powershell
git submodule update --init --recursive
\`\`\`

## LM Studioを起動

AI NAS Managerは次のローカルAPIを使用する。

- URL: \`http://127.0.0.1:1234\`
- モデルID: \`gemma4-12b-qat\`
- Context Length: \`16384\`
- Parallel Requests: \`1\`

LM StudioのDeveloper / Local Server画面からサーバーを開始するか、PowerShellで次を実行する。

\`\`\`powershell
lms server start
lms load google/gemma-4-12b-qat --identifier gemma4-12b-qat --context-length 16384 --parallel 1 --gpu max -y
\`\`\`

確認コマンド:

\`\`\`powershell
lms server status
lms ps
Invoke-RestMethod http://127.0.0.1:1234/v1/models
\`\`\`

## PC Appを起動

\`gemma-research\` のトップで実行する。

\`\`\`powershell
.\start_pc_app.ps1
\`\`\`

実行ポリシーで拒否される場合:

\`\`\`powershell
powershell -ExecutionPolicy Bypass -File .\start_pc_app.ps1
\`\`\`

ブラウザーを自動で開かない場合:

\`\`\`powershell
.\start_pc_app.ps1 -NoBrowser
\`\`\`

起動後に <http://127.0.0.1:8788> を開く。

## 起動ラッパーの修正（2026-09-13）

clone方法やsubmoduleの構成によって、本体の起動スクリプトが次のどちらにあっても検出できるようにした。

\`\`\`text
ai-nas-manager/start_pc_app.ps1
ai-nas-manager/ai-nas-manager/start_pc_app.ps1
\`\`\`

起動ラッパーは次を行う。

1. 上記2種類の配置から本体起動スクリプトを検出する。
2. 本体がなければsubmoduleを初期化する。
3. \`uv\` の存在を確認する。
4. YOLOX-Tiny ONNXがなければダウンロードし、SHA-256を検証する。
5. LM Studioの \`/v1/models\` を確認する。
6. 本体の \`start_pc_app.ps1\` を実行する。

## よくあるエラー

### \`Could not resolve host: github.com\`

GitHubのDNS名前解決に失敗している。本体が既にある場合はcloneを繰り返さず、正しい本体パスのスクリプトを実行する。

\`\`\`powershell
cd .\ai-nas-manager
.\start_pc_app.ps1
\`\`\`

ネスト構成の場合:

\`\`\`powershell
cd .\ai-nas-manager\ai-nas-manager
.\start_pc_app.ps1
\`\`\`

### \`127.0.0.1:1234\` へ接続できない

\`\`\`powershell
lms server start
lms server status
lms ps
\`\`\`

\`lms ps\` に \`gemma4-12b-qat\` がなければ、上記の \`lms load\` を実行する。

### PC Appのポートを変更

\`\`\`powershell
.\start_pc_app.ps1 -Port 8790
\`\`\`

## 2026-09-13のPC App修正

- 映像と画像の表示切り替えを修正。
- 別ファイルを選択しても古い映像のままになる問題を修正。
- 解析中のファイル切り替え時に、古い解析を停止する処理を追加。
- 映像の一時停止とリアルタイム解析を同期。
- Scene要約が途中で切れた場合の再試行を追加。
- メニューよりカード画像が前面に出る重なり順を修正。

詳細はsubmodule内の \`docs/pc-app-update-2026-09-13.md\` を参照する。

