# `async` / `.await` 入門！

`async/.await`は通常の同期コードの用に見える非同期関数を作成するための Rust のビルドインツールです。 `async`はコードブロックを`Future`トレイトを実装しているステートマシンに変換するものです。 一方、同期メソッドでブロッキング関数を呼び出すとスレッド全体がブロックされてしまいますが、ブロックされた`Future`はスレッドの制御をもたらし、他の`Future`を実行できるようにします。

非同期関数を作成するには次の`async fn`構文を使用できます。

```rust
async fn do_something() { ... }
```

`async fn`によってこの関数の返り値は`Future`になります。
`Future`は次のようにエグゼキューターで実行する必要があります。

```rust
{{#include ../../examples/01_04_async_await_primer/src/lib.rs:hello_world}}
```

`async fn`内では`.await`を使うことで、ほかの`Future`トレイトを実装する別の型の完了を待つことができます。`block_on`とは異なり、`.await`は現在のスレッドをブロックしません、代わりに、`Future`が完了するのを非同期で待機し、`Future`が現在進行できないときは他のタスクを実行できるようにします。

例として、3 つの`async fn`を考えてみましょう。`learn_song`, `sing_song`, `dance`です。

```rust
async fn learn_song() -> Song { ... }
async fn sing_song(song: Song) { ... }
async fn dance() { ... }
```

歌、学習、ダンスを行う方法の一つは、それぞれ個別にブロックすることです。

```rust
{{#include ../../examples/01_04_async_await_primer/src/lib.rs:block_on_each}}
```

ただ、この方法では最高のパフォーマンスを実現しているわけではありません。一つのことしか実行してないからね！

明らかに、歌を歌うには歌を学ぶ必要があります。しかし、歌を学んだあとに歌うのと、同時に踊ることも可能ですよね？

これを行うには、同時に実行できる 2 つの独立した`async fn`を作ることです。

```rust
{{#include ../../examples/01_04_async_await_primer/src/lib.rs:block_on_main}}
```

この例では、歌を歌う前に歌を学習する必要がありますが、詩を学ぶと同時に踊ることもできます。 `learn_and_sing`で`learn_song().await`ではなく`block_on(learn_son())`を使ってしまうと、スレッドはしばらくの間他のことを行うことができなくなり、同時に踊ることを不可能にします。

今学習した、`async / await` の例を試してみましょう！
