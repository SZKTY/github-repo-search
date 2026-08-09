# GitHubRepoSearch

GitHubリポジトリ検索iOSアプリ。

## 動作環境

- iOS 16.0+
- Xcode 26.5 / Swift 6

## ビルド方法

```sh
git clone https://github.com/SZKTY/github-repo-search.git
cd github-repo-search
open App.xcworkspace
```

`App` スキームを選択してRun。外部ライブラリは使用していないため、追加のセットアップは不要です。

※ パッケージの解決を `App.xcworkspace` に任せる構成のため、`App.xcodeproj` 単体ではなく必ずワークスペースから開いてください。

## テスト

Xcodeで `App` スキームのTest、またはCLIで:

```sh
xcodebuild test -workspace App.xcworkspace -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## アーキテクチャ

MVVM + レイヤー分割によるマルチモジュール構成。

```
github-repo-search/
├── App.xcworkspace   … ワークスペース(App.xcodeproj + Packageを統合) ←これを開く
├── App.xcodeproj     … プロジェクトファイル
├── App/iOS/          … エントリポイント・画面遷移の合成のみ
└── Package/          … 機能はすべてここ(ローカルSwift Package)
    ├── Sources/
    │   ├── Scene/    … 画面単位のモジュール(View + ViewModel)
    │   └── Core/     … UIに依存しないモジュール
    └── Tests/        … モジュール単位のユニットテスト
```

- 依存方向は Scene → Core の一方向。Scene同士は依存させず、画面遷移はAppシェルが合成する
- 新しい画面は `Sources/Scene/<Name>` にモジュールとして追加する
