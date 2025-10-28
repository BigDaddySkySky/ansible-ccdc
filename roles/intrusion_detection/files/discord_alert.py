#!/usr/bin/env python3
"""
CCDC Discord Alert Script - Hardened Edition
Sends intrusion detection alerts with:
- Alert queuing for failed sends
- Atomic file locking (no race conditions)
- Structured logging
- Automatic retry mechanism

USAGE:
    discord_alert.py --webhook URL --severity critical --message "Alert text" --host hostname
    discord_alert.py --retry  # Retry all queued alerts
"""

import argparse
import hashlib
import json
import logging
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# Use filelock for atomic operations
try:
    import fcntl
    HAVE_FCNTL = True
except ImportError:
    HAVE_FCNTL = False
    print("Warning: fcntl not available, using fallback locking", file=sys.stderr)

# Configuration
CACHE_DIR = Path("/var/cache/ccdc_alerts")
QUEUE_DIR = Path("/var/spool/ccdc_alerts")
LOG_DIR = Path("/var/log/ccdc")
COOLDOWN_FILE = CACHE_DIR / "last_alert_{severity}_{hash}.json"
DEFAULT_COOLDOWN = 300  # 5 minutes

SEVERITY_EMOJI = {
    "critical": "🚨",
    "warning": "⚠️",
    "info": "ℹ️"
}

# Setup logging
LOG_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / 'discord_alerts.log'),
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger(__name__)


