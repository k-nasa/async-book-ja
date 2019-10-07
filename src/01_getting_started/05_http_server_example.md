# HTTP サーバーを書いてみよう!

`async / .await`を使用してエコーサーバーを構築してみましょう！

最初に、`rustup update nightly`で Rust の最新かつ最高のコピーを手に入れてください。
それが完了したら、`cargo +nightly new async-await-echo`を実行して新プロジェクトを作成します。

`Cargo.toml`ファイルにいくつかの依存関係を追加しましょう

```toml
{{#include ../../examples/01_05_http_server/Cargo.toml:9:18}}
```

依存関係を追加したので、コードを書いていきましょう！
追加するインポートがいくつかあります

```rust
{{#include ../../examples/01_05_http_server/src/lib.rs:imports}}
```

次はリクエストを処理できるようにしていきましょう。

```rust
{{#include ../../examples/01_05_http_server/src/lib.rs:boilerplate}}
```

`cargo run`でターミナルに「Listening on http://127.0.0.1:3000」というメッセージが表示されるはずです。
ブラウザでその URL を開くとどうなりますか？ 「hello, world」と見慣れた挨拶が表示されれば順調な証拠です。 おめでとうございます！
Rust で最初の非同期 Web サーバーを作成しました。

また、リクエスト URL、HTTP のバージョン、ヘッダー、その他のメタデータなどの情報を調べることも出来ます。例えば、次のようにリクエストの URL を出力できます。

```rust
println!("Got request at {:?}", req.uri());
```

お気づきかな？すぐにレスポンスを返すため、リクエストを処理する際に非同期処理をまだ行ってないことに。
静的なメッセージを返すのではなく、Hyper の HTTP クライアントを使用して、ユーザーのリクエストを別の WEB サイトにプロキシしてみましょう。

URL を解析することから初めます。

```rust
{{#include ../../examples/01_05_http_server/src/lib.rs:parse_url}}
```

次に、新しく`hyper::Client`を作成し、`GET`リクエストを送りユーザーにレスポンスを返します。

```rust
{{#include ../../examples/01_05_http_server/src/lib.rs:get_request}}
```

`Client::get`は`hyper::client::FutureResponse`を返します。
これは、`Future<Output = Result<Response, Error>>`を実装します。
`.await`するとき、HTTP リクエストが送信され、現在のタスクが一時停止され、レスポンスが利用可能になったらタスクがキューに入れられて続行されます。

`cargo run`をして、`http://127.0.0.1:3000/foo`を開いてみてください、Rust のホームページと以下の出力がターミナルで見れるはずです。

```
Listening on http://127.0.0.1:3000
Got request at /foo
making request to http://www.rust-lang.org/en-US/
request finished-- returning response
```

HTTP リクエストのプロキシに成功しました！！
