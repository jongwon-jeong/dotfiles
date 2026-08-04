# Shell 작업 흐름

이 문서는 Bash와 Zsh에서 함께 사용하는
[`aliases.sh`](../config/shell/aliases.sh)의 사용자 진입점을 작업별로 정리한다.
명령의 실제 구현, platform 분기와 기본값은 설정 파일이 기준이다. 이 문서는 모든
alias를 복제하지 않고 일상적으로 선택하기 어려운 기능과 안전 경계를 설명한다.

설정은 POSIX `sh`와 호환되지 않는다. Bash 또는 Zsh의 interactive shell에서
사용하며, 설치되지 않은 선택 도구에 의존하는 명령은 정의되지 않거나 portable
fallback으로 동작한다.

## 빠른 시작

```sh
cpath .                       # 현재 경로를 text로 복사
cfile report.pdf              # 파일 객체를 desktop clipboard로 복사
ccont notes.txt               # 파일 내용을 복사
f .                           # 현재 경로를 기본 GUI 앱으로 열기
ff config                     # 이름으로 경로 검색
rgp 'literal text'            # 본문에서 고정 문자열 검색
fcd                           # fzf로 디렉터리 선택 후 이동
reload_config                 # 현재 session에서 읽을 수 있는 설정 다시 읽기
sunset status                 # 현재 session의 색온도 조절 상태 확인
pclean                        # 범위를 확인한 뒤 개인정보 기록과 cache 정리
```

현재 정의를 확인할 때는 shell 자체를 기준으로 삼는다.

```sh
type cpath
type bubu
alias gs
command -v fd
```

## 이름 읽는 법

일부 명령 이름은 한글을 입력하려다 영문 입력 상태로 친 key sequence를 mnemonic으로
사용한다. 무작위 약어로 외우지 말고 원래 발음으로 읽는다.

| 명령 | 영문 key를 한글로 읽은 의미 |
|---|---|
| `flfhem` | `리로드`; `reload_config`의 짧은 alias다. |
| `ajrtm` | `먹스`; tmux session에 진입한다. 뒤의 숫자는 session 번호다. |
| `xmfl` | `트리`; `eza`로 directory tree를 표시한다. |
| `djszip`, `djs7z` | `언zip`, `언7z`; archive를 푼다. |
| `clfz` | `칠z`; 7z archive를 만든다. |

`xmfl1`처럼 붙는 숫자는 depth를 뜻한다. `clfz` 계열의 `p`는 password와 filename
암호화, `cp`는 압축하지 않는 copy 방식을 뜻한다.

## 적용 범위와 platform 차이

| 환경 | 주요 동작 |
|---|---|
| Arch Linux desktop | Wayland clipboard, `xdg-open`, Pacman·AUR·Flatpak 관리와 systemd 연동을 사용한다. |
| 다른 Linux desktop | 사용 가능한 package manager와 XDG·clipboard 도구만 선택한다. |
| macOS | `pbcopy`, Finder, Homebrew와 `caffeinate`를 사용한다. |
| WSL | text clipboard와 파일 열기에 `clip.exe`, `explorer.exe`를 사용하고 desktop 전용 update는 건너뛴다. |
| SSH remote shell | GUI clipboard와 파일 열기, OS update alias와 자동 디렉터리 목록 출력을 비활성화한다. |

`fd`, `eza`, `rg`, `bat`, `fzf`, `7zz` 같은 선택 도구는 shell 파일을 읽는 시점에
감지된다. 새 도구를 설치한 뒤에는 새 login shell을 열거나 `reload_config`를
실행한다.

## 설정 편집, 배포와 reload

`nvim`이 있으면 `VISUAL`, `EDITOR`, `GIT_EDITOR`, `FCEDIT`는 `nvim`을 사용하고,
없으면 `vim`으로 내려간다. `v`, `vi`, `vim`, `vimdiff`는 선택된 editor를 일관되게
사용한다.

