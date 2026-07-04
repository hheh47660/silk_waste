#!/usr/bin/env python3
"""
Yonsei Fall 2026 housing application helper.

This script uses Playwright to log in to the Yonsei portal, wait until the
housing term becomes available, fill the configured fields, and optionally
submit the application.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Iterable
from zoneinfo import ZoneInfo

from playwright.sync_api import (
    BrowserContext,
    Error,
    Locator,
    Page,
    TimeoutError as PlaywrightTimeoutError,
    sync_playwright,
)


ROOT = Path(__file__).resolve().parent
DEFAULT_CONFIG = ROOT / "config.json"
DEFAULT_STATE = ROOT / "storage_state.json"


@dataclass
class Settings:
    config_path: Path
    storage_state: Path
    headless: bool
    dry_run: bool
    setup_login: bool
    auto_submit_override: bool
    early_login_minutes: int


def log(message: str) -> None:
    stamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{stamp}] {message}", flush=True)


def load_config(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise SystemExit(
            f"Missing {path.name}. Copy config.example.json to config.json and fill your data."
        )
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def local_now(tz_name: str) -> datetime:
    return datetime.now(ZoneInfo(tz_name))


def parse_run_at(value: str, tz_name: str) -> datetime:
    run_at = datetime.fromisoformat(value)
    if run_at.tzinfo is None:
        run_at = run_at.replace(tzinfo=ZoneInfo(tz_name))
    return run_at


def wait_until(target: datetime, label: str) -> None:
    while True:
        now = datetime.now(target.tzinfo)
        remaining = (target - now).total_seconds()
        if remaining <= 0:
            return
        if remaining > 60:
            log(f"Waiting for {label}: {remaining / 60:.1f} minutes left")
            time.sleep(min(60, remaining - 30))
        elif remaining > 5:
            log(f"Waiting for {label}: {remaining:.0f} seconds left")
            time.sleep(1)
        else:
            time.sleep(0.05)


def contexts(page: Page) -> Iterable[Any]:
    yield page
    for frame in page.frames:
        if frame == page.main_frame:
            continue
        yield frame


def wait_for_quiet_page(page: Page, timeout_ms: int = 12_000) -> None:
    try:
        page.wait_for_load_state("networkidle", timeout=timeout_ms)
    except PlaywrightTimeoutError:
        log("Page is still loading background requests; continuing with visible content.")


def first_visible(locator: Locator, timeout_ms: int = 800) -> Locator | None:
    if timeout_ms <= 0:
        return None
    try:
        locator.first.wait_for(state="visible", timeout=timeout_ms)
        return locator.first
    except PlaywrightTimeoutError:
        return None
    except Error:
        return None


def find_by_text(page: Page, texts: list[str], timeout_ms: int = 700) -> Locator | None:
    deadline = time.monotonic() + timeout_ms / 1000
    while time.monotonic() < deadline:
        for ctx in contexts(page):
            for text in texts:
                for exact in (True, False):
                    remaining_ms = int((deadline - time.monotonic()) * 1000)
                    if remaining_ms <= 0:
                        return None
                    found = first_visible(ctx.get_by_text(text, exact=exact), min(remaining_ms, 250))
                    if found:
                        return found
    return None


def click_text(page: Page, texts: list[str], timeout_ms: int = 1000) -> bool:
    deadline = time.monotonic() + timeout_ms / 1000
    target = find_by_text(page, texts, timeout_ms)
    if not target:
        return False
    try:
        remaining_ms = max(200, int((deadline - time.monotonic()) * 1000))
        target.click(timeout=remaining_ms)
        return True
    except Error:
        return False


def click_role(page: Page, role: str, names: list[str], timeout_ms: int = 1000) -> bool:
    deadline = time.monotonic() + timeout_ms / 1000
    while time.monotonic() < deadline:
        for ctx in contexts(page):
            for name in names:
                remaining_ms = int((deadline - time.monotonic()) * 1000)
                if remaining_ms <= 0:
                    return False
                found = first_visible(ctx.get_by_role(role, name=name), min(remaining_ms, 250))
                if found:
                    try:
                        remaining_ms = max(200, int((deadline - time.monotonic()) * 1000))
                        found.click(timeout=remaining_ms)
                        return True
                    except Error:
                        pass
    return False


def fill_first(page: Page, labels: list[str], value: str, timeout_ms: int = 1000) -> bool:
    if value is None or value == "":
        return True

    for ctx in contexts(page):
        for label in labels:
            locators = [
                ctx.get_by_label(label),
                ctx.get_by_placeholder(label),
                ctx.locator(f"input[name*='{label}' i], textarea[name*='{label}' i]"),
                ctx.locator(f"input[id*='{label}' i], textarea[id*='{label}' i]"),
            ]
            for locator in locators:
                found = first_visible(locator, timeout_ms)
                if not found:
                    continue
                try:
                    found.fill(str(value), timeout=timeout_ms)
                    return True
                except Error:
                    try:
                        found.click(timeout=timeout_ms)
                        found.press("Control+A")
                        found.type(str(value), delay=10)
                        return True
                    except Error:
                        pass
    return False


def choose_option(page: Page, labels: list[str], value: str, timeout_ms: int = 1200) -> bool:
    if not value:
        return True

    for ctx in contexts(page):
        for label in labels:
            candidates = [
                ctx.get_by_label(label),
                ctx.locator(f"select[name*='{label}' i], select[id*='{label}' i]"),
            ]
            for locator in candidates:
                found = first_visible(locator, timeout_ms)
                if not found:
                    continue
                try:
                    found.select_option(label=value, timeout=timeout_ms)
                    return True
                except Error:
                    try:
                        found.select_option(value=value, timeout=timeout_ms)
                        return True
                    except Error:
                        pass

    if click_text(page, labels, timeout_ms):
        if click_text(page, [value], timeout_ms):
            return True

    return click_text(page, [value], timeout_ms)


def has_visible_password_field(page: Page, timeout_ms: int = 700) -> bool:
    deadline = time.monotonic() + timeout_ms / 1000
    while time.monotonic() < deadline:
        for ctx in contexts(page):
            remaining_ms = int((deadline - time.monotonic()) * 1000)
            if remaining_ms <= 0:
                return False
            if first_visible(ctx.locator("input[type='password']"), min(remaining_ms, 250)):
                return True
    return False


def is_probably_logged_in(page: Page) -> bool:
    logged_in_markers = [
        "Academic Information",
        "Dorm(Sinchon)",
        "Logout",
        "학사정보",
        "기숙사",
        "로그아웃",
    ]
    return bool(find_by_text(page, logged_in_markers, timeout_ms=350))


def wait_for_auth_state(page: Page, timeout_ms: int = 8_000) -> str:
    deadline = time.monotonic() + timeout_ms / 1000
    while time.monotonic() < deadline:
        if is_probably_logged_in(page):
            return "logged_in"
        if has_visible_password_field(page, timeout_ms=350):
            return "login_form"
        time.sleep(0.2)
    return "unknown"


def fill_portal_login_fields(page: Page, student_id: str, password: str) -> bool:
    for ctx in contexts(page):
        password_input = first_visible(ctx.locator("input[type='password']"), 1_500)
        if not password_input:
            continue

        visible_inputs = ctx.locator("input:visible")
        try:
            count = visible_inputs.count()
        except Error:
            count = 0

        id_input: Locator | None = None
        for idx in range(count):
            candidate = visible_inputs.nth(idx)
            try:
                input_type = (candidate.get_attribute("type", timeout=300) or "text").lower()
            except Error:
                input_type = "text"
            if input_type not in {"password", "hidden", "submit", "button", "checkbox", "radio"}:
                id_input = candidate
                break

        if not id_input:
            return False

        try:
            id_input.fill(student_id, timeout=1_000)
            password_input.fill(password, timeout=1_000)
            return True
        except Error:
            return False

    return False


def login(page: Page, cfg: dict[str, Any]) -> None:
    page.goto(cfg["portal_url"], wait_until="domcontentloaded")
    wait_for_quiet_page(page, timeout_ms=8_000)

    auth_state = wait_for_auth_state(page)
    if auth_state == "logged_in":
        log("Existing portal session detected; skipping login form.")
        return

    login_cfg = cfg.get("login", {})
    student_id = login_cfg.get("student_id", "")
    password = login_cfg.get("password", "")

    if not student_id or not password or "PUT_" in password:
        log("Login credentials are not configured; waiting for manual login.")
        page.pause()
        return

    if auth_state == "unknown":
        log("Saved session is not confirmed; trying to show the login form.")
        click_role(page, "button", ["LOG-IN", "LOGIN", "Log In", "Login", "로그인"], 1_000) or click_text(
            page, ["LOG-IN", "LOGIN", "Log In", "Login", "로그인"], 1_000
        )
        auth_state = wait_for_auth_state(page, timeout_ms=5_000)

    if auth_state == "logged_in":
        log("Portal session became active; skipping login form.")
        return

    log("Filling portal login.")
    if not has_visible_password_field(page, timeout_ms=2_000):
        log("Saved session appears expired, but the login form was not found. Please log in manually.")
        page.pause()
        return

    filled = fill_portal_login_fields(page, student_id, password)

    if not filled:
        log("Could not identify login fields reliably; finish login manually in the browser.")
        page.pause()
        return

    clicked = (
        click_role(page, "button", ["LOG-IN", "LOGIN", "Log In", "Login", "로그인"], 1200)
        or click_text(page, ["LOG-IN", "LOGIN", "Log In", "Login", "로그인"], 1200)
    )
    if not clicked:
        page.keyboard.press("Enter")

    wait_for_quiet_page(page, timeout_ms=12_000)
    auth_state = wait_for_auth_state(page, timeout_ms=10_000)
    if auth_state != "logged_in":
        log("Automatic login did not reach the portal home. Please finish login manually.")
        page.pause()
    log("Login step finished.")


def open_housing_application(page: Page) -> None:
    log("Opening Academic Information System.")
    click_text(page, ["Academic Information System", "학사정보"], 1_000)
    log("Opening Dorm(Sinchon) housing application menu.")
    click_text(page, ["Dorm(Sinchon)", "Dorm", "기숙사"], 2_000)
    opened = click_text(page, ["Application/입사신청", "Application", "입사신청"], 3_000)
    if not opened:
        log("Menu not found automatically; please open Academic Information > Dorm(Sinchon) > Application/입사신청.")
        page.pause()

    wait_for_quiet_page(page)


def select_housing_term(page: Page, term: str, deadline_seconds: int = 900) -> None:
    log(f"Looking for housing term: {term}")
    deadline = time.monotonic() + deadline_seconds
    attempts = 0

    while time.monotonic() < deadline:
        attempts += 1
        for ctx in contexts(page):
            selects = ctx.locator("select")
            try:
                count = selects.count()
            except Error:
                count = 0
            for idx in range(count):
                select = selects.nth(idx)
                try:
                    select.select_option(label=term, timeout=400)
                    log(f"Housing term selected after {attempts} attempts.")
                    return
                except Error:
                    try:
                        options = select.locator("option").all_inner_texts(timeout=400)
                    except Error:
                        options = []
                    for option in options:
                        if term.lower() in option.lower() or "2026-fall" in option.lower():
                            select.select_option(label=option, timeout=800)
                            log(f"Housing term selected as: {option}")
                            return

        if click_text(page, [term, "2026-FALL", "2026- Fall", "2026-Fall"], 400):
            log(f"Housing term selected after {attempts} attempts.")
            return

        if attempts % 10 == 0:
            log("Term not available yet; refreshing/polling.")
            try:
                page.reload(wait_until="domcontentloaded", timeout=15_000)
                wait_for_quiet_page(page, timeout_ms=15_000)
            except Error:
                pass
        else:
            time.sleep(0.3)

    raise RuntimeError("Housing term did not become available before the polling deadline.")


def fill_address(page: Page, address_cfg: dict[str, str]) -> None:
    if not address_cfg:
        return

    log("Filling address using Direct Input when available.")
    click_text(page, ["Search", "검색", "Address", "주소"], 1_000)
    click_text(page, ["Direct Input", "직접입력"], 2_000)
    fill_first(page, ["Postal Code", "Zip Code", "Post Code", "우편번호"], address_cfg.get("postal_code", "0000"))
    fill_first(page, ["Address", "주소"], address_cfg.get("address", ""))
    fill_first(page, ["Detail", "Detailed Address", "상세주소"], address_cfg.get("detail", ""))
    click_role(page, "button", ["OK", "Confirm", "Apply", "확인"], 800)


def fill_application(page: Page, cfg: dict[str, Any]) -> None:
    app_cfg = cfg.get("application", {})
    fields = app_cfg.get("form_fields", {})

    log("Filling application fields from config.json.")
    for label, value in fields.items():
        if not fill_first(page, [label], str(value)):
            if not choose_option(page, [label], str(value)):
                log(f"Field not found automatically: {label!r}. You may need to fill it manually.")

    fill_address(page, app_cfg.get("address", {}))

    priority = app_cfg.get("first_priority", "")
    if priority:
        log("Selecting first priority.")
        if not choose_option(
            page,
            ["1st Priority", "First Priority", "1 priority", "희망", "Dormitory"],
            priority,
        ):
            log("Could not select first priority automatically; please check it in the browser.")

    for agreement in app_cfg.get("agreements", []):
        click_text(page, [agreement], 700)


def submit_application(page: Page, cfg: dict[str, Any], dry_run: bool, auto_submit_override: bool) -> None:
    submit_cfg = cfg.get("submit", {})
    auto_submit = bool(submit_cfg.get("auto_submit", False) or auto_submit_override)
    pause_before = bool(submit_cfg.get("pause_before_final_submit", True))

    if dry_run:
        log("Dry run enabled; stopping before submit.")
        page.pause()
        return

    if pause_before and not auto_submit:
        log("Review the form in the browser. Resume Playwright when you are ready to submit.")
        page.pause()

    if not auto_submit and pause_before:
        log("Submitting after manual confirmation.")
    elif not auto_submit:
        log("auto_submit is false, so I will not submit. Browser remains open for manual submit.")
        page.pause()
        return
    else:
        log("Auto-submit enabled.")

    clicked = (
        click_role(page, "button", ["Submit", "Apply", "Save", "신청", "저장", "확인"], 2_000)
        or click_text(page, ["Submit", "Apply", "Save", "신청", "저장", "확인"], 2_000)
    )
    if not clicked:
        log("Submit button not found automatically; submit manually in the browser.")
        page.pause()
        return

    time.sleep(0.5)
    click_role(page, "button", ["OK", "Confirm", "Yes", "확인", "예"], 2_000) or click_text(
        page, ["OK", "Confirm", "Yes", "확인", "예"], 2_000
    )
    wait_for_quiet_page(page, timeout_ms=20_000)
    log("Submit flow completed. Check the page for the final status.")


def save_login_state(context: BrowserContext, path: Path) -> None:
    context.storage_state(path=str(path))
    log(f"Saved login state to {path.name}.")


def run(settings: Settings) -> None:
    cfg = load_config(settings.config_path)
    tz_name = cfg.get("timezone", "Europe/Rome")
    run_at = parse_run_at(cfg.get("run_at", "2026-06-02T03:00:00+02:00"), tz_name)
    login_at = run_at - timedelta(minutes=settings.early_login_minutes)

    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=settings.headless)
        context_args: dict[str, Any] = {"viewport": {"width": 1440, "height": 1000}}
        if settings.storage_state.exists():
            context_args["storage_state"] = str(settings.storage_state)
        context = browser.new_context(**context_args)
        page = context.new_page()

        if settings.setup_login:
            log("Opening portal for manual login setup.")
            page.goto(cfg["portal_url"], wait_until="domcontentloaded")
            log("Log in manually, then resume Playwright to save the session.")
            page.pause()
            save_login_state(context, settings.storage_state)
            browser.close()
            return

        if local_now(tz_name) < login_at:
            wait_until(login_at, "early login")

        login(page, cfg)
        save_login_state(context, settings.storage_state)
        open_housing_application(page)

        if local_now(tz_name) < run_at:
            wait_until(run_at, "portal opening")

        select_housing_term(page, cfg["housing_term"])
        fill_application(page, cfg)
        submit_application(page, cfg, settings.dry_run, settings.auto_submit_override)

        log("Leaving browser open for inspection. Press Ctrl+C here when done.")
        try:
            while True:
                time.sleep(60)
        except KeyboardInterrupt:
            browser.close()


def parse_args() -> Settings:
    parser = argparse.ArgumentParser(description="Yonsei housing application bot")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--storage-state", type=Path, default=DEFAULT_STATE)
    parser.add_argument("--headless", action="store_true", help="Run browser without a visible window")
    parser.add_argument("--dry-run", action="store_true", help="Fill only, then pause before submit")
    parser.add_argument("--setup-login", action="store_true", help="Open portal, let you login manually, save session")
    parser.add_argument("--auto-submit", action="store_true", help="Submit without manual pause")
    parser.add_argument("--early-login-minutes", type=int, default=10)
    args = parser.parse_args()
    return Settings(
        config_path=args.config,
        storage_state=args.storage_state,
        headless=args.headless,
        dry_run=args.dry_run,
        setup_login=args.setup_login,
        auto_submit_override=args.auto_submit,
        early_login_minutes=args.early_login_minutes,
    )


if __name__ == "__main__":
    try:
        run(parse_args())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as exc:
        log(f"ERROR: {exc}")
        sys.exit(1)
