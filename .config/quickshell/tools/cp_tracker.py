#!/usr/bin/env python3
"""
~/.config/quickshell/tools/cp_tracker.py
Deterministic backend for Quickshell CP Desktop Widget.
Fetches Codeforces & AtCoder data, evaluates level recommendations,
and outputs/caches unified JSON for Quickshell QML.
"""

import sys
import os
import json
import re
import time
import argparse
import urllib.request
from datetime import datetime, timezone, timedelta

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0"

def get_ist_timezone():
    return timezone(timedelta(hours=5, minutes=30))

def format_timestamp_ist(epoch_sec):
    dt = datetime.fromtimestamp(epoch_sec, tz=get_ist_timezone())
    return dt.strftime("%a, %b %d • %I:%M %p")

def format_countdown(epoch_sec, now_sec):
    diff = int(epoch_sec - now_sec)
    if diff <= 0:
        return "Started / Live"
    days = diff // 86400
    hours = (diff % 86400) // 3600
    mins = (diff % 3600) // 60
    if days > 0:
        return f"{days}d {hours}h"
    elif hours > 0:
        return f"{hours}h {mins}m"
    else:
        return f"{mins}m"

def http_get(url, timeout=8):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return response.read()
    except Exception:
        return None

# ==============================================================================
# Codeforces Client
# ==============================================================================
class CodeforcesClient:
    BASE_URL = "https://codeforces.com/api"

    @classmethod
    def get_upcoming_contests(cls):
        raw = http_get(f"{cls.BASE_URL}/contest.list?gym=false")
        if not raw:
            return []
        try:
            data = json.loads(raw.decode("utf-8"))
            if data.get("status") != "OK":
                return []
            upcoming = []
            for c in data.get("result", []):
                if c.get("phase") == "BEFORE":
                    start_sec = c.get("startTimeSeconds", 0)
                    duration_sec = c.get("durationSeconds", 7200)
                    upcoming.append({
                        "platform": "Codeforces",
                        "id": f"cf-{c['id']}",
                        "name": c.get("name", "Unknown Round"),
                        "start_epoch": start_sec,
                        "duration_sec": duration_sec,
                        "duration_str": f"{duration_sec // 60}m",
                        "url": f"https://codeforces.com/contest/{c['id']}",
                        "raw_type": c.get("type", "CF")
                    })
            upcoming.sort(key=lambda x: x["start_epoch"])
            return upcoming
        except Exception:
            return []

    @classmethod
    def get_user_info(cls, handle):
        if not handle:
            return None
        raw = http_get(f"{cls.BASE_URL}/user.info?handles={handle}")
        if not raw:
            return None
        try:
            data = json.loads(raw.decode("utf-8"))
            if data.get("status") != "OK" or not data.get("result"):
                return None
            u = data["result"][0]
            rating = u.get("rating", 0)
            rank = u.get("rank", "unrated")
            return {
                "handle": u.get("handle", handle),
                "rating": rating,
                "max_rating": u.get("maxRating", 0),
                "rank": rank.capitalize() if rank else "Unrated",
                "max_rank": u.get("maxRank", "unrated")
            }
        except Exception:
            return None

