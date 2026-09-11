// Date: Thu Sep 11 2026

// Project: Learning Chapter 15
// Goal: Using Smart Pointer: Using Box for Recursive Type
// Dependency: Without dependency

// rustc 1.100.0-nightly (cea272fa3 2026-09-07)
// binary: rustc
// commit-hash: cea272fa356e94bd2ee2cadf376630aa0683867a
// commit-date: 2026-09-07
// host: x86_64-unknown-linux-gnu
// release: 1.100.0-nightly
// LLVM version: 23.1.1

// cargo 1.100.0-nightly (3c0b53475 2026-09-04)
// release: 1.100.0-nightly
// commit-hash: 3c0b534756e166d12eb9fd2e1abfe5b42ac6101e
// commit-date: 2026-09-04
// host: x86_64-unknown-linux-gnu
// libgit2: 1.9.6 (sys:0.21.0 vendored)
// libcurl: 8.21.0-DEV (sys:0.4.90+curl-8.21.0 vendored ssl:OpenSSL/3.6.3)
// ssl: OpenSSL 3.6.3 9 Jun 2026
// os: Fedora 44.0.0 [64-bit]

// Kernel Version: 7.1.13-200.fc44.x86_64
// Firmware Version: 71CN51WW(V1.21)

use List::{Cons, Nil};

fn main() {
    println!("\n");

    let my_list = Cons(1, Box::new(Cons(2, Box::new(Cons(3, Box::new(Nil))))));
    println!("value of my_list is: {:?}", my_list);

    println!("\nThe End ...\n");
}

// recursive type
#[derive(Debug)]
enum List {
    Cons(i32, Box<List>),
    Nil,
}
