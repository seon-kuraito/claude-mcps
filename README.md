# Claude MCPs

個人維護的 Claude Code [MCP servers](https://docs.claude.com/en/docs/claude-code/mcp)。這個 repo 保存實際檔案並負責版控，再透過 symlink 掛進 Claude Code 的執行環境。

　

## 運作方式

MCP 的接線方式比較接近 hooks：它不靠掃描目錄探索 server。每個 server 都要先登記在設定裡（user scope 的登記存放在 `~/.claude.json` 的 `mcpServers`，由 `claude mcp` 指令管理），而登記指向的啟動指令可以放在任何位置。本 repo 利用這一點，讓 server 的實際檔案納入版控，同時避開那份會隨使用狀態變動的設定檔：

```
~/Developer/claude-mcps/mcps/<name>/   ← 實際檔案（本 repo）
~/.claude/mcps/<name>                  ← symlink，逐一建立
```

與 claude-skills、claude-hooks 相同，server 是逐一連結的：登記中的指令路徑使用 `~/.claude/mcps/<mcp-name>/…`，再經由 symlink 解析到本 repo；直接安裝或用其他方式登記的第三方 server 不會進入本 repo。

　

### 為什麼不直接版控 `~/.claude.json`？

`~/.claude.json` 是執行階段狀態：Claude Code 會隨使用情境持續改寫它，內容也很靠近私人資料。因此本 repo 沿用 claude-hooks 的「宣告與對照」（declare and compare）做法：

- [`mcp.servers.json`](mcp.servers.json) 宣告 `mcps/` 中每個 server 應如何登記，作為登記方式的參考來源
- 實際設定再以手動方式（或 `claude mcp add`）更新對齊；之後可能加入 check script 協助比對

　

## 使用方式

把 repo 中的 server 連結進 Claude Code 執行環境：

```sh
scripts/link-mcp.sh <mcp-name>
```

`<mcp-name>` 是 server 在 `mcps/` 中的資料夾名。腳本可重複執行：已連結的 server 不會有任何動作，也不會覆蓋任何非自身 symlink 的目標（例如同名的第三方 server）。若 server 附有 `install.sh`，連結後會執行一次，用來安裝相依或建置；這個步驟同樣可重複執行。

　

## 新增 mcp

1. 在 `mcps/<mcp-name>/` 下撰寫 server（資料夾內需包含啟動進入點；需要安裝或建置就附上 `install.sh`）
2. 執行 `scripts/link-mcp.sh <mcp-name>` 讓它出現在 `~/.claude/mcps/`
3. 為 server 撰寫一份自己的 `README.md`，說明用途、來源與授權
4. commit 前確認出處：
   - **原創作品**：採用 MIT 授權
   - **衍生自寬鬆授權的上游**：保留上游授權，並以 `NOTICE` 標明來源、作者與修改內容
   - **來源不明或授權不相容**：不收入本 repo
5. 在 `mcp.servers.json` 宣告它的登記方式
6. 把登記套用到實際設定（使用 `claude mcp add` 或手動編輯）
