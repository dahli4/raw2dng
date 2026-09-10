#!/usr/bin/env python3
"""raw2dng GUI — pick RAW files/folders and convert to DNG via dnglab."""

from __future__ import annotations

import os
import queue
import shutil
import subprocess
import sys
import threading
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

RAW_EXTS = {
    ".arw", ".cr2", ".cr3", ".crw", ".dng", ".erf", ".iiq", ".kdc", ".mef",
    ".mos", ".mrw", ".nef", ".nrw", ".orf", ".pef", ".raf", ".raw", ".rw2",
    ".rwl", ".sr2", ".srf", ".srw", ".x3f",
}


def app_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent.parent.parent


def find_dnglab() -> Path | None:
    env = os.environ.get("RAW2DNG_DNGLAB") or os.environ.get("DNGLAB")
    if env and Path(env).is_file():
        return Path(env)
    here = app_dir()
    for name in ("dnglab", "dnglab.exe"):
        p = here / name
        if p.is_file():
            return p
    which = shutil.which("dnglab")
    return Path(which) if which else None


def collect_raws(paths: list[Path], recursive: bool) -> list[Path]:
    out: list[Path] = []
    for p in paths:
        if p.is_file() and p.suffix.lower() in RAW_EXTS:
            out.append(p)
        elif p.is_dir():
            globber = p.rglob if recursive else p.glob
            for f in sorted(globber("*")):
                if f.is_file() and f.suffix.lower() in RAW_EXTS:
                    out.append(f)
    # unique preserve order
    seen = set()
    uniq = []
    for f in out:
        rp = f.resolve()
        if rp not in seen:
            seen.add(rp)
            uniq.append(f)
    return uniq


