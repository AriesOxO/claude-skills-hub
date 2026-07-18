# x-twitter-data

X/Twitter data workflow guidance for Xquik. Use this skill when Claude needs to plan tweet search, user lookup, follower or reply extraction, media downloads, account monitors, webhooks, MCP setup, SDK usage, or confirmation-gated X write actions.

## Use Cases

- Search public X/Twitter posts and profiles.
- Extract followers, replies, reposts, quotes, likes, community posts, list members, or media.
- Create account or keyword monitors.
- Set up signed webhook delivery.
- Connect agents through Xquik REST, MCP, OpenAPI, or SDKs.
- Prepare write actions with explicit confirmation.

## Install

```bash
csh install x-twitter-data
```

For deeper Xquik references, install the upstream package:

```bash
npx skills@1.5.19 add Xquik-dev/x-twitter-scraper
```

## Configuration

Create a Xquik API key in the Xquik dashboard and store it in a secure secret store or environment variable. Do not paste API keys into prompts, shell history, logs, issues, or generated documentation.

Docs: https://docs.xquik.com

## Example

```text
Search X for posts about this product launch, choose the most relevant posts, and prepare reply extraction jobs.
```

Expected output:

```markdown
## Xquik Plan
- Goal:
- Mode:
- Inputs needed:
- Recommended endpoint or workflow:
- Safety checks:
- Next command or code step:
```

## Category

`analysis`

## Author

Xquik

## License

MIT

Xquik is an independent third-party service. Not affiliated with X Corp. "Twitter" and "X" are trademarks of X Corp.
