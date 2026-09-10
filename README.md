# raw2dng

카메라 **RAW → Adobe DNG** 변환 CLI.

내부적으로 [dnglab](https://github.com/dnglab/dnglab)을 호출합니다. CR2/CR3, NEF, ARW, RAF, ORF, RW2 등 주요 RAW를 지원합니다.

## 가장 쉬운 방법 (실행 파일)

1. [Releases](https://github.com/dahli4/raw2dng/releases)에서 OS에 맞는 압축 파일을 받습니다.
2. 압축을 풀면 `raw2dng`와 `dnglab`이 같이 있습니다.
3. 그 폴더에서:

```bash
# macOS / Linux
chmod +x raw2dng dnglab
./raw2dng IMG_1234.CR3

# Windows (PowerShell / cmd)
raw2dng.exe IMG_1234.CR3
```

출력은 기본적으로 같은 폴더에 `IMG_1234.dng`로 생깁니다.

## 사용법

```bash
# 단일 파일
raw2dng photo.CR3
raw2dng photo.CR3 out/photo.dng

# 여러 파일 → 폴더
raw2dng a.NEF b.NEF converted/

# 폴더 일괄 변환
raw2dng ./DCIM ./dng-out
raw2dng -r ./DCIM ./dng-out          # 하위 폴더 포함
raw2dng -f ./DCIM ./dng-out          # 기존 .dng 덮어쓰기

# 옵션
raw2dng -c uncompressed photo.ARW    # 무압축 DNG
raw2dng --no-embed-raw photo.ARW     # 원본 RAW 임베드 안 함
raw2dng --which-dnglab               # 사용 중인 dnglab 경로
raw2dng -V
```

## Python으로 설치

Python 3.9+ 필요. **dnglab 실행 파일**도 필요합니다.

```bash
pip install git+https://github.com/dahli4/raw2dng.git
bash scripts/install_dnglab.sh   # 또는 Release / 공식 dnglab 바이너리를 PATH에
raw2dng photo.CR3
```

`dnglab`을 PATH에 두거나:

```bash
export RAW2DNG_DNGLAB=/path/to/dnglab
```

### dnglab만 직접 쓰기

```bash
dnglab convert INPUT.CR3 OUTPUT.dng
dnglab convert ./raw-folder ./dng-folder
```

공식 배포: https://github.com/dnglab/dnglab/releases

## 지원 확장자 (입력)

`.arw` `.cr2` `.cr3` `.crw` `.dng` `.erf` `.iiq` `.kdc` `.mef` `.mos` `.mrw` `.nef` `.nrw` `.orf` `.pef` `.raf` `.raw` `.rw2` `.rwl` `.sr2` `.srf` `.srw` `.x3f`

실제 카메라 호환은 dnglab 버전에 따릅니다. `dnglab cameras`로 목록을 볼 수 있습니다.

## 개발

```bash
git clone https://github.com/dahli4/raw2dng.git
cd raw2dng
python3 -m pip install -e .
python3 -m raw2dng --help
```

릴리즈 패키지 빌드:

```bash
bash scripts/build_release.sh
```

## 라이선스

MIT. 변환 엔진은 dnglab(해당 프로젝트 라이선스)을 사용합니다.
