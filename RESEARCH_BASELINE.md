# Research baseline

## Pipeline

```text
MP4 / RTSP / MPEG-TS / Rockchip MPP
  -> hardware/software decode
  -> low-cost visual, object, audio and subtitle signals
  -> online Fragment detection and revision
  -> latest-only Gemma vision queue
  -> timestamped Japanese text
  -> online Scene boundary detection
  -> post-processing PELT
  -> multi-Fragment Scene summary
  -> SQLite media database and PC App
```

## Design principles

1. Gemmaへ全フレームを送らない。
2. Stream終了を待たず、映像継続中にテキストを生成・更新する。
3. Fragment検出と意味推論を分離し、将来のモデル交換を可能にする。
4. 静的解析とリアルタイム解析で同じ検出・意味統合コードを使う。
5. 新アルゴリズムはShadow Modeで現行境界と比較してから採用する。
6. 画像、時刻、Fragmentテキスト、Scene要約の由来を保持する。

## Pinned implementation

- Repository: `fujiokahiroshi/ai-nas-manager`
- Branch at checkpoint: `master`
- Commit: `6b4e31bb990d301783db1cfdedcee2d7012b31e0`
- Local model: `gemma4-12b-qat`
- LM Studio context: `16384`
- LM Studio parallel requests: `1`

## Verified PC App experiment

- Static mode: completed without source-time waiting; produced 3 Fragment records and 2 Scenes.
- Real-time mode: Fragment count increased during playback (`1 -> 2 -> 3 -> 5`), then produced 2 Scenes.
- Both modes used the same object-assisted Fragment and hybrid Scene pipeline.
- A multi-Fragment Scene summary was returned by the local Gemma model.
