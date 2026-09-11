// Date: Thu Sep 11 2026

// Project: Learning Chapter 15
// Goal: Using Smart Pointer: ...
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

use crate::List::{Cons, Nil};

fn main() {
    println!("\n");

    let list_one: List = Cons(
        1,
        Box::new(Cons(
            2,
            Box::new(Cons(3, Box::new(Cons(4, Box::new(Cons(5, Box::new(Nil))))))),
        )),
    );

    // Reading first member fo list_one
    // ---------------------------------------------------------------
    match list_one {
        Cons(field_one, field_two) => {
            println!("value of field_one is: {}", field_one);
            println!("value of field_two is: {:p}", field_two.as_ref());
        }
        Nil => println!("Nil"),
    }
    // ---------------------------------------------------------------

    println!("\nThe End ...\n");
}

enum List {
    Cons(i32, Box<List>),
    Nil,
}
