# Gemma Research

ローカルのGemmaを映像Stream解析バックエンドとして利用し、映像を全フレーム推論せずに
Fragmentへ分割してテキスト化し、Scene単位の意味データベースを構築する研究プロジェクトです。

## プロジェクトの目的

AI NAS Managerへ、長時間の映像を個人でも継続的に解析できるローカルAI基盤を追加します。
映像をすべてクラウドへ送ったり、全フレームをVisionモデルで処理したりせず、変化のある区間だけを
Fragmentとして抽出します。各Fragmentの代表画像、時刻、音、字幕、Gemmaの説明文を関連付け、
複数FragmentをSceneへ統合して検索可能な映像データベースを作ります。

推論モデルと映像処理を分離しているため、現在のGemmaから将来の高性能なローカルモデルへ
交換できます。PC版でアルゴリズムとUIを検証し、その後Rockchip搭載NASへ移植する構成です。

## 基本パイプライン

```text
MP4 / カメラ / RTSP / MPEG-TS
  -> FFmpeg または Rockchip MPPによるデコード
  -> 映像変化・物体・音・字幕・手動Markerの軽量検出
  -> オンラインFragment生成
  -> 代表画像だけをGemma Visionへ投入
  -> Fragment説明文を逐次生成・更新
  -> オンラインScene境界検出と意味統合
  -> Scene要約を生成
  -> 画像・時刻・説明・SceneをSQLiteへ保存
  -> PC Appで再生・検索・確認・修正
```

映像の終了を待つバッチ処理ではなく、Streamが続いている最中にFragmentとテキストを生成します。
Gemmaの処理が遅れた場合は古い候補を蓄積せず、最新候補を優先する設計です。

## PC Appの機能

- Windowsのファイル選択画面からMP4を開く
- 静的解析とリアルタイム解析を切り替える
- 映像を再生しながらFragmentを逐次追加する
- Fragmentのサムネイル、時刻、Gemmaの説明文を並べて表示する
- 複数FragmentをSceneへまとめ、Scene全体の要約を表示する
- SceneまたはFragmentの位置から映像を再生する
- 説明文を利用して映像データベースを検索する
- ユーザーが説明やMarkerを確認・修正する

## Fragment・Scene検出

Fragment候補は、映像変化、物体検出、音声イベント、字幕、手動Markerを組み合わせて生成します。
過分割を抑えるため、ヒステリシス、信号別クールダウン、複数信号の統合判定を利用します。

Scene境界は、リアルタイム性を保つオンラインCUSUM/BOCPDと意味変化を組み合わせます。
解析後はPELTで境界を再評価し、Adaptive Memory版をShadow Modeで現行方式と比較できます。

## 想定用途

- スマートフォンで撮影した野球、ゴルフなどのハイライト抽出
- 家族映像から自動的に動画アルバムを作成
- 防犯カメラ映像のイベント検索
- 銃声、打撃音、拍手など、音を起点にした映像区間の抽出
- 字幕付き番組の内容理解と場面検索
- 長時間の個人映像をクラウド料金なしでローカル整理

## 現在の到達点

- LM Studio + `gemma4-12b-qat`による完全ローカル推論
- 映像変化・物体・音声信号を統合するオンラインFragment検出
- CUSUM/BOCPD、Adaptive Memory、PELTを使ったScene境界検出
- 複数Fragmentの説明からScene全体をGemmaで要約
- PC AppからWindows映像ファイルを選択
- 静的解析と、映像時刻に同期したリアルタイム解析
- Fragment画像、時刻、説明文、SceneをSQLiteへ関連付け
- RTSP、MPEG-TS、Rockchip MPPへ置換可能な入力層

## 再現可能な基準点

