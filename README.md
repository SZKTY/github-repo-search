# GitHubRepoSearch

GitHub REST API (Search API) を利用したリポジトリ検索iOSアプリ。

## 機能

- キーワードを入力してGitHubリポジトリを検索
- 検索したクエリと総件数を結果ヘッダーに表示
- リポジトリ名・オーナーアバター・説明・スター数・言語をリスト表示
- スクロール末尾で次ページを自動読み込み
- リポジトリ詳細画面(統計・言語・ライセンス表示、GitHubで開く)
- Pull to Refresh
- 通信エラー・レート制限・0件時のハンドリングと再試行
- キーワードをクリアすると検索結果を初期化

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

Xcodeで `App` スキームのTest(⌘U)、またはCLIで:

```sh
xcodebuild test -workspace App.xcworkspace -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

- `APIClientTests` — URLProtocolスタブによるリクエスト検証・実形式フィクスチャのデコード・エラーマッピング
- `RepositorySearchTests` — モック注入によるViewModelの状態遷移・ページネーション・遅延レスポンス競合の検証

## アーキテクチャ

MVVM + レイヤー分割によるマルチモジュール構成。アプリ本体(xcodeproj)とローカルSwift Packageをxcworkspaceで統合する構成です。

```
github-repo-search/
├── App.xcworkspace   … ワークスペース(App.xcodeproj + Packageを統合) ←これを開く
├── App.xcodeproj     … プロジェクトファイル
├── App/iOS/          … エントリポイント・画面遷移の合成のみ
└── Package/          … 機能はすべてここ(ローカルSwift Package)
    ├── Sources/
    │   ├── Scene/    … 画面単位のモジュール
    │   │   ├── RepositorySearch/   検索画面(View + ViewModel)
    │   │   ├── RepositoryDetail/   詳細画面
    │   │   └── Home/               サンプル画面
    │   └── Core/     … UIに依存しないモジュール
    │       ├── APIClient/          GitHub APIクライアント(protocol + URLSession実装)
    │       ├── Entity/             ドメインモデル(Decodable)
    │       └── Logger/             共通ロガー
    └── Tests/        … モジュール単位のユニットテスト
```

- 依存方向は Scene → Core の一方向。Scene同士は依存させず、画面遷移はAppシェルが `navigationDestination` で合成する
- `RepositorySearchClient` をprotocolとしてViewModelに注入し、テストではモックに差し替える
- 新しい画面は `Sources/Scene/<Name>` にモジュールとして追加する