# ==============================================================================
# AtCoder Client
# ==============================================================================
class AtCoderClient:
    BASE_URL = "https://atcoder.jp"

    @classmethod
    def get_upcoming_contests(cls):
        raw = http_get(f"{cls.BASE_URL}/contests/")
        if not raw:
            return []
        try:
            html = raw.decode("utf-8")
            if "Upcoming Contests" not in html:
                return []
            part = html.split("Upcoming Contests")[1].split("</table>")[0]
            rows = re.findall(r"<tr>(.*?)</tr>", part, re.DOTALL)
            upcoming = []
            now = time.time()

            for row in rows[1:]:
                time_match = re.search(r"iso=([0-9]{8}T[0-9]{4})", row)
                name_match = re.search(r"<a href=[\"']/contests/([a-zA-Z0-9_\-]+)[\"']>(.*?)</a>", row)
                duration_match = re.search(r"<td class=[\"']text-center[\"']>([0-9]{2}:[0-9]{2})</td>", row)
                rated_match = re.findall(r"<td class=[\"']text-center[\"']>(.*?)</td>", row)

                if not (time_match and name_match):
                    continue

                contest_slug = name_match.group(1)
                contest_name = name_match.group(2).strip()
                iso_str = time_match.group(1)

                jst_dt = datetime.strptime(iso_str, "%Y%m%dT%H%M").replace(
                    tzinfo=timezone(timedelta(hours=9))
                )
                start_epoch = int(jst_dt.timestamp())

                dur_str = duration_match.group(1) if duration_match else "01:40"
                dur_parts = dur_str.split(":")
                dur_sec = int(dur_parts[0]) * 3600 + int(dur_parts[1]) * 60

                rated_target = rated_match[-1].strip() if rated_match else "All"

                upcoming.append({
                    "platform": "AtCoder",
                    "id": f"ac-{contest_slug}",
                    "name": contest_name,
                    "start_epoch": start_epoch,
                    "duration_sec": dur_sec,
                    "duration_str": f"{dur_sec // 60}m",
                    "url": f"https://atcoder.jp/contests/{contest_slug}",
                    "rated_range": rated_target
                })

            upcoming = [c for c in upcoming if c["start_epoch"] > now]
            upcoming.sort(key=lambda x: x["start_epoch"])
            return upcoming
        except Exception:
            return []

    @classmethod
    def get_user_history(cls, handle):
        if not handle:
            return {"rating": 0, "highest": 0, "rank": "Unrated"}
        raw = http_get(f"{cls.BASE_URL}/users/{handle}/history/json")
        if not raw:
            return {"rating": 0, "highest": 0, "rank": "Unrated"}
        try:
            data = json.loads(raw.decode("utf-8"))
            if not isinstance(data, list) or len(data) == 0:
                return {"rating": 0, "highest": 0, "rank": "Unrated"}
            latest = data[-1]
            highest = max(item.get("NewRating", 0) for item in data)
            rating = latest.get("NewRating", 0)
            rank = "Kyu / Dan" if rating > 0 else "Unrated"
            return {
                "rating": rating,
                "highest": highest,
                "rank": rank
            }
        except Exception:
            return {"rating": 0, "highest": 0, "rank": "Unrated"}

# ==============================================================================
# Level Matcher
# ==============================================================================
class LevelMatcher:
    @staticmethod
    def evaluate(contest, user_rating):
        name = contest.get("name", "")
        platform = contest.get("platform", "")
        eff_rating = max(user_rating, 800)

        if platform == "Codeforces":
            if "Div. 4" in name:
                return {"tier": "RECOMMENDED", "badge": "⭐ Div 4", "color": "#80d4dc"}
            elif "Div. 3" in name:
                if eff_rating < 1600:
                    return {"tier": "RECOMMENDED", "badge": "⭐ Div 3", "color": "#80d4dc"}
                else:
                    return {"tier": "PRACTICE", "badge": "Div 3 (Speed)", "color": "#b1cbce"}
            elif "Div. 2" in name:
                if eff_rating < 1400:
                    return {"tier": "PRACTICE", "badge": "Practice A/B", "color": "#b1cbce"}
                elif eff_rating < 1900:
                    return {"tier": "RECOMMENDED", "badge": "⭐ Div 2", "color": "#80d4dc"}
                else:
                    return {"tier": "PRACTICE", "badge": "Div 2", "color": "#b1cbce"}
            elif "Div. 1" in name:
                if eff_rating < 1900:
                    return {"tier": "SKIP", "badge": "Skip (Div 1)", "color": "#899393"}
                else:
                    return {"tier": "RECOMMENDED", "badge": "⭐ Div 1", "color": "#80d4dc"}
            else:
                return {"tier": "PRACTICE", "badge": "Open Round", "color": "#b1cbce"}

        elif platform == "AtCoder":
            if "Beginner Contest" in name or "ABC" in name:
                return {"tier": "RECOMMENDED", "badge": "⭐ AtCoder ABC", "color": "#80d4dc"}
            elif "Regular Contest" in name or "ARC" in name:
                if eff_rating < 1600:
                    return {"tier": "SKIP", "badge": "Skip (ARC)", "color": "#899393"}
                else:
                    return {"tier": "RECOMMENDED", "badge": "⭐ ARC", "color": "#80d4dc"}
            elif "Grand Contest" in name or "AGC" in name:
                return {"tier": "SKIP", "badge": "Skip (AGC)", "color": "#899393"}
            else:
                return {"tier": "PRACTICE", "badge": "Heuristic/Other", "color": "#b1cbce"}

        return {"tier": "PRACTICE", "badge": "Contest", "color": "#b1cbce"}

