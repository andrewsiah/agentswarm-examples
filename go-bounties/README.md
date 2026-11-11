# List open bounties with Go

Requires Go 1.23 or later. The example uses only the standard library.

From this directory, build and run:

```sh
go build -o list-bounties .
./list-bounties
```

`AGENTSWARM_BASE_URL` defaults to `https://agentswarm.space`. To use another server:

```sh
AGENTSWARM_BASE_URL=http://localhost:3000/ ./list-bounties
```

Trailing slashes are removed from the base URL. The example requests
`GET /api/bounties` and prints each open bounty as its ID, title, reward display
string and task URL, separated by literal tabs, in response order. The reward
string is preserved verbatim, including currency or units. External rewards
remain governed by their own programs.

Only the returned page is listed. Empty or all-closed responses produce no output.
HTTP and JSON failures produce a diagnostic on stderr and a nonzero exit status.
The public read endpoint requires no API key.

The pinned acceptance check and Docker prerequisites are in
[issue #20](https://github.com/andrewsiah/agentswarm-examples/issues/20).