| 명령 | 역할 |
|---|---|
| `zshrc` | 배포된 `~/.zshrc`를 연다. |
| `alish` | 배포된 `~/.config/shell/aliases.sh`를 연다. |
| `dotfiles` | 배포본인 `~/.dotfiles`로 이동한다. |
| `vdc` | checkout과 배포본의 Neovim 설정을 비교한다. |
| `vdz` | checkout과 배포된 Zsh 설정을 비교한다. |
| `vda` | checkout과 배포본의 shell alias를 비교한다. |
| `xzsh` | 현재 shell을 새 Zsh login shell로 교체한다. |

`~/.dotfiles`는 checkout이 아니라 배포된 파생 복사본일 수 있다. repository의
설정을 변경했다면 먼저 checkout에서 다음을 수동 실행한다.

```sh
./scripts/setup_dotfiles.sh
```

그다음 `reload_config`를 실행하면 접근 가능한 systemd user manager, Sway, 현재
tmux와 shell alias를 차례로 다시 읽는다. 일부 단계가 실패하면 나머지를 시도한
뒤 nonzero를 반환하므로 마지막 `DONE` 또는 `WARN`을 확인한다. 애플리케이션을
완전히 다시 시작해야 하는 설정까지 적용해 주는 명령은 아니다.

## 경로, 파일과 clipboard

| 명령 | 결과 |
|---|---|
| `cpath [PATH ...]` | 절대 경로를 줄 단위 text로 복사한다. 인자가 없으면 현재 디렉터리를 사용한다. |
| `cfile PATH ...` | 파일이나 디렉터리를 GUI에 붙여넣을 수 있는 clipboard 객체로 복사한다. |
| `ccont FILE` | 일반 파일의 내용을 복사한다. X11에서는 조회한 MIME type을 함께 전달한다. |
| `f PATH` | Linux에서는 XDG 기본 앱, WSL에서는 Explorer, macOS에서는 Finder로 연다. |

`cfile`은 `gio`와 Wayland의 `wl-copy` 또는 X11의 `xclip`이 필요하다. `ccont`의
WSL 경로는 text 파일만 허용한다. SSH remote shell에서는 local clipboard가
명시적으로 전달되지 않으므로 세 복사 명령과 `f`를 실패 처리한다.

기본 `cp`와 `mv`는 interactive·verbose 동작을 사용해 덮어쓰기를 확인한다.
무조건적인 복사가 필요할 때만 Linux의 `cp1` 또는 macOS의 대응 구현을 사용한다.

`del PATH ...`은 대상을 즉시 삭제하지 않고 `~/.trash/<timestamp>/`로 옮긴다.
`empty-trash`는 확인 후 이 custom trash만 영구 삭제한다. desktop 표준 휴지통까지
포함한 전체 정리는 `pclean`을 사용한다.

## 디렉터리 이동과 목록

| 명령 | 역할 |
|---|---|
| `p`, `per`, `wk` | `~/Projects`, 개인 프로젝트, 업무 프로젝트로 이동한다. |
| `dl`, `dc`, `tmp` | Downloads, Documents, `~/tmp`로 이동한다. |
| `mkcd DIR` | 디렉터리를 만든 뒤 이동한다. |
| `..`, `...`, `.1` … `.6` | 지정한 수만큼 상위 디렉터리로 이동한다. |
| `ls`, `ll`, `lsa`, `lt` | `eza`가 있으면 Git·icon 정보를 포함하고, 없으면 platform `ls`로 내려간다. |
| `xmfl`, `xmfl1` … `xmfl3` | `eza` tree를 전체 또는 지정 depth로 표시한다. |
| `tree1` … `tree3`, `treesrc`, `treed` | `tree`가 있을 때 자주 쓰는 범위로 구조를 표시한다. |

