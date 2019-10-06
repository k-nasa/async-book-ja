# Future トレイト

`Future`トレイトはRustの非同期プログラミングの中心人物です。(超重役だぞ!)

`Future`は値を生成できる非同期計算です。(`()`のような空の値の時もあります)

*簡略化した*`Future`トレイトは以下のようになります。


```rust
{{#include ../../examples/02_02_future_trait/src/lib.rs:simple_future}}
```

この`poll`関数を呼び出すことで`Future`を進めることが出来ます、これにより、`Future`が可能な限り完了するようになります。`Future`が完了すると`Poll::Ready(result)`を返し、未完了のときは`Poll::Pending`を返して、`Future`がさらに進む準備ができたときに`wake()`関数が呼び出されるように準備します。

`wake()`が呼び出されると、`Future`を駆動するエグゼキューターが`poll`を再度呼び出し、`Future`を更に進めようとします。


`wakte()`がなければ、エグゼキューターは`Future`がいつ進むかを知る方法がなく、つねにすべての`future`をポーリングする必要があります。`wake()`を使用するkとで、エグゼキューターはどの`Future`を`poll`する準備ができているかを正確に把握できます。

For example, consider the case where we want to read from a socket that may
or may not have data available already. If there is data, we can read it
in and return `Poll::Ready(data)`, but if no data is ready, our future is
blocked and can no longer make progress. When no data is available, we
must register `wake` to be called when data becomes ready on the socket,
which will tell the executor that our future is ready to make progress.
A simple `SocketRead` future might look something like this:

```rust
{{#include ../../examples/02_02_future_trait/src/lib.rs:socket_read}}
```

This model of `Future`s allows for composing together multiple asynchronous
operations without needing intermediate allocations. Running multiple futures
at once or chaining futures together can be implemented via allocation-free
state machines, like this:

```rust
{{#include ../../examples/02_02_future_trait/src/lib.rs:join}}
```

This shows how multiple futures can be run simultaneously without needing
separate allocations, allowing for more efficient asynchronous programs.
Similarly, multiple sequential futures can be run one after another, like this:

```rust
{{#include ../../examples/02_02_future_trait/src/lib.rs:and_then}}
```

These examples show how the `Future` trait can be used to express asynchronous
control flow without requiring multiple allocated objects and deeply nested
callbacks. With the basic control-flow out of the way, let's talk about the
real `Future` trait and how it is different.

```rust
{{#include ../../examples/02_02_future_trait/src/lib.rs:real_future}}
```

The first change you'll notice is that our `self` type is no longer `&mut self`,
but has changed to `Pin<&mut Self>`. We'll talk more about pinning in [a later
section][pinning], but for now know that it allows us to create futures that
are immovable. Immovable objects can store pointers between their fields,
e.g. `struct MyFut { a: i32, ptr_to_a: *const i32 }`. Pinning is necessary
to enable async/await.

Secondly, `wake: fn()` has changed to `&mut Context<'_>`. In `SimpleFuture`,
we used a call to a function pointer (`fn()`) to tell the future executor that
the future in question should be polled. However, since `fn()` is zero-sized,
it can't store any data about *which* `Future` called `wake`.

In a real-world scenario, a complex application like a web server may have
thousands of different connections whose wakeups should all be
managed separately. The `Context` type solves this by providing access to
a value of type `Waker`, which can be used to wake up a specific task.

[pinning]: ../04_pinning/01_chapter.md
