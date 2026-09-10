// Date: Thu Sep 10 2026

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

fn main() {
    println!("\n");

    let my_number: Box<Box<i32>> = Box::new(Box::new(391));

    // my_number dereferences automatically
    println!("Auto: value of my_number is: {}", my_number);

    // my_number dereferences manually
    println!("Non-Auto: value of my_number is: {}", **my_number);

    println!("\nThe End ...\n");
}
