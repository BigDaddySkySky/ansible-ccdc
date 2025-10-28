#!/usr/bin/env python3
"""
CCDC Alert Retry Daemon
Runs as systemd service to automatically retry queued alerts every 5 minutes.

USAGE:
    systemctl start ccdc-alert-retry
    systemctl enable ccdc-alert-retry
"""

import os
import sys
import time
import logging
from pathlib import Path

# Import the main alert script functions
sys.path.insert(0, '/usr/local/bin')
from ccdc_alert import retry_queued_alerts, get_queue_stats

# Configuration
RETRY_INTERVAL = 300  # 5 minutes
WEBHOOK_URL_FILE = Path("/etc/ccdc/webhook_url")
LOG_DIR = Path("/var/log/ccdc")

# Setup logging
LOG_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / 'alert_retry_daemon.log'),
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger(__name__)


def get_webhook_url() -> str:
    """Read webhook URL from config file."""
    if not WEBHOOK_URL_FILE.exists():
        logger.error(f"Webhook URL file not found: {WEBHOOK_URL_FILE}")
        return None
    
    try:
        with open(WEBHOOK_URL_FILE, 'r') as f:
            url = f.read().strip()
            if not url:
                logger.error("Webhook URL file is empty")
                return None
            return url
    except Exception as e:
        logger.error(f"Failed to read webhook URL: {e}")
        return None


def main():
    """Main daemon loop."""
    logger.info("CCDC Alert Retry Daemon starting...")
    
    # Initial health check
    webhook_url = get_webhook_url()
    if not webhook_url:
        logger.critical("Cannot start without webhook URL")
        sys.exit(1)
    
    logger.info(f"Webhook configured, retry interval: {RETRY_INTERVAL}s")
    
    consecutive_failures = 0
    max_consecutive_failures = 12  # 1 hour of failures
    
    while True:
        try:
            # Get queue stats
            stats = get_queue_stats()
            
            if stats['queued'] > 0:
                logger.info(f"Processing {stats['queued']} queued alerts...")
                
                # Attempt retry
                success, failure = retry_queued_alerts(webhook_url)
                
                if success > 0:
                    logger.info(f"Successfully delivered {success} alerts")
                    consecutive_failures = 0
                
                if failure > 0:
                    consecutive_failures += 1
                    logger.warning(f"Failed to deliver {failure} alerts (consecutive failures: {consecutive_failures})")
                    
                    if consecutive_failures >= max_consecutive_failures:
                        logger.critical(f"Exceeded max consecutive failures ({max_consecutive_failures}), check webhook URL")
                        # Don't exit - keep trying
            else:
                # Reset failure counter when queue is empty
                if consecutive_failures > 0:
                    logger.info("Queue cleared, resetting failure counter")
                consecutive_failures = 0
            
            # Log queue status periodically
            if stats['queued'] > 10:
                logger.warning(f"Alert queue backlog: {stats['queued']} alerts")
            
            if stats['failed'] > 5:
                logger.warning(f"Persistent failures: {stats['failed']} alerts exceeded retry limit")
            
        except KeyboardInterrupt:
            logger.info("Received interrupt signal, shutting down...")
            break
        except Exception as e:
            logger.exception(f"Unexpected error in retry loop: {e}")
            consecutive_failures += 1
        
        # Wait before next retry
        time.sleep(RETRY_INTERVAL)
    
    logger.info("CCDC Alert Retry Daemon stopped")


if __name__ == "__main__":
    main()