local shell에서는 `cd` 성공 후 새 디렉터리의 숨김 항목까지 자동 표시한다. 느린
network filesystem에서 불필요한 목록 조회를 만들지 않도록 SSH remote shell에는
이 wrapper를 적용하지 않는다.

tree와 검색 helper는 `.git`, dependency, build output, editor metadata 같은 공통
대형 디렉터리를 기본적으로 제외한다. 제외되지 않은 모든 항목이 필요하면 원래
명령을 `command fd`, `command rg`, `command tree`처럼 직접 실행한다.

## 파일명과 본문 검색

| 명령 | 검색 방식 |
|---|---|
| `ff PATTERN` | 대소문자를 무시하고 경로 이름에 pattern이 포함된 항목을 찾는다. |
| `ffs PREFIX` | 이름이 prefix로 시작하는 항목을 찾는다. |
| `ffe SUFFIX` | 이름이 suffix로 끝나는 항목을 찾는다. |
| `fdf PATTERN` | 일반 파일만 찾는다. |
| `fdf-ext EXT` | 확장자로 파일을 찾는다. `fd`가 필요하다. |
| `fdd PATTERN` | 디렉터리만 찾는다. |
| `rgp TEXT` | 본문에서 fixed string을 smart-case로 찾는다. |
| `rgr REGEX` | 본문에서 regular expression을 smart-case로 찾는다. |

이름 검색의 `-s` 변형은 대소문자를 구분한다. 본문 검색도 `rgp-s`, `rgr-s`로
대소문자를 강제할 수 있다. `fd`나 `rg`가 없으면 일부 기능은 `find`와 `grep`으로
내려가며, 완전히 같은 option 집합을 보장하지 않는다.

`fzf`가 있으면 다음 interactive helper도 정의된다.

| 명령 | 역할과 주의점 |
|---|---|
| `fe [QUERY]` | 파일을 선택해 현재 editor로 연다. |
| `fcd` | 디렉터리를 선택해 이동한다. |
| `fgb` | local·remote branch를 선택해 `git checkout`한다. 전환 전 working tree를 확인한다. |
| `fhist` | history에서 명령을 골라 Zsh command line에 올리거나 Bash에서 출력한다. |
| `fkill` | 선택한 사용자 process에 즉시 `SIGKILL`을 보낸다. 정상 종료가 불가능할 때만 사용한다. |

## Git 단축 명령

Git alias는 원래 명령의 의미를 바꾸지 않고 자주 쓰는 option만 더한다.

| 목적 | 명령 |
|---|---|
| 상태와 diff | `gs`, `gd`, `gds`, `gdc`, `gdcs` |
| stage와 commit | `ga`, `gaa`, `gc`, `gcm`, `gca` |
| branch 전환 | `gb`, `gsw`, `gswc`, `gco`, `gcob` |
| restore | `grs`, `grss` |
| remote 동기화 | `gf`, `gl`, `gp`, `gr` |
| merge·rebase·cherry-pick | `gm`, `grb`, `gcp` |
| stash | `gst`, `gstp` |
| diff·merge 도구 | `gdt`, `gdts`, `gmt` |
| 중단·계속·건너뛰기 | `gma`, `gmc`, `grba`, `grbc`, `grbs`, `gcpa`, `gcpc` |
| log | `gg`, `ggs`, `glp`, `glps`, `ggrep` |

`gaa`, `gca`, restore 계열과 충돌 해결 명령은 넓은 변경을 만들 수 있다. 실행 전후
`gs`, `gd`, `gdc`로 범위를 확인한다.

## tmux 진입점

| 명령 | 역할 |
|---|---|
| `ajrtm`, `ajrtm1` … `ajrtm5` | 아직 tmux 밖일 때 지정 session을 생성하거나 attach한다. |
| `tmls` | session 목록을 표시한다. |
| `tmat NAME` | 지정 session에 attach한다. |
| `tmdt` | 현재 client를 detach한다. |
| `tmkl -t NAME` | 지정 session을 종료한다. |