中核実装は[`ai-nas-manager`](https://github.com/fujiokahiroshi/ai-nas-manager)を
Git submoduleとして参照します。このリポジトリの初期基準点は次のコミットです。

```text
6b4e31bb990d301783db1cfdedcee2d7012b31e0
feat: add static and realtime analysis menu
```

取得方法:

```bash
git clone --recursive https://github.com/fujiokahiroshi/gemma-research.git
```

## PC実験環境

### 1. LM StudioをWindowsへ導入

1. [LM Studio公式ダウンロードページ](https://lmstudio.ai/download?os=win32)を開きます。
2. Windows版をダウンロードし、取得したインストーラーを実行します。
3. インストール完了後、LM Studioを起動します。
4. 初回起動時にRuntimeの導入を求められた場合は、推奨される`llama.cpp` Runtimeを導入します。

LM StudioはWindows x64/ARM64に対応しています。この実験環境ではWindows x64版を使用します。
モデルの検索とダウンロード時にはインターネット接続が必要ですが、モデル取得後の推論と
localhost上のAPI処理はローカルだけで実行できます。

### 2. Gemmaモデルを取得

1. 左側の`Discover`を開きます。Windowsでは`Ctrl+2`でも開けます。
2. 検索欄で使用するGemmaモデルを検索します。
3. この実験で使用する12B QATのGGUFモデルを選び、PCのメモリに収まる量子化をダウンロードします。
4. 既にGGUFを持っている場合は、LM Studioへimportして使用できます。

モデル名や配布元は更新される可能性があります。Appから指定するモデル識別名は
`gemma4-12b-qat`に統一します。

### 3. Gemmaをロード

1. `Chat`を開き、画面下部のモデル選択欄を押します。`Ctrl+L`でもモデルローダーを開けます。
2. ダウンロードしたGemma 12B QATを選択します。
3. Load設定でContext Lengthを`16384`にします。
4. Parallel Requestsを`1`にします。
5. GPU Offloadは、VRAMに収まる範囲で最大にします。
6. モデルをロードし、Chatで短い日本語応答が返ることを確認します。

Contextを大きくしすぎるとメモリ使用量と初期処理時間が増えます。複数のFragment画像を扱いながら
安定性を保つため、このPCの基準値をContext `16384`、Parallel `1`としています。

### 4. Local Serverを開始

LM StudioのDeveloperまたはLocal Server画面を開き、サーバーを開始します。
標準の接続先は次の通りです。

```text
http://127.0.0.1:1234
```

LM Studioに含まれる`lms`コマンドを使う場合は、次の操作でも開始できます。

```powershell
lms ls
lms server start
```

別のPowerShellから、OpenAI互換APIが応答することを確認できます。

```powershell
Invoke-RestMethod http://127.0.0.1:1234/v1/models
```

### 5. PC Appを起動

GitHubから初めて取得する場合:

```powershell
git clone --recursive https://github.com/fujiokahiroshi/gemma-research.git
cd gemma-research\ai-nas-manager\ai-nas-manager
.\start_pc_app.ps1
```

このPCの既存作業フォルダから起動する場合:

```powershell
cd "C:\Users\yukik\gemmmaの研究\ai-nas-manager\ai-nas-manager"
.\start_pc_app.ps1
```

ブラウザで`http://127.0.0.1:8788`を開きます。
Appのメニューから映像を選択し、`静的解析を開始`または
`リアルタイム解析を開始`を実行します。

LM Studio公式手順は[Get started with LM Studio](https://lmstudio.ai/docs/app/basics)と
[Download an LLM](https://lmstudio.ai/docs/app/basics/download-model)を参照してください。

## 研究の次段階

- Fragment境界の過分割、見逃し、重複Revisionの削減
- 映像、物体、音、字幕、手動Markerのマルチモーダル統合
- Scene前半の情報を失わない意味メモリ
- Precision、Recall、F1、検出遅延、推論負荷の同時評価
- Rockchip MPP/RGAによるハードウェアデコード入力

## 公開しないローカルデータ

SQLiteデータベース、ユーザー映像、LM Studio/MCPのローカル設定、モデル重み、
生成キャッシュはこのリポジトリへ保存しません。
