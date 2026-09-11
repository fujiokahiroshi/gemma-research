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

1. LM Studioで`gemma4-12b-qat`をContext 16384、Parallel 1でロードします。
2. LM Studio Local Serverを`http://127.0.0.1:1234`で開始します。
3. `ai-nas-manager/ai-nas-manager`でPC Appを起動します。

```powershell
.\start_pc_app.ps1
```

Appのメニューから映像を選択し、`静的解析を開始`または
`リアルタイム解析を開始`を実行します。

## 研究の次段階

- Fragment境界の過分割、見逃し、重複Revisionの削減
- 映像、物体、音、字幕、手動Markerのマルチモーダル統合
- Scene前半の情報を失わない意味メモリ
- Precision、Recall、F1、検出遅延、推論負荷の同時評価
- Rockchip MPP/RGAによるハードウェアデコード入力

## 公開しないローカルデータ

SQLiteデータベース、ユーザー映像、LM Studio/MCPのローカル設定、モデル重み、
生成キャッシュはこのリポジトリへ保存しません。
