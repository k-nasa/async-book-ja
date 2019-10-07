# エグゼキューターを書いてみよう

Rust の`Future`は怠け者です。積極的に完了しない限り、何もしてくれません。
future を完了させるための一つの方法は`async`関数内の`.await`です。
それは問題は 1 レベル上に押し上げるだけです。トップレベルの非同期関数から返された future を誰が実行しますか？
`Future`のエグゼキューターが必要です。

`Future`エグゼキューターは、トップレベルの`Future`セットを取得し、`Future`が進行するたびに`poll`を呼び出すことにより、それらを完了まで実行します。

通常、エグゼキューターは future を一回`poll`して開始します。`Future`が`wake()`を呼び出して進行する準備ができたことを示すと、それらはキューに戻され、`poll`が再度呼び出され、`Future`が完了するまで繰り返されます。

このセクションでは、多数のトップレベル future を同時に実行できる、独自のシンプルなエグゼキューターを作成していきます。

この例では、`Waker`を構築する簡単な方法を提供する`ArcWake`トレイトの future クレートに依存しています。

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

この設計では、エグゼキューター自体にタスクチャネルの受信側が必要です。ユーザーは新しい future を作成できるように送信側を取得します。タスク自体は自分自身を再スケジュールする future です。
したがって、タスク自体をリキューするために使用できる送信者とペアになった future として保存します。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:executor_decl}}
```

また、spawner にメソッドを追加して、新しい future を簡単に生成できるようにします。このメソッドは future の型を取得し、それを box 化して`FutureObj`に入れ、その中にエグゼキューターにエンキューできる新しい`Arc<Task>`を作成します。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:spawn_fn}}
```

future を poll するには`Waker`を作成する必要があります。[Waker の章](./03_wakeups.md)でも説明したように`Waker`は`wake()`が呼び出された時に再度ポーリングされるタスクをスケジュールする責任があります。`Waker`はどのタスクが準備完了になったかをエグゼキューターに正確に伝え、準備ができている future だけをポーリングできることを忘れないでください。新しい`Waker`を作成する簡単な方法は`ArcWake`トレイトを実装し、`waker_ref`または`.into_waker()`関数を使用して`Arc<impl ArcWake>`を`Waker`に変更することです。タスクに`ArcWake`を実装してタスクを`Waker`に変えて目覚めさせてみましょう。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:arcwake_for_task}}
```

`Arc<Task>`から`Waker`が作成された時に`wake()`を呼び出すと、Arc のコピがタスクチャネルに送信されます。次に、エグゼキューターがタスクを取得してポーリングする必要があります。それを実装しましょう。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:executor_run}}
```

おめでとう！future エグゼキューターが出来ました！これを使用して、`async / .await`コードと先程書いた`TimerFuture`などのカスタム future を実行することが出来ます。

```rust
{{#include ../../examples/02_04_executor/src/lib.rs:main}}
```