class App(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("raw2dng — RAW → DNG")
        self.geometry("720x520")
        self.minsize(560, 420)

        self.paths: list[Path] = []
        self.out_dir = tk.StringVar(value="")
        self.recursive = tk.BooleanVar(value=True)
        self.overwrite = tk.BooleanVar(value=True)
        self.same_folder = tk.BooleanVar(value=True)
        self._log_q: queue.Queue[str] = queue.Queue()
        self._worker: threading.Thread | None = None

        self._build()
        self.after(100, self._drain_log)

        dng = find_dnglab()
        if dng:
            self._log(f"dnglab: {dng}")
        else:
            self._log("경고: dnglab을 찾지 못했습니다. 이 프로그램과 같은 폴더에 dnglab이 있어야 합니다.")

    def _build(self) -> None:
        pad = {"padx": 10, "pady": 6}
        top = ttk.Frame(self)
        top.pack(fill="x", **pad)

        ttk.Button(top, text="파일 추가", command=self.add_files).pack(side="left", padx=4)
        ttk.Button(top, text="폴더 추가", command=self.add_folder).pack(side="left", padx=4)
        ttk.Button(top, text="목록 비우기", command=self.clear_list).pack(side="left", padx=4)

        opts = ttk.Frame(self)
        opts.pack(fill="x", **pad)
        ttk.Checkbutton(opts, text="하위 폴더 포함", variable=self.recursive).pack(side="left", padx=4)
        ttk.Checkbutton(opts, text="기존 DNG 덮어쓰기", variable=self.overwrite).pack(side="left", padx=4)
        ttk.Checkbutton(
            opts, text="원본과 같은 폴더에 저장", variable=self.same_folder, command=self._toggle_out
        ).pack(side="left", padx=4)

        out_row = ttk.Frame(self)
        out_row.pack(fill="x", **pad)
        ttk.Label(out_row, text="출력 폴더").pack(side="left")
        self.out_entry = ttk.Entry(out_row, textvariable=self.out_dir)
        self.out_entry.pack(side="left", fill="x", expand=True, padx=6)
        self.out_btn = ttk.Button(out_row, text="찾기…", command=self.pick_out)
        self.out_btn.pack(side="left")
        self._toggle_out()

        mid = ttk.Frame(self)
        mid.pack(fill="both", expand=True, **pad)
        self.listbox = tk.Listbox(mid, selectmode="extended")
        scroll = ttk.Scrollbar(mid, orient="vertical", command=self.listbox.yview)
        self.listbox.configure(yscrollcommand=scroll.set)
        self.listbox.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")

        bottom = ttk.Frame(self)
        bottom.pack(fill="x", **pad)
        self.convert_btn = ttk.Button(bottom, text="DNG로 변환", command=self.start_convert)
        self.convert_btn.pack(side="left", padx=4)
        self.status = ttk.Label(bottom, text="대기 중")
        self.status.pack(side="left", padx=8)

        log_frame = ttk.LabelFrame(self, text="로그")
        log_frame.pack(fill="both", expand=False, **pad)
        self.log = tk.Text(log_frame, height=10, wrap="word", state="disabled")
        self.log.pack(fill="both", expand=True, padx=4, pady=4)

    def _toggle_out(self) -> None:
        state = "disabled" if self.same_folder.get() else "normal"
        self.out_entry.configure(state=state)
        self.out_btn.configure(state=state)

    def _log(self, msg: str) -> None:
        self._log_q.put(msg)

    def _drain_log(self) -> None:
        try:
            while True:
                msg = self._log_q.get_nowait()
                self.log.configure(state="normal")
                self.log.insert("end", msg + "\n")
                self.log.see("end")
                self.log.configure(state="disabled")
        except queue.Empty:
            pass
        self.after(100, self._drain_log)

    def add_files(self) -> None:
        files = filedialog.askopenfilenames(
            title="RAW 파일 선택",
            filetypes=[
                ("RAW / DNG", " ".join(f"*{e}" for e in sorted(RAW_EXTS))),
                ("All", "*.*"),
            ],
        )
        for f in files:
            self._add_path(Path(f))

    def add_folder(self) -> None:
        d = filedialog.askdirectory(title="RAW 폴더 선택")
        if d:
            self._add_path(Path(d))

    def pick_out(self) -> None:
        d = filedialog.askdirectory(title="출력 폴더")
        if d:
            self.out_dir.set(d)

    def _add_path(self, p: Path) -> None:
        if p not in self.paths:
            self.paths.append(p)
            self.listbox.insert("end", str(p))

    def clear_list(self) -> None:
        self.paths.clear()
        self.listbox.delete(0, "end")

    def start_convert(self) -> None:
        if self._worker and self._worker.is_alive():
            return
        if not self.paths:
            messagebox.showinfo("raw2dng", "파일이나 폴더를 추가하세요.")
            return
        dnglab = find_dnglab()
        if not dnglab:
            messagebox.showerror("raw2dng", "dnglab을 찾을 수 없습니다.\n프로그램과 같은 폴더에 두세요.")
            return
        if not self.same_folder.get() and not self.out_dir.get().strip():
            messagebox.showinfo("raw2dng", "출력 폴더를 지정하세요.")
            return

        files = collect_raws(self.paths, self.recursive.get())
        if not files:
            messagebox.showinfo("raw2dng", "변환할 RAW 파일이 없습니다.")
            return

        self.convert_btn.configure(state="disabled")
        self.status.configure(text=f"변환 중… (0/{len(files)})")
        self._worker = threading.Thread(
            target=self._run_convert,
            args=(dnglab, files),
            daemon=True,
        )
        self._worker.start()

    def _run_convert(self, dnglab: Path, files: list[Path]) -> None:
        ok = 0
        fail = 0
        for i, inp in enumerate(files, 1):
            if self.same_folder.get():
                out = inp.with_suffix(".dng")
            else:
                out = Path(self.out_dir.get()) / (inp.stem + ".dng")
                out.parent.mkdir(parents=True, exist_ok=True)

            if out.exists() and not self.overwrite.get():
                self._log(f"건너뜀: {out.name}")
                self.after(0, lambda i=i, n=len(files): self.status.configure(text=f"변환 중… ({i}/{n})"))
                continue

            cmd = [str(dnglab), "convert"]
            if self.overwrite.get():
                cmd.append("-f")
            cmd.extend([str(inp), str(out)])
            self._log(f"{inp.name} → {out}")
            try:
                r = subprocess.run(cmd, capture_output=True, text=True)
                if r.returncode == 0:
                    ok += 1
                else:
                    fail += 1
                    err = (r.stderr or r.stdout or "").strip()
                    self._log(f"실패 ({r.returncode}): {err[:500]}")
            except Exception as e:
                fail += 1
                self._log(f"오류: {e}")
            self.after(0, lambda i=i, n=len(files): self.status.configure(text=f"변환 중… ({i}/{n})"))

        def done() -> None:
            self.convert_btn.configure(state="normal")
            self.status.configure(text=f"완료 — 성공 {ok}, 실패 {fail}")
            messagebox.showinfo("raw2dng", f"완료\n성공 {ok}\n실패 {fail}")

        self.after(0, done)


def main() -> None:
    app = App()
    app.mainloop()


if __name__ == "__main__":
    main()
