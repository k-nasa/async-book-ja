# エグゼキューターを書いてみよう

Rustの`Future`は怠け者です。積極的に完了しない限り、何もしてくれません。
futureを完了させるための一つの方法は`async`関数内の`.await`です。
それは問題は1レベル上に押し上げるだけです。トップレベルの非同期関数から返されたfutureを誰が実行しますか？
`Future`のエグゼキューターが必要です。

`Future`エグゼキューターは、トップレベルの`Future`セットを取得し、`Future`が進行するたびに`poll`を呼び出すことにより、それらを完了まで実行します。

通常、エグゼキューターはfutureを一回`poll`して開始します。`Future`が`wake()`を呼び出して進行する準備ができたことを示すと、それらはキューに戻され、`poll`が再度呼び出され、`Future`が完了するまで繰り返されます。

このセクションでは、多数のトップレベルfutureを同時に実行できる、独自のシンプルなエグゼキューターを作成していきます。

この例では、`Waker`を構築する簡単な方法を提供する`ArcWake`トレイトのfutureクレートに依存しています。

```toml
[package]
name = "xyz"
version = "0.1.0"
authors = ["XYZ Author"]
edition = "2018"

[dependencies]
futures-preview = "=0.3.0-alpha.17"
```

次に、`src/main.rs`の先頭に次のインポートが必要です。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:imports}}
```

エグゼキューターはチャネルを介して実行するタスクを送信することで動作します。エグゼキューターはチャネルからイベントを取得して実行します。タスクがより多くの作業をする準備ができた時に(起こされた時)、タスクをチャネルに戻すことにより、再度ポーリングされるようにスケジュールできます。

この設計では、エグゼキューター自体にタスクチャネルの受信側が必要です。ユーザーは新しいfutureを作成できるように送信側を取得します。タスク自体は自分自身を再スケジュールするfutureです。
したがって、タスク自体をリキューするために使用できる送信者とペアになったfutureとして保存します。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:executor_decl}}
```

また、spawnerにメソッドを追加して、新しいfutureを簡単に生成できるようにします。このメソッドはfutureの型を取得し、それをbox化して`FutureObj`に入れ、その中にエグゼキューターにエンキューできる新しい`Arc<Task>`を作成します。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:spawn_fn}}
```

futureをpollするには`Waker`を作成する必要があります。[Wakerの章](./03_wakeups.md)でも説明したように`Waker`は`wake()`が呼び出された時に再度ポーリングされるタスクをスケジュールする責任があります。`Waker`はどのタスクが準備完了になったかをエグゼキューターに正確に伝え、準備ができているfutureだけをポーリングできることを忘れないでください。新しい`Waker`を作成する簡単な方法は`ArcWake`トレイトを実装し、`waker_ref`または`.into_waker()`関数を使用して`Arc<impl ArcWake>`を`Waker`に変更することです。タスクに`ArcWake`を実装してタスクを`Waker`に変えて目覚めさせてみましょう。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:arcwake_for_task}}
```

`Arc<Task>`から`Waker`が作成された時に`wake()`を呼び出すと、Arcのコピがタスクチャネルに送信されます。次に、エグゼキューターがタスクを取得してポーリングする必要があります。それを実装しましょう。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:executor_run}}
```

おめでとう！futureエグゼキューターが出来ました！これを使用して、`async / .await`コードと先程書いた`TimerFuture`などのカスタムfutureを実行することが出来ます。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:main}}
```
