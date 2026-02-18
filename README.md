# ARC Internals & Lifetime Analysis Lab

# Overview
This project is a focused exploration of Swift Automatic Reference Counting(ARC) and runtime lifetime behavior. Built as part of a Staff Engineer study plan.

Rather than relying on Instruments or tooling, this playground is designed to build a first-principles mental model of:
- How ARC inserts retain/release calls
- When and why `deinit` executes
- Why retain cycles occur
- Closure capture semantics
- Weak vs unowned tradeoffs
- Async lifetime extension behavior
- Runtime lifetime guarantees in Swift

The goal is to reason about memory deterministically, like the compiler and the runtime do.

# Why this Project Exists
At Staff level, engineers must:
- Predict object lifetimes without trial-and-error-debugging
- Review PRs and immediately spot potential memory leaks
- Design APIs with explicit ownership semantics
- Understand closure capture and escaping semantics deeply
- Architect systems that avoid accidental retain cycles

# Project Structure

## Module 1: Lifetime Logging Foundation
A `TrackedObject` base class logs `init` and `deinit` events, making object lifetimes observable.

Concepts explored:
- Deterministic deallocation
- ARC behavior under reference changes
- When exactly is `deinit` is invoked

### What is deterministic deallocation? 
Unlike languages with a garbage collector (e.g., Java, Python, C#), Swift deallocates an object immediately when it's last reference is gone.
Traditional GC is non-deterministic, meaning objects are cleared "whenever the collection runs".

ARC does not use a background thread to scan memory. The code to increment or decrement counts is inserted by the compiler at compile time.

## Module 2: Retain Cycles & Object Graphs
Builds a bidirectional relationship between objects(e.g., `Person` and `Pet`) to intentionally create retain cycles.

Concepts explored:
- Strong reference cycles
- Why ARC does not detect cycles
- Weak reference semantics
- Zeroing weak implementation behavior

### Why doesn't ARC detect cycles?
Because ARC is local and mechanical: it only knows "how many strong references point to this object right now?"
- ARC increments/decrements a reference count on each object as strong references are created/destroyed.
- Deallocation happens only when the count reaches 0.
- A cycle means each object in the cycle still has at least 1 strong reference (from within the cycle), so none ever hits zero.

Detecting cycles would require ARC to do graph analysis (tracing the object graph to see if a subgraph is unreachable from "roots").
That's what a tracing GC does. ARC intentionally avoids that because it:
- Would add runtime overhead and pauses
- Would require tracking "roots" (stack/global references) and scanning memory
- Complicates deterministic deinit timing (one of ARC's big wins)

So in the `Person <-> Pet` example, ARC is behaving exactly as designed: both refcounts never reach zero, so neither deallocates.

### Why is weak optional?
Because a weak reference can become nil at any time when the referenced object deallocates.

If Swift allowed:

```swift
weak var owner: Person // non-optional
```
then after `Person` dellocates, `owner` would have to contain a value that is not a valid object anymore. That would be unsafe.

So Swift forces `weak` to be:
- `Optional`(`Person?`), because it needs a legal "no value" state, or
- `unowned` (non-optional) *only if you promise it will always be valid while accessed (otherwise app will crash).

That's the rule of thumb:
- **weak**: can become nil -> must be optional
- **unowned**: won't become nil (assumed) -> can be non-optional, but unsafe if assumption is wrong

### What runtime data structure tracks weak references?
At runtime, Swift uses a side table mechanism to track refcounts and weak refs.
Conceptionally there are two buckets:
1. **Inline Refcounting**(fast path): stored in the object header/isa metadata when possible.
2. **Side table entries**(slow path): allocated when the runtime needs extra bookkeeping.

Weak references are tracked in a **weak reference table** (a hash table keyed by the object identity) that stores the set of "weak locations" (addresses of variables/properties)
that currently point to that object.

So conceptually you can think:
```swift
weakTable[ObjectID] = {&rachel.owner, &someOtherWeakVar, ...}
```

### How is "zeroing weak" implemented?
"Zeroing" means: when the object dies, all weak refs that pointed to it are automatically set to nil.

Mechanism:
1. When you assign to a weak variable/property:
   - runtime registers that storage location (the address of the weak slot) in the weak table entry for that object.
2. When the object is about to deinitialize/deallocate:
   - runtime looks up the object in the weak table
   - iterates every registered weak-slot address
   - writes `nil` to each one of these slots
   - removes the weak table entry for that object

That's why, in the example, after:
```swift
rachel?.owner = sarah
sarah = nil
```
`rachel.owner` doesn't become a dangling pointer. When `sarah` deallocates, the runtime proactively writes `nil` into `rachel.owner`

How this relates to Module 2 in the playground:
- With `var owner: Person?` (strong), you create a strong cycle and neither refcount reach 0 -> no `deninit`.
- With `weak var owner: Person?`, the back-edge does not increment Sarah's strong refcount, so you when you set external refs to nil, both can reach 0 and deallocate.
- If you used `unowned var owner: Person`, you'd avoid the cycle too, but if `Pet` outlives `Person`, accessing `owner` would crash.

## Module 3: Closure Capture Deep Dive

## Module 4: Async Lifetime Extension

## Module 5: Mini Retain Graph Inspector
