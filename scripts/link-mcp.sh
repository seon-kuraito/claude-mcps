#!/usr/bin/env bash
#
# link-mcp.sh — symlink an MCP server from this repo into ~/.claude/mcps so it
# can be registered in the user-scope config via a stable ~/.claude path while
# living here.
#
# Usage: scripts/link-mcp.sh <mcp-name>
#
# Idempotent: re-running is safe. Refuses to overwrite anything it doesn't own
# (e.g. a third-party server of the same name).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_mcps="$(cd "$script_dir/.." && pwd)/mcps"
runtime_mcps="$HOME/.claude/mcps"

name="${1:-}"
if [ -z "$name" ]; then
  echo "usage: link-mcp.sh <mcp-name>" >&2
  exit 1
fi

src="$repo_mcps/$name"
dest="$runtime_mcps/$name"

if [ ! -d "$src" ]; then
  echo "error: mcp server not found in repo: $src" >&2
  exit 1
fi

# Link if needed; converge to the post-link step in every non-error case.
if [ -L "$dest" ]; then
  if [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok: already linked — $name"
  else
    echo "error: $dest already links elsewhere ($(readlink "$dest"))" >&2
    exit 1
  fi
elif [ -e "$dest" ]; then
  # A real file/dir is in the way → refuse to clobber it.
  echo "error: $dest exists and is not a symlink — refusing to overwrite" >&2
  exit 1
else
  mkdir -p "$runtime_mcps"
  ln -s "$src" "$dest"
  echo "linked: $dest -> $src"
fi

# Run the server's own post-link setup if it ships one (idempotent: install
# dependencies, build artifacts, etc.). Keeps link-mcp.sh server-agnostic.
if [ -x "$src/install.sh" ]; then
  "$src/install.sh"
fi
