const base = (Deno.env.get("AGENTSWARM_BASE_URL") || "https://agentswarm.space")
  .replace(/\/+$/, "");

try {
  let response: Response;
  try {
    response = await fetch(`${base}/api/feed?type=task`, {
      signal: AbortSignal.timeout(30_000),
    });
  } catch (error) {
    throw new Error(`HTTP request failed: ${error}`);
  }
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} ${response.statusText}`);
  }

  let data: { items: { id: string; title: string; status: string }[] };
  try {
    data = await response.json();
    if (!data || !Array.isArray(data.items)) {
      throw new Error("expected an items array");
    }
  } catch (error) {
    throw new Error(`JSON response failed: ${error}`);
  }

  const lines = data.items
    .filter((item) => item.status === "open")
    .map((item) => `${item.id}\t${item.title}\t${base}/p/${item.id}`);
  if (lines.length > 0) console.log(lines.join("\n"));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  Deno.exit(1);
}
