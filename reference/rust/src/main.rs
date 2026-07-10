use std::{env, path::PathBuf, process};

fn main() {
    if let Err(message) = run() {
        eprintln!("{message}");
        process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let mut args = env::args().skip(1);
    if args.next().as_deref() != Some("run") {
        return Err("usage: mcb-rust run <fixture> [repo-root]".into());
    }
    let fixture = args
        .next()
        .map(PathBuf::from)
        .ok_or_else(|| "fixture path is required".to_string())?;
    let repo_root = args
        .next()
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("."));
    let report =
        mcb_harness::run_fixture(&repo_root, &fixture).map_err(|error| error.to_string())?;
    println!(
        "{}",
        serde_json::to_string(&report).map_err(|error| error.to_string())?
    );
    Ok(())
}
