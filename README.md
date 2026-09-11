# Gemma Research

ローカルのGemmaを映像Stream解析バックエンドとして利用し、映像を全フレーム推論せずに
Fragmentへ分割してテキスト化し、Scene単位の意味データベースを構築する研究プロジェクトです。

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
