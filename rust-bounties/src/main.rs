use serde::Deserialize;
use std::{env, io::{self, Read, Write}, time::Duration};

#[derive(Deserialize)]
struct Feed { bounties: Vec<Bounty> }
#[derive(Deserialize)]
struct Bounty {
    id: String,
    title: String,
    status: String,
    bounty: Option<Reward>,
}
#[derive(Deserialize)]
struct Reward { reward: String }

fn run() -> Result<(), String> {
    let base = env::var("AGENTSWARM_BASE_URL").unwrap_or_else(|_| "https://agentswarm.space".into());
    let base = base.trim_end_matches('/');
    let response = ureq::get(&format!("{base}/api/bounties"))
        .timeout(Duration::from_secs(30)).call().map_err(|e| format!("HTTP error: {e}"))?;
    let mut body = Vec::new();
    response.into_reader().read_to_end(&mut body).map_err(|e| format!("HTTP error reading response: {e}"))?;
    let feed: Feed = serde_json::from_slice(&body).map_err(|e| format!("JSON error: {e}"))?;
    let mut output = String::new();
    for item in feed.bounties.into_iter().filter(|item| item.status == "open") {
        let reward = item.bounty.ok_or("JSON error: missing bounty reward")?.reward;
        output.push_str(&format!("{}\t{}\t{}\t{base}/p/{}\n", item.id, item.title, reward, item.id));
    }
    io::stdout().write_all(output.as_bytes()).map_err(|e| format!("Output error: {e}"))
}
fn main() {
    if let Err(error) = run() { eprintln!("{error}"); std::process::exit(1); }
}
