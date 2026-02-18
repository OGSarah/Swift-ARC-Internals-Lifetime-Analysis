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

## 1. Lifetime Logging Foundation
A `TrackedObject` base class logs `init` and `deinit` events, making object lifetimes observable.

Concepts explored:
- Deterministic deallocation
- ARC behavior under reference changes
- When exactly is `deinit` is invoked

### What is deterministic deallocation? 
Unlike languages with a garbage collector (e.g., Java, Python, C#), Swift deallocates an object immediately when it's last reference is gone.
Traditional GC is non-deterministic, meaning objects are cleared "whenever the collection runs".

ARC does not use a background thread to scan memory. The code to increment or decrement counts is inserted by the compiler at compile time.

## 2. Retain Cycles & Object Graphs

## 3. Closure Capture Semantics

## 4. Async Lifetime Extension

## 5. Mini Retain Graph Inspector
