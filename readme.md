# 🍪 Cookies Inspector Pro

A lightweight browser extension for inspecting and exporting cookies — including `HttpOnly` and `Secure` cookies that are normally hidden from JavaScript.

## Features

- **Full cookie access** — reads all cookies for the active tab, including `HttpOnly` and `Secure` flags
- **Filter by type** — quickly switch between All, HttpOnly, Secure, or Both flags
- **Live stats** — at-a-glance badges showing cookie counts per category
- **Export to JSON** — download cookies as a timestamped `.json` file
- **Copy to clipboard** — one-click copy of the current filtered view
- **Clean dark UI** — readable monospace preview with smooth toast notifications

## Browser Compatibility

| Browser | Supported | Minimum Version | Notes |
|---|---|---|---|
| Chrome | ✅ | 125 | Primary target, uses Manifest V3 |
| Firefox | ✅ | 109 | Uses `browser.*` API with MV2 manifest |

## Permissions

| Permission | Reason |
|---|---|
| `cookies` | Read all cookies including HttpOnly and Secure |
| `activeTab` | Detect the current tab's URL |
| `tabs` | Query the active tab |
| `<all_urls>` | Access cookies across all domains |

## Output Format

Cookies are exported as a JSON array. Each entry includes:

```json
{
  "name": "session_id",
  "value": "abc123",
  "domain": "example.com",
  "path": "/",
  "secure": true,
  "httpOnly": true,
  "sameSite": "strict",
  "expirationDate": 1735689600,
  "hostOnly": false,
  "session": false,
  "storeId": "0"
}
```

## Usage

1. Navigate to any website
2. Click the extension icon in the toolbar
3. Use the filter buttons to narrow down cookies by type
4. Click **Download JSON** to save, or **Copy** to paste elsewhere

## Notes

- This extension is intended for **development and debugging purposes only**
- Cookie values may contain sensitive session tokens — handle exported files with care


## License

MIT