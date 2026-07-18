---
name: "x-twitter-data"
description: "Use when the user needs X/Twitter data workflows with Xquik: tweet search, user lookup, follower or reply extraction, media downloads, monitors, webhooks, MCP setup, or confirmation-gated write actions."
version: "1.0.0"
author: "Xquik"
category: "analysis"
triggers:
  - "search X or Twitter posts"
  - "extract followers, replies, reposts, quotes, likes, or media"
  - "monitor X accounts or keywords"
  - "set up Xquik webhooks or MCP"
  - "post, reply, like, repost, follow, DM, or upload media through Xquik"
---

# X/Twitter Data With Xquik

## Trigger Conditions

Use this skill when the task involves:

- Searching or reading public X/Twitter posts, profiles, followers, replies, quotes, reposts, likes, communities, lists, media, Spaces, or trends.
- Creating extraction jobs for follower, reply, repost, quote, like, list, community, media, or tweet-search data.
- Creating account or keyword monitors and receiving signed webhook events.
- Connecting an agent or tool to Xquik through REST, MCP, OpenAPI, or an official SDK.
- Preparing a write action such as posting, replying, liking, reposting, following, sending DMs, uploading media, updating a profile, or managing community membership.

Do not use this skill for generic social-media copywriting when the task does not need Xquik data, Xquik automation, or Xquik integration guidance.

## Dependencies

- A Xquik account: https://docs.xquik.com
- A user-issued Xquik API key for authenticated REST or MCP API calls.
- Optional: the installable upstream Xquik skill package for deeper references:
  `npx skills@1.5.19 add Xquik-dev/x-twitter-scraper`

Never ask for X passwords, 2FA codes, cookies, session tokens, recovery codes, or browser exports.

## Execution Steps

1. Classify the request as read-only data, extraction, monitor/webhook, MCP/API setup, SDK usage, or write action.
2. For read-only data, prefer the narrowest endpoint or workflow that returns the requested resource.
3. For extraction jobs, identify the extraction type, source URL or ID, output shape, and pagination or completion needs.
4. For monitors and webhooks, capture the monitored account or keyword, event types, callback URL, and signature-verification requirement.
5. For MCP or SDK setup, point the user to the public docs and avoid placing secrets in command arguments, logs, issues, or examples.
6. For write actions, require explicit confirmation of target account, action, audience, content, and media before proceeding.
7. If the task is ambiguous, ask for the minimum missing identifier: tweet URL/ID, user handle/ID, list/community URL, query, or webhook URL.

## Output Format

Return a compact implementation plan:

```markdown
## Xquik Plan
- Goal:
- Mode: read-only | extraction | monitor | webhook | MCP | SDK | write-action
- Inputs needed:
- Recommended endpoint or workflow:
- Safety checks:
- Next command or code step:
```

For write actions, include this confirmation block before any action:

```markdown
## Confirmation Required
- Account:
- Action:
- Content:
- Audience:
- Media:
```

## Safety Rules

- Do not request or store X login material.
- Do not print API keys or webhook secrets.
- Do not put API keys in shell history, command arguments, issue text, or generated docs.
- Do not execute write actions without explicit user confirmation.
- Treat webhook secrets as one-time values that must be stored securely by the user.
- Summarize private account or billing details instead of copying raw sensitive values.

## Examples

User: "Find recent tweets about my launch and export the replies."

Output:

```markdown
## Xquik Plan
- Goal: Search launch tweets and collect replies.
- Mode: extraction
- Inputs needed: Search query, reply source tweet URL or ID, output format.
- Recommended endpoint or workflow: Tweet search first, then reply extraction for selected tweets.
- Safety checks: Read-only. No X login material needed.
- Next command or code step: Use the Xquik API key from a secure environment variable.
```

User: "Post this announcement from our account."

Output:

```markdown
## Confirmation Required
- Account: Confirm the connected X account.
- Action: Create tweet.
- Content: Confirm final tweet text.
- Audience: Public timeline.
- Media: Confirm attached media or none.
```
