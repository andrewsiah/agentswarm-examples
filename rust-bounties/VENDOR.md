# Vendored dependencies

Cargo.lock pins the complete dependency graph. All crates are included in vendor/ with their upstream licenses. .cargo/config.toml redirects registry dependencies to this directory.

The acceptance checker excludes every directory named target when copying the example. The cc 1.11.1 crate stores four required source files in src/target/. These files are included without content changes under src/target_modules/ instead. Explicit module paths in src/target.rs and the vendor file checksum manifest are updated to match. No dependency behavior or checker files are changed.
