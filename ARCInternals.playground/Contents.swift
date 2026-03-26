import Foundation
import PlaygroundSupport

/// Keeps the playground process alive, but it does not affect ARC behavior.
PlaygroundPage.current.needsIndefiniteExecution = true

/// # Module 1: Lifetime Logging Foundation
/// Goal: See object allocation and deallocation clearly.

/// Base class
class TrackedObject {
    let id: String

    init(id: String) {
        self.id = id
        print("INIT:", id)
    }

    deinit {
        print("DEINIT:", id)
    }

}

/// A new `TrackedObject` is created.
/// It's reference count becomes 1 (held by `object`)
var object: TrackedObject? = TrackedObject(id: "A")

/// The strong reference is removed.
/// Reference count becomes 0.
/// ARC immediately deallocates the instance.
/// `deinit` runs right away when the references drop to zero
object = nil

/// # Module 2: Retain Cycles & Object Graphs
/// Goal: Understand how reference counts change

/// Build a small object graph
class Person: TrackedObject {
    var pet: Pet?
}

class Pet: TrackedObject {

    /// Fix for strong reference
    /// Now you will see deinit printed in the debug console for both `Sarah` and `Rachel`
    weak var owner: Person?
    // var owner: Person?
}

/// Reference counts are now `Sarah -> 1`, `Rachel -> 1`
var sarah: Person? = Person(id: "Sarah")
var rachel: Pet? = Pet(id: "Rachel")

/// Link them
/// Now `sarah.pet` strongly references `rachel`.
/// `rachel.owner` strongly references `sarah`
/// Now the reference count becomes:
/// `Sarah` total 2, 1 from `sarah`, 1 from`rachel.owner`
/// `Rachel` total 2, 1 from `rachel`, 1 from `sarah.pet`

sarah?.pet = rachel
rachel?.owner = sarah

/// Remove external references.
/// After `sarah = nil`, `Sarah` loses 1 reference, still has 1 reference from `rachel.owner`
/// After `rachel = nil`, `Rachel` loses 1 reference, still has 1 reference from `sarah.pet`
sarah = nil
rachel = nil

/// They are holding each other alive
/// Since neither reaches zero:
/// - `deinit` never runs
/// - Memory is never freed
/// - You have a memory leak

/// # Module 3: Closure Capture Deep Dive
///  Goal: Understand closure memory semantics

/// Basic case with memory leak
/* class ClosureHolder: TrackedObject {
    var action: (() -> Void)?

    func setup() {
        action = {
            print("Action from", self.id)
        }
    }
}

/// Test
/// /// `holder` strongly owns `action
/// `action` closure strongly captures `self`
var holder: ClosureHolder? = ClosureHolder(id: "Holder")
holder?.setup()

/// `holder` still has 1 strong reference from the closure.
holder = nil
/// So the reference count never reaches 0
/// `deinit` never runs
/// This is a memory leak.
*/

/*
/// Fixed without memory leak
/// Now:
///  Closure holds `self` weakly
///  No retain cycle
///  `deinit` runs correctly
class ClosureHolder: TrackedObject {
    var action: (() -> Void)?

    func setup() {
        action = { [weak self] in
            guard let self else { return }
            print("Action from", self.id)
        }
    }
}

/// Test fix
var holder: ClosureHolder? = ClosureHolder(id: "Holder")
holder?.setup()
holder = nil
*/

/// Intentional crash with `unowned self`
/*class ClosureHolder: TrackedObject {
    var action: (() -> Void)?

    func setup() {
        action = { [unowned self] in
            print("Action from", self.id)
        }
    }
}

/// Test
var holder: ClosureHolder? = ClosureHolder(id: "Holder")
holder?.setup()

let savedAction = holder?.action
holder = nil /// deallocates `Holder`
savedAction?() /// Crashes here with `Fatal error: Attempted to read an unowned reference but object 0x600000c36400 was already deallocated`
*/

/// Module 4: Async Lifetime Traps
/// Goal: Understand lifetime extension in async contexts.

/// Case 1: Strong Capture in DispatchQueue - lifetime extension
class AsyncWorker: TrackedObject, @unchecked Sendable {
    func startWork() {
        /// The closure strongly captures `self.
        /// Even if the external `worker` reference is set to nil, the DispatchQueue holds a strong reference to `self` until the block finishes.
        /// ARC will NOT deallocate the object until the queued block completes.
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            print("Working from:", self.id)
            /// `self` is alive here because the closure retains it.
            /// `deinit` will run AFTER this block executes, not when `worker = nil` is called.
        }
    }
}

print("\n--- Module 4: Async Lifetime Extension ---")
var worker: AsyncWorker? = AsyncWorker(id: "Worker-A")
worker?.startWork()

/// This does NOT immediately deallocate Worker-A.
/// The DispatchQueue block still holds a strong reference.
/// deinit will run ~2 seconds later, after the block finishes.
worker = nil
print("worker = nil - but Worker-A is still alive (retained by queue block)")