def ensure_directories():
    """Create required directories if they don't exist."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    QUEUE_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)


def get_alert_hash(message: str, host: str) -> str:
    """Generate hash for alert deduplication."""
    content = f"{host}:{message}"
    return hashlib.sha256(content.encode()).hexdigest()[:12]


def should_send_alert_atomic(severity: str, alert_hash: str, cooldown: int) -> bool:
    """
    Check if alert should be sent using atomic file locking.
    Returns True if alert should be sent, False if suppressed.
    
    Uses fcntl.flock for atomic operations to prevent race conditions.
    """
    ensure_directories()
    lockfile = Path(str(COOLDOWN_FILE).format(severity=severity, hash=alert_hash))
    
    if not HAVE_FCNTL:
        # Fallback to non-atomic check (race condition possible)
        return should_send_alert_fallback(lockfile, cooldown)
    
    try:
        # Open file with O_CREAT | O_RDWR
        fd = os.open(str(lockfile), os.O_RDWR | os.O_CREAT, 0o600)
        
        try:
            # Acquire exclusive lock (blocks if another process has lock)
            fcntl.flock(fd, fcntl.LOCK_EX)
            
            # Read existing timestamp
            os.lseek(fd, 0, os.SEEK_SET)
            content = os.read(fd, 1024).decode('utf-8')
            
            if content:
                try:
                    data = json.loads(content)
                    last_sent = data.get('timestamp', 0)
                    
                    if time.time() - last_sent <= cooldown:
                        elapsed = int(time.time() - last_sent)
                        remaining = cooldown - elapsed
                        logger.info(f"Alert suppressed (cooldown active, {remaining}s remaining)")
                        return False
                except json.JSONDecodeError:
                    logger.warning(f"Corrupted lockfile: {lockfile}, recreating")
            
            # Update timestamp atomically
            new_data = {
                'timestamp': time.time(),
                'datetime': datetime.now().isoformat()
            }
            
            os.lseek(fd, 0, os.SEEK_SET)
            os.ftruncate(fd, 0)
            os.write(fd, json.dumps(new_data).encode('utf-8'))
            
            return True
            
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)
            
    except Exception as e:
        logger.error(f"Lockfile error: {e}, failing open to allow alert")
        return True  # Fail open to avoid missing critical alerts


def should_send_alert_fallback(lockfile: Path, cooldown: int) -> bool:
    """Fallback rate limiting without fcntl (race condition possible)."""
    if not lockfile.exists():
        return True
    
    try:
        with open(lockfile, 'r') as f:
            data = json.load(f)
            last_sent = data.get('timestamp', 0)
            
        if time.time() - last_sent > cooldown:
            return True
        
        remaining = int(cooldown - (time.time() - last_sent))
        logger.info(f"Alert suppressed (cooldown active, {remaining}s remaining)")
        return False
    except Exception as e:
        logger.warning(f"Lockfile read error: {e}, allowing alert")
        return True


def record_alert_fallback(severity: str, alert_hash: str):
    """Fallback alert recording without fcntl."""
    ensure_directories()
    lockfile = Path(str(COOLDOWN_FILE).format(severity=severity, hash=alert_hash))
    
    try:
        with open(lockfile, 'w') as f:
            json.dump({
                'timestamp': time.time(),
                'datetime': datetime.now().isoformat()
            }, f)
    except Exception as e:
        logger.error(f"Failed to record alert: {e}")


def queue_failed_alert(severity: str, message: str, host: str, details: str = None, reason: str = "unknown"):
    """Store failed alert for later retry."""
    ensure_directories()
    
    alert_id = f"{time.time()}_{severity}_{host}_{os.getpid()}"
    alert_file = QUEUE_DIR / f"{alert_id}.json"
    
    try:
        with open(alert_file, 'w') as f:
            json.dump({
                'severity': severity,
                'message': message,
                'host': host,
                'details': details,
                'timestamp': time.time(),
                'datetime': datetime.now().isoformat(),
                'failure_reason': reason,
                'retry_count': 0
            }, f, indent=2)
        
        logger.info(f"Alert queued: {alert_file} (reason: {reason})")
        
    except Exception as e:
        logger.error(f"Failed to queue alert: {e}")


def send_discord_alert(webhook_url: str, severity: str, message: str, 
                       host: str, details: str = None) -> bool:
    """
    Send alert to Discord webhook.
    Returns True on success, False on failure.
    """
    emoji = SEVERITY_EMOJI.get(severity, "📢")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    content = f"{emoji} **{severity.upper()}: Intrusion Detection Alert**\n"
    content += f"**Host:** `{host}`\n"
    content += f"**Event:** {message}\n"
    content += f"**Time:** {timestamp}\n"
    
    if details:
        # Truncate details to avoid Discord's 2000 char limit
        details_truncated = details[:800]
        if len(details) > 800:
            details_truncated += "\n... (truncated)"
        content += f"**Details:**\n```\n{details_truncated}\n```"
    
    # Ensure content doesn't exceed Discord's limit
    if len(content) > 1900:
        content = content[:1900] + "\n... (truncated)"
    
    payload = {"content": content}
    
    logger.info(f"Sending {severity} alert for {host}: {message[:50]}...")
    
    try:
        req = Request(
            webhook_url,
            data=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        
        with urlopen(req, timeout=10) as response:
            # Handle both response types
            status = getattr(response, 'getcode', lambda: getattr(response, 'status', None))()
            
            if status in [200, 204]:
                logger.info(f"Alert sent successfully (status: {status})")
                return True
            elif status == 429:
                logger.warning(f"Rate limited by Discord (status: 429)")
                queue_failed_alert(severity, message, host, details, reason="rate_limited")
                return False
            else:
                logger.error(f"Alert failed with status: {status}")
                queue_failed_alert(severity, message, host, details, reason=f"http_{status}")
                return False
                
    except HTTPError as e:
        logger.error(f"HTTP error: {e.code} - {e.reason}")
        queue_failed_alert(severity, message, host, details, reason=f"http_error_{e.code}")
        return False
    except URLError as e:
        logger.error(f"Network error: {e.reason}")
        queue_failed_alert(severity, message, host, details, reason="network_error")
        return False
    except Exception as e:
        logger.exception(f"Unexpected error sending alert: {e}")
        queue_failed_alert(severity, message, host, details, reason="exception")
        return False


def retry_queued_alerts(webhook_url: str) -> tuple[int, int]:
    """
    Retry all queued alerts.
    Returns: (success_count, failure_count)
    """
    ensure_directories()
    
    queued_files = sorted(QUEUE_DIR.glob("*.json"))
    
    if not queued_files:
        logger.info("No queued alerts to retry")
        return (0, 0)
    
    logger.info(f"Retrying {len(queued_files)} queued alerts...")
    
    success_count = 0
    failure_count = 0
    
    for alert_file in queued_files:
        try:
            with open(alert_file, 'r') as f:
                alert = json.load(f)
            
            # Check retry count
            retry_count = alert.get('retry_count', 0)
            if retry_count >= 10:
                logger.warning(f"Alert {alert_file.name} exceeded retry limit, archiving")
                archive_file = alert_file.with_suffix('.failed')
                alert_file.rename(archive_file)
                failure_count += 1
                continue
            
            # Attempt to send
            if send_discord_alert(
                webhook_url,
                alert['severity'],
                alert['message'],
                alert['host'],
                alert.get('details')
            ):
                logger.info(f"Successfully resent queued alert: {alert_file.name}")
                alert_file.unlink()
                success_count += 1
            else:
                # Increment retry count
                alert['retry_count'] = retry_count + 1
                with open(alert_file, 'w') as f:
                    json.dump(alert, f, indent=2)
                failure_count += 1
                
        except Exception as e:
            logger.error(f"Failed to retry {alert_file.name}: {e}")
            failure_count += 1
    
    logger.info(f"Retry complete: {success_count} sent, {failure_count} failed")
    return (success_count, failure_count)


def get_queue_stats() -> dict:
    """Get statistics about alert queue."""
    ensure_directories()
    
    queued_files = list(QUEUE_DIR.glob("*.json"))
    failed_files = list(QUEUE_DIR.glob("*.failed"))
    
    if not queued_files:
        return {
            'queued': 0,
            'failed': len(failed_files),
            'oldest_queued': None
        }
    
    oldest_file = min(queued_files, key=lambda f: f.stat().st_mtime)
    oldest_age = time.time() - oldest_file.stat().st_mtime
    
    return {
        'queued': len(queued_files),
        'failed': len(failed_files),
        'oldest_queued': int(oldest_age),
        'oldest_file': oldest_file.name
    }


def main():
    parser = argparse.ArgumentParser(description="Send CCDC intrusion alerts to Discord")
    parser.add_argument("--webhook", help="Discord webhook URL")
    parser.add_argument("--severity", choices=["critical", "warning", "info"], 
                       default="warning", help="Alert severity level")
    parser.add_argument("--message", help="Alert message")
    parser.add_argument("--host", help="Hostname where event occurred")
    parser.add_argument("--details", help="Additional details (logs, commands, etc.)")
    parser.add_argument("--cooldown", type=int, default=DEFAULT_COOLDOWN,
                       help="Cooldown period in seconds (default: 300)")
    parser.add_argument("--force", action="store_true",
                       help="Bypass rate limiting and send immediately")
    parser.add_argument("--retry", action="store_true",
                       help="Retry all queued alerts")
    parser.add_argument("--stats", action="store_true",
                       help="Show queue statistics")
    
    args = parser.parse_args()
    
    # Handle --stats
    if args.stats:
        stats = get_queue_stats()
        print(f"Queued alerts: {stats['queued']}")
        print(f"Failed alerts: {stats['failed']}")
        if stats['oldest_queued']:
            print(f"Oldest queued: {stats['oldest_queued']}s ago ({stats['oldest_file']})")
        sys.exit(0)
    
    # Handle --retry
    if args.retry:
        if not args.webhook:
            print("Error: --webhook required for --retry", file=sys.stderr)
            sys.exit(1)
        
        success, failure = retry_queued_alerts(args.webhook)
        sys.exit(0 if failure == 0 else 1)
    
    # Normal alert sending
    if not all([args.webhook, args.message, args.host]):
        parser.error("--webhook, --message, and --host are required for sending alerts")
    
    # Generate alert hash for deduplication
    alert_hash = get_alert_hash(args.message, args.host)
    
    # Check rate limiting (unless forced)
    if not args.force:
        if not should_send_alert_atomic(args.severity, alert_hash, args.cooldown):
            sys.exit(0)  # Not an error, just suppressed
    
    # Send alert
    if send_discord_alert(args.webhook, args.severity, args.message, 
                          args.host, args.details):
        # Only record successful sends (atomic function already recorded)
        if HAVE_FCNTL:
            pass  # Already recorded in should_send_alert_atomic
        else:
            record_alert_fallback(args.severity, alert_hash)
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()