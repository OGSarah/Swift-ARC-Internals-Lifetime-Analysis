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