VS Code terminal, 이미 중첩된 tmux와 non-interactive shell에서는 자동 attach
helper가 아무 작업도 하지 않는다. prefix, window, pane과 nested tmux 사용법은
[tmux 작업 흐름](./tmux-workflow.md)을 따른다.

## 패키지와 개발 도구 업데이트

| 명령 | 범위 |
|---|---|
| `bubo` | 사용 가능한 OS·AUR·desktop package update를 확인한다. network metadata를 읽을 수 있다. |
| `bubc` | 확인된 platform package update를 실제 적용한다. |
| `bubu` | `bubo`가 성공하면 `bubc`를 이어서 실행한다. |
| `upall` | mise 도구, Cargo로 관리하는 `cargo-watch`, uv tool을 갱신하고 mise의 오래된 version을 정리한다. |
| `fwup` | firmware metadata를 새로 읽고 update를 적용한다. |
| `pcup` | 현재 repository의 pre-commit revision을 갱신하고 모든 파일에 hook을 실행한다. |

Arch의 `bubc`는 partial upgrade를 피하기 위해 먼저 `pacman -Syu`, 그다음 AUR,
마지막으로 Flatpak을 처리한다. Debian 계열은 APT upgrade·autoremove·cache 정리와
사용 가능한 Snap refresh를 수행하고, macOS는 Homebrew upgrade와 cleanup을
사용한다. SSH remote shell에서는 OS update alias를 정의하지 않는다.

package를 찾거나 설치 상태를 확인할 때는 Arch의 `pacss`, `pacsi`, `pacqi`,
`pacq`와 AUR의 `yayss`, `yaysi`, `yayqi`를 사용한다. Debian 계열에서는 같은
역할을 `aptss`, `aptsi`, `aptqi`, `aptq`가 맡는다. `pacq`와 `aptq`는 인자가
없으면 전체 설치 목록, 인자가 있으면 이름이 일치하는 package만 보여준다.

OS·개발 도구·firmware update는 서로 다른 소유자와 복구 조건을 가지므로 한 명령에
합치지 않는다. `fwup`은 AC 전원이나 reboot가 필요할 수 있다. `pcup`은 설정과 여러
파일을 수정할 수 있으므로 완료 후 반드시 Git diff를 검토한다.

## 개인정보와 삭제 경계

