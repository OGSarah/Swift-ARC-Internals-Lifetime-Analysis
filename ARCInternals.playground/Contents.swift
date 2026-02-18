import Foundation
import PlaygroundSupport

// Keeps the playground process alive, but it does not affect ARC behavior.
PlaygroundPage.current.needsIndefiniteExecution = true

/// Module 1 - Build a Lifetime Logger
/// Goal: See object allocation and deallocation clearly.

// Base class
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

// A new `TrackedObject` is created.
// It's reference count becomes 1 (held by `object`)
var object: TrackedObject? = TrackedObject(id: "A")

// The strong reference is removed.
// Reference count becomes 0.
// ARC immediately deallocates the instance.
// `deinit` runs right away when the references drop to zero
object = nil

