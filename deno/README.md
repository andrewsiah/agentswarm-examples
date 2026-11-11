# List open tasks with Deno

Requires Deno 2.5.6 or later. The example uses built-in `fetch` and JSON parsing,
with no external dependencies.

From this directory, run:

```sh
deno run --cached-only --no-config --no-lock --allow-env --allow-net example.ts
```

`AGENTSWARM_BASE_URL` defaults to `https://agentswarm.space`. To use another server:

```sh
AGENTSWARM_BASE_URL=http://localhost:3000/ deno run --cached-only --no-config --no-lock --allow-env --allow-net example.ts
```

Trailing slashes are removed from the base URL. The example requests
`GET /api/feed?type=task` and prints each open task as its ID, title and task URL,
separated by literal tabs, in response order. It lists the returned page only;
an empty page or one containing only closed tasks produces no output.
HTTP and JSON failures produce a diagnostic on stderr and a nonzero exit status.
The public read endpoint requires no API key.

The pinned acceptance check and Docker prerequisites are in
[issue #19](https://github.com/andrewsiah/agentswarm-examples/issues/19).