# ==============================================================================
# Fetch & Package Data
# ==============================================================================
def fetch_and_package(cf_handle="pranav244872", ac_handle="pranav244872"):
    now = time.time()
    cf_user = CodeforcesClient.get_user_info(cf_handle)
    ac_user = AtCoderClient.get_user_history(ac_handle)

    cf_rating = cf_user.get("rating", 0) if cf_user else 0
    cf_rank = cf_user.get("rank", "Unrated") if cf_user else "Unrated"
    ac_rating = ac_user.get("rating", 0) if ac_user else 0
    ac_rank = ac_user.get("rank", "Unrated") if ac_user else "Unrated"

    effective_rating = max(cf_rating, ac_rating)

    cf_contests = CodeforcesClient.get_upcoming_contests()
    ac_contests = AtCoderClient.get_upcoming_contests()

    all_contests = cf_contests + ac_contests
    all_contests.sort(key=lambda x: x["start_epoch"])

    evaluated = []
    next_recommended = None

    for c in all_contests:
        lvl = LevelMatcher.evaluate(c, effective_rating)
        c_item = dict(c)
        c_item["tier"] = lvl["tier"]
        c_item["badge"] = lvl["badge"]
        c_item["badge_color"] = lvl["color"]
        c_item["start_formatted"] = format_timestamp_ist(c["start_epoch"])
        c_item["countdown"] = format_countdown(c["start_epoch"], now)
        c_item["hours_until"] = round((c["start_epoch"] - now) / 3600, 1)
        evaluated.append(c_item)

        if lvl["tier"] == "RECOMMENDED" and next_recommended is None:
            next_recommended = c_item

    # If no recommended contest found, take the first upcoming one
    featured = next_recommended if next_recommended else (evaluated[0] if evaluated else None)

    return {
        "status": "success",
        "last_updated_epoch": int(now),
        "last_updated_str": format_timestamp_ist(now),
        "user": {
            "cf_handle": cf_handle,
            "cf_rating": cf_rating,
            "cf_rank": cf_rank,
            "ac_handle": ac_handle,
            "ac_rating": ac_rating,
            "ac_rank": ac_rank,
            "effective_rating": effective_rating
        },
        "featured_contest": featured,
        "upcoming_contests": evaluated[:8] # Top 8 upcoming
    }

def get_default_cache_path():
    cache_dir = os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
    return os.path.join(cache_dir, "quickshell", "cp_data.json")

def main():
    parser = argparse.ArgumentParser(description="Quickshell CP Data Provider")
    parser.add_argument("--cf-handle", default="pranav244872")
    parser.add_argument("--ac-handle", default="pranav244872")
    parser.add_argument("--cache-file", default=get_default_cache_path())
    parser.add_argument("--json", action="store_true", help="Print JSON to stdout")
    parser.add_argument("--print-cache", action="store_true", help="Print cached file if fresh")
    args = parser.parse_args()

    cache_path = os.path.expanduser(args.cache_file)
    os.makedirs(os.path.dirname(cache_path), exist_ok=True)

    # Check if print-cache requested and cache is fresh (< 10 minutes)
    if args.print_cache and os.path.exists(cache_path):
        try:
            mtime = os.path.getmtime(cache_path)
            if (time.time() - mtime) < 600:
                with open(cache_path, "r") as f:
                    print(f.read())
                    return
        except Exception:
            pass

    # Fresh fetch
    data = fetch_and_package(cf_handle=args.cf_handle, ac_handle=args.ac_handle)

    # Atomic write to cache
    tmp_path = cache_path + ".tmp"
    try:
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp_path, cache_path)
    except Exception as e:
        sys.stderr.write(f"Error caching data: {e}\n")

    if args.json or args.print_cache:
        print(json.dumps(data, indent=2))

if __name__ == "__main__":
    main()