`pclean`은 삭제 대상을 먼저 요약하고 확인을 받은 뒤 실행한다. clipboard와 shell
history, recent-file metadata, thumbnail, 휴지통, 오래된 setup log, system journal,
Arch package cache의 정확한 보존 범위와 제외 대상은
[Sway 개인정보 수명주기](./sway-workflow.md#개인정보와-로컬-데이터-수명주기)를
따른다.

색온도는 `sunset on`, `sunset off`, `sunset status`로 현재 Sway session에서만
제어한다. 자동 시작이나 위치 기반 network 조회를 추가하지 않는 이유와 시간대는
[Sway 오디오·밝기·미디어](./sway-workflow.md#오디오-밝기-미디어)를 따른다.

다른 열린 shell은 종료할 때 메모리에 남은 history를 다시 기록할 수 있다. 완전한
정리가 필요하면 다른 shell을 먼저 종료하고 마지막 shell에서 `pclean`을 실행한다.
브라우저 기록, 로그인 정보, 다운로드와 광범위한 개발 cache는 자동 삭제하지 않는다.

`mat21 FILE ...`은 MAT2로 지원되는 metadata를 원본 파일에 바로 반영한다. 되돌릴
원본이 필요하면 먼저 별도 복사본을 만든다.

## 압축과 디렉터리 비교

| 명령 | 역할 |
|---|---|
| `zipf PATH ...` | 각 대상을 같은 이름의 ZIP archive로 만든다. |
| `djszip FILE.zip ...` | CP949 filename을 사용하는 ZIP을 archive별 디렉터리에 푼다. |
| `djs7z ARCHIVE ...` | 한 번 입력한 password로 여러 7z archive를 푼다. |
| `clfz PATH ...` | 각 대상을 LZMA2 기반 7z archive로 만든다. |
| `clfzp PATH ...` | filename까지 암호화한 password 7z archive를 만든다. |
| `clfzcp`, `clfzpcp` | 재압축 없이 보관하거나 password와 filename 암호화를 함께 적용한다. |
| `dirdiff DIR1 DIR2 [OPTION ...]` | 공통 대형 디렉터리를 제외하고 두 tree를 재귀 비교한다. |

password 입력은 화면에 표시하지 않지만 shell 함수가 archive password를 별도로
보관하거나 복구하지 않는다. 생성된 archive가 정상적으로 열리는지 확인한 뒤 원본을
정리한다.

## 단일 파일 실행

다음 helper는 알고리즘 연습이나 짧은 실험용이다. 실제 project는 repository가
정한 build tool, dependency와 test command를 우선한다.

| 명령 | 실행 방식 |
|---|---|
| `crun FILE.c` | C17, 엄격한 warning과 ASan·UBSan으로 compile한 뒤 실행한다. |
| `cpprun FILE.cpp` | C++23, 엄격한 warning과 ASan·UBSan으로 compile한 뒤 실행한다. |
| `pyrun FILE.py` | unbuffered Python으로 실행한다. |
| `javarun FILE.java` | compile 후 source 디렉터리를 classpath로 실행한다. |
| `rustrun FILE.rs` | debug info와 optimization을 적용해 compile한 뒤 실행한다. |

source와 같은 basename의 `.in` 파일이 있으면 표준 입력으로 사용한다. C, C++,
Java와 Rust helper는 자신이 만든 executable이나 class 파일을 실행 후 정리한다.
compile이 실패하면 해당 결과를 그대로 반환한다.

## SSH identity와 절전 방지

```sh
sshload ~/.ssh/id_ed25519_personal
ssh-add -l
sshkill
```

`sshload`는 지정한 private key만 8시간 제한으로 현재 agent에 등록하며 `~/.ssh`를
자동 탐색하지 않는다. 접근 가능한 agent가 없으면 현재 interactive shell이 소유하는
새 agent를 시작하므로 그 환경은 다른 기존 terminal에 자동 전파되지 않는다.

`sshkill`은 `SSH_AGENT_PID`가 설정되어 있고 해당 process가 살아 있으면 그
환경이 가리키는 agent를 종료한다. 그 외에는 현재 `SSH_AUTH_SOCK`에 연결된 agent의
identity를 모두 제거하며, 다른 agent process를 검색하거나 종료하지 않는다. Sway
session agent와 업무 identity 선택의 상세 경계는
[Sway SSH agent](./sway-workflow.md#ssh-agent)와
[업무 환경의 SSH 준비](./work-environment.md#4-ssh-준비)를 따른다.

긴 compile, download나 remote 작업 중에만 명령 단위로 절전을 막는다.

```sh
keep_awake make test
keep_awake ssh build-server
```

Linux에서는 `systemd-inhibit`, macOS에서는 `caffeinate`가 child command와 같은
수명을 가진다. 전역 잠금·절전 정책은 변경하지 않는다.

## 문제 해결

명령이 없거나 기대한 구현이 선택되지 않았다면 다음 순서로 확인한다.

```sh
type command_name
command -v dependency_name
echo "$SSH_CONNECTION"
echo "$WAYLAND_DISPLAY"
reload_config
```

repository 파일만 수정한 상태에서는 `reload_config`가 새 내용을 볼 수 없다. 먼저
dotfile을 배포하고, 배포된 symlink나 `~/.dotfiles` 복사본이 checkout의 변경을
가리키는지 확인한다. remote shell이나 선택 dependency가 없는 환경에서 기능을
숨기거나 명시적으로 실패하는 것은 의도된 fallback이다.
