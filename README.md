# raw2dng

카메라 **RAW → Adobe DNG** 변환기.

**설치 없음.** [Releases](https://github.com/dahli4/raw2dng/releases)에서 OS용 압축 파일만 받아 풀고 실행하세요. Python / pip 필요 없습니다.

내부 엔진은 [dnglab](https://github.com/dnglab/dnglab)입니다.

## 다운로드 & 실행

1. [Releases](https://github.com/dahli4/raw2dng/releases)에서 받기
   - Linux x64 / arm64 → `.tar.gz`
   - macOS Apple Silicon → `.tar.gz`
   - Windows x64 → `.zip`
2. 압축 풀기
3. 실행:

```bash
# macOS / Linux
cd raw2dng-*-linux-x64   # 또는 macos-arm64
chmod +x raw2dng dnglab  # 필요할 때만
./raw2dng IMG_1234.CR3
```

```bat
:: Windows
cd raw2dng-*-windows-x64
raw2dng.cmd IMG_1234.CR3
```

같은 폴더에 `IMG_1234.dng`가 생깁니다. 폴더 안에는 `raw2dng`(또는 `raw2dng.cmd`)와 `dnglab`만 있으면 됩니다.

## 사용법

```bash
# 단일 파일
./raw2dng photo.CR3
./raw2dng photo.CR3 out/photo.dng

# 여러 파일 → 폴더
./raw2dng a.NEF b.NEF converted/

# 폴더 일괄
./raw2dng ./DCIM ./dng-out
./raw2dng -r ./DCIM ./dng-out
./raw2dng -f ./DCIM ./dng-out

./raw2dng -V
./raw2dng -h
```

Windows는 `raw2dng.cmd`에 같은 식으로 인자를 넣으면 됩니다.

엔진만 직접:

```bash
./dnglab convert INPUT.CR3 OUTPUT.dng
```

## 지원 입력 (대표)

`.arw` `.cr2` `.cr3` `.nef` `.nrw` `.orf` `.pef` `.raf` `.raw` `.rw2` `.dng` 등  
카메라별 호환은 `./dnglab cameras` 참고.

## (선택) 개발자용 Python 패키지

일반 사용자는 무시하세요. 소스 수정할 때만:

```bash
git clone https://github.com/dahli4/raw2dng.git
cd raw2dng
python3 -m pip install -e .
bash scripts/install_dnglab.sh
raw2dng photo.CR3
```

## 릴리즈 빌드

```bash
bash scripts/build_release.sh
```

## 라이선스

MIT. 변환 엔진은 dnglab(해당 프로젝트 라이선스)을 사용합니다.
