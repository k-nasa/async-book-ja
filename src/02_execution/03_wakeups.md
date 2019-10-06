# タスクを起こせ！Waker！

`Future`は最初に`poll`された時に完了できないことがよくあります。これが発生した時、`Future`はさらに前進する準備ができたら再度ポーリングされるようにする必要があります。
これは`Waker`型で行われます。

`Future`がポーリングされるたびに、「タスク」の一部としてポーリングされます。
タスクは、エグゼキューターに送信されたトップレベルの`Future`です。

`Waker`は関連付けられたタスクを起動する必要があることをエグゼキューターに伝えるために使用できる`wake()`メソッドを提供します。

`wake()`が呼び出された時、エグゼキューターは、`Waker`と関連するタスクが進む準備が出来たことを知っています。そして、再びポーリングする必要があることも。

`Waker`は`clone()`も実装しているため、コピーして保存することが出来ます。

`Waker`を使用して単純なタイマーを実装してみましょう！

## タイマー作成

この例では、タイマーが作成された時に新しいスレッドを立て、必要な時間だけスリープし、時間経過した時にタイマーの`Future`を通知します。

必要なインポートは次のとおりです。

```rust
{{#include ../../examples/02_03_timer/src/lib.rs:imports}}
```

`Future`の型自体を定義するところからです。

Let's start by defining the future type itself. Our future needs a way for the
thread to communicate that the timer has elapsed and the future should complete.
We'll use a shared `Arc<Mutex<..>>` value to communicate between the thread and
the future.

```rust
{{#include ../../examples/02_03_timer/src/lib.rs:timer_decl}}
```

Now, let's actually write the `Future` implementation!

```rust
{{#include ../../examples/02_03_timer/src/lib.rs:future_for_timer}}
```

Pretty simple, right? If the thread has set `shared_state.completed = true`,
we're done! Otherwise, we clone the `Waker` for the current task and pass it to
`shared_state.waker` so that the thread can wake the task back up.

Importantly, we have to update the `Waker` every time the future is polled
because the future may have moved to a different task with a different
`Waker`. This will happen when futures are passed around between tasks after
being polled.

Finally, we need the API to actually construct the timer and start the thread:

```rust
{{#include ../../examples/02_03_timer/src/lib.rs:timer_new}}
```

Woot! That's all we need to build a simple timer future. Now, if only we had
an executor to run the future on...
