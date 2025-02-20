# HTTP FILTER

**HTTP FILTER** is a fast and efficient Bash tool designed to automate HTTP response code analysis. It is tailored for security researchers, penetration testers, and bug bounty hunters. The tool processes URLs—either individually or from a list—concurrently, categorizing them into separate files based on their HTTP status codes (e.g., `200.txt`, `404.txt`, `500.txt`).

---

## Features

- **Concurrent Processing**: Uses `xargs` to process up to 10 URLs in parallel for speed.
- **Customizable Timeout**: Adjust request timeouts with the `-t` option (default: 10s).
- **Retry Mechanism**: Retry failed requests with the `-r` option (default: 0 retries).
- **Verbose Mode**: Display response times with the `-V` flag for performance insights.
- **Error Handling**: Validates URLs and input files, with clear error messages.
- **Summary Report**: Provides a summary of results after processing a list.
- **Organized Output**: Saves results in a timestamped directory to avoid overwriting.

---

## Installation

1. Ensure you have Bash (4.0+) and `curl` installed on your system.
2. Clone or download this repository:
   ```bash
   git clone https://github.com/yourusername/http-filter.git

##Make the script executable:
chmod +x http_filter.sh
