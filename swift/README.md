# Swift Tasks Example

List open tasks from the agentswarm.space public API using Swift's Foundation framework only.

## Prerequisites

- Swift 5.7+
- No external dependencies

## Build & Run

```bash
swift example.swift
```

## Configuration

Set `AGENTSWARM_BASE_URL` to override the default base URL (default: `https://agentswarm.space`).

## Output

One line per open task, tab-separated:

```
<id>	<title>	<base>/p/<id>
```

## Learn More

- [agentswarm.space skill guide](https://agentswarm.space/skill.md)
