#!/usr/bin/env python3
"""
CCDC Discord Alert Script
Sends intrusion detection alerts with rate limiting and deduplication.

USAGE:
    discord_alert.py --webhook URL --severity critical --message "Alert text" --host hostname

FEATURES:
    - Rate limiting via lockfile timestamps
    - Alert deduplication via content hash
    - Severity levels (critical, warning, info)
    - Evidence file attachment support
"""

import argparse
import hashlib
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError

CACHE_DIR = Path("/var/cache/ccdc_alerts")
COOLDOWN_FILE = CACHE_DIR / "last_alert_{severity}_{hash}.json"
DEFAULT_COOLDOWN = 300  # 5 minutes

SEVERITY_EMOJI = {
    "critical": "🚨",
    "warning": "⚠️",
    "info": "ℹ️"
}


def ensure_cache_dir():
    """Create cache directory if it doesn't exist."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def get_alert_hash(message: str, host: str) -> str:
    """Generate hash for alert deduplication."""
    content = f"{host}:{message}"
    return hashlib.sha256(content.encode()).hexdigest()[:12]


def should_send_alert(severity: str, alert_hash: str, cooldown: int) -> bool:
    """Check if enough time has passed since last identical alert."""
    ensure_cache_dir()
    lockfile = Path(str(COOLDOWN_FILE).format(severity=severity, hash=alert_hash))
    
    if not lockfile.exists():
        return True
    
    try:
        with open(lockfile, 'r') as f:
            data = json.load(f)
            last_sent = data.get('timestamp', 0)
            
        if time.time() - last_sent > cooldown:
            return True
        
        print(f"Alert suppressed (cooldown active, {cooldown - int(time.time() - last_sent)}s remaining)", 
              file=sys.stderr)
        return False
    except Exception as e:
        print(f"Warning: Could not read lockfile: {e}", file=sys.stderr)
        return True


def record_alert(severity: str, alert_hash: str):
    """Record alert timestamp for rate limiting."""
    ensure_cache_dir()
    lockfile = Path(str(COOLDOWN_FILE).format(severity=severity, hash=alert_hash))
    
    try:
        with open(lockfile, 'w') as f:
            json.dump({
                'timestamp': time.time(),
                'datetime': datetime.now().isoformat()
            }, f)
    except Exception as e:
        print(f"Warning: Could not write lockfile: {e}", file=sys.stderr)


def send_discord_alert(webhook_url: str, severity: str, message: str, 
                       host: str, details: str = None) -> bool:
    """Send alert to Discord webhook."""
    emoji = SEVERITY_EMOJI.get(severity, "📢")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    content = f"{emoji} **{severity.upper()}: Intrusion Detection Alert**\n"
    content += f"**Host:** `{host}`\n"
    content += f"**Event:** {message}\n"
    content += f"**Time:** {timestamp}\n"
    
    if details:
        content += f"**Details:**\n```\n{details[:500]}\n```"
    
    payload = {"content": content}
    
    try:
        req = Request(
            webhook_url,
            data=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        
        with urlopen(req, timeout=10) as response:
            # Some HTTPResponse implementations expose getcode(), others expose status.
            status = None
            try:
                status = response.getcode()
            except Exception:
                status = getattr(response, 'status', None)

            if status in [200, 204]:
                print(f"Alert sent successfully (status: {status})")
                return True
            else:
                print(f"Alert failed (status: {status})", file=sys.stderr)
                return False
                
    except URLError as e:
        print(f"Network error sending alert: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Send CCDC intrusion alerts to Discord")
    parser.add_argument("--webhook", required=True, help="Discord webhook URL")
    parser.add_argument("--severity", choices=["critical", "warning", "info"], 
                       default="warning", help="Alert severity level")
    parser.add_argument("--message", required=True, help="Alert message")
    parser.add_argument("--host", required=True, help="Hostname where event occurred")
    parser.add_argument("--details", help="Additional details (logs, commands, etc.)")
    parser.add_argument("--cooldown", type=int, default=DEFAULT_COOLDOWN,
                       help="Cooldown period in seconds (default: 300)")
    parser.add_argument("--force", action="store_true",
                       help="Bypass rate limiting and send immediately")
    
    args = parser.parse_args()
    
    # Generate alert hash for deduplication
    alert_hash = get_alert_hash(args.message, args.host)
    
    # Check rate limiting (unless forced)
    if not args.force:
        if not should_send_alert(args.severity, alert_hash, args.cooldown):
            sys.exit(0)  # Not an error, just suppressed
    
    # Send alert
    if send_discord_alert(args.webhook, args.severity, args.message, 
                          args.host, args.details):
        record_alert(args.severity, alert_hash)
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()