# raw2dng

카메라 **RAW → Adobe DNG** 변환기 (**GUI**).

**설치 없음.** [Releases](https://github.com/dahli4/raw2dng/releases)에서 OS 패키지를 받아 풀고 실행하세요. Python / pip 필요 없습니다.

엔진: [dnglab](https://github.com/dnglab/dnglab) (센서 RAW를 DNG로 담음, 기본 무손실).

## 다운로드 & 실행

| OS | 받는 파일 | 실행 |
|---|---|---|
| Windows | `*-windows-x64.zip` | `raw2dng-gui.cmd` 더블클릭 |
| Linux x64 | `*-linux-x64.tar.gz` | `./raw2dng-gui` |
| macOS Apple Silicon | `*-macos-arm64.tar.gz` | `raw2dng-gui.command` 더블클릭 |

같은 폴더에 `dnglab`(또는 `dnglab.exe`)이 있어야 합니다. 패키지에 포함되어 있습니다.

### GUI에서
1. **파일 추가** 또는 **폴더 추가**
2. (선택) 출력 폴더 — 기본은 원본과 같은 폴더
3. **DNG로 변환**

## 화질

DNG는 미리보기용 JPEG와 별도로 **센서 RAW(CFA)를 무손실**로 담습니다.

샘플(NEF/ARW/ORF) 검증 요약:
- Olympus ORF: 센서 데이터 비트 단위 동일
- Nikon NEF: 상관계수 ≈ 1
- Sony ARW: 정렬 보정 후 CFA 데이터 동일
- EXIF 노출값 유지

## CLI (선택)

패키지의 `raw2dng-cli` / `raw2dng-cli.cmd` 또는 `./dnglab convert in.CR3 out.dng`

## 지원 입력 (대표)

`.arw` `.cr2` `.cr3` `.nef` `.orf` `.raf` `.rw2` `.dng` `.raw` …

## 개발

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -e .
python -m raw2dng          # GUI
python -m raw2dng --cli …  # CLI
```

릴리즈 빌드(Linux GUI 바이너리 필요):

```bash
# pyinstaller → build/gui-bin/raw2dng-gui
bash scripts/build_release.sh
```

## 라이선스

MIT. 변환 엔진은 dnglab 라이선스를 따릅니다.
