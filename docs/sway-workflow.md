# Sway 데스크톱 사용 안내

이 문서는 이 리포가 구성하는 Sway 단일 데스크톱의 사용법과 복구 절차를 설명한다. 공용 설정의 기준 파일은 `config/sway/config`이며, 키를 변경할 때는 이 문서도 같은 변경에서 갱신한다.

## 5분 빠른 시작

`Super`는 일반 키보드의 Windows 키 또는 Command 키에 해당한다.

처음에는 다음 키만 기억하면 된다.

| 키 | 동작 |
|---|---|
| `Super+Enter` | 터미널 열기 |
| `Super+D` | 애플리케이션 검색 |
| `Super+H/J/K/L` 또는 방향키 | 창 사이의 초점 이동 |
| `Super+Shift+H/J/K/L` 또는 방향키 | 창 위치 이동 |
| `Super+1` … `Super+0` | 워크스페이스 1~10으로 이동 |
| `Super+Shift+1` … `Super+Shift+0` | 현재 창을 워크스페이스로 보내기 |
| `Super+F` | 전체 화면 전환 |
| `Super+Shift+Q` | 현재 창 닫기 |
| `Super+Ctrl+L` | 화면 잠금 |
| `Super+F1` | 이 문서 열기 |

애플리케이션을 찾을 때는 `Super+D`를 누르고 이름 일부를 입력한 뒤 `Enter`를 누른다. 대부분의 작업은 이 실행기를 출발점으로 삼는다.

## 기본 개념

### 창과 컨테이너

Sway는 새 창을 현재 컨테이너에 타일로 배치한다. 창을 겹쳐 놓고 위치를 매번 조절하는 대신 화면을 분할하고, 분할된 영역 안에 창을 넣는다.

- 초점: 현재 키 입력을 받는 창
- 컨테이너: 창 또는 여러 창을 감싸는 레이아웃 단위
- 워크스페이스: 서로 독립된 작업 화면
- Floating: 타일에서 분리해 자유롭게 움직이는 창
- Scratchpad: 필요할 때만 꺼내 쓰는 숨김 공간

### 방향 문법

방향 동작은 항상 같은 규칙을 따른다.

- `Super+방향`: 초점 이동
- `Super+Shift+방향`: 창 이동
- `Super+Ctrl+좌우`: 모니터 사이의 초점 이동
- `Super+Ctrl+Shift+좌우`: 현재 워크스페이스를 다른 모니터로 이동

H/J/K/L이 익숙하지 않으면 방향키를 그대로 사용해도 된다.

## 전체 키맵

### 애플리케이션과 도구

| 키 | 동작 |
|---|---|
| `Super+Enter` | Alacritty 터미널 |
| `Super+D` | Fuzzel 애플리케이션 실행기 |
| `Super+Ctrl+B` | Google Chrome |
| `Super+Ctrl+E` | Thunar 파일 관리자 |
| `Super+Ctrl+A` | 오디오 설정 |
| `Super+Ctrl+D` | 디스플레이 설정 |
| `Super+F1` | 이 안내서 열기 |

### 창 초점과 이동

| 키 | 동작 |
|---|---|
| `Super+H/J/K/L` | 왼쪽/아래/위/오른쪽 창에 초점 |
| `Super+방향키` | 같은 동작의 방향키 버전 |
| `Alt+Tab` | 다음 창 |
| `Alt+Shift+Tab` | 이전 창 |
| `Super+Shift+H/J/K/L` | 창을 해당 방향으로 이동 |
| `Super+Shift+방향키` | 같은 동작의 방향키 버전 |
| `Super+A` | 부모 컨테이너에 초점 |
| `Super+Space` | 타일 창과 Floating 창 사이의 초점 전환 |
| `Super+Shift+Space` | 현재 창의 Floating 상태 전환 |
| `Super+Shift+Q` | 현재 창 닫기 |

파일 선택창, 저장창, 오디오·네트워크·블루투스 설정창은 자동으로 Floating 배치된다.

### 레이아웃

| 키 | 동작 |
|---|---|
| `Super+B` | 다음 창을 좌우로 분할 |
| `Super+V` | 다음 창을 위아래로 분할 |
| `Super+S` | Stacking 레이아웃 |
| `Super+W` | Tabbed 레이아웃 |
| `Super+E` | 현재 컨테이너의 분할 방향 전환 |
| `Super+F` | 전체 화면 전환 |

`Super+B`와 `Super+V`는 현재 창을 즉시 움직이는 키가 아니다. 다음에 열거나 이동해 넣는 창이 배치될 방향을 지정한다.

### 크기 조절

`Super+R`을 누르면 Resize 모드가 된다. Waybar에 현재 모드가 표시된다.

| Resize 모드 키 | 동작 |
|---|---|
| `H` 또는 `Left` | 너비 줄이기 |
| `L` 또는 `Right` | 너비 늘리기 |
| `K` 또는 `Up` | 높이 줄이기 |
| `J` 또는 `Down` | 높이 늘리기 |
| `Enter` 또는 `Escape` | Resize 모드 종료 |

### 워크스페이스와 모니터

| 키 | 동작 |
|---|---|
| `Super+1` … `Super+0` | 워크스페이스 1~10으로 이동 |
| `Super+Shift+1` … `Super+Shift+0` | 현재 창을 워크스페이스 1~10으로 이동 |
| `Super+Ctrl+H/L` | 왼쪽/오른쪽 모니터로 초점 이동 |
| `Super+Ctrl+Shift+H/L` | 현재 워크스페이스를 다른 모니터로 이동 |

Waybar에는 모든 출력의 워크스페이스가 표시된다. 워크스페이스 번호를 클릭하거나 마우스 휠로 이동할 수도 있다.

### Scratchpad

| 키 | 동작 |
|---|---|
| `Super+Shift+-` | 현재 창을 Scratchpad로 보내기 |
| `Super+-` | Scratchpad 창 표시 또는 숨기기 |

계산기, 음악 플레이어, 임시 터미널처럼 항상 열어 두되 화면을 차지하지 않아야 하는 창에 적합하다.

### 알림, 클립보드, 패널

| 키 | 동작 |
|---|---|
| `Super+N` | 알림센터 열기/닫기 |
| `Super+C` | 클립보드 기록 검색 및 붙여넣기 준비 |
| `Super+Ctrl+C` | 확인 후 클립보드 기록 전체 삭제 |
| `Super+Shift+B` | Waybar 표시/숨김 |

알림센터 안에서는 `Shift+D`로 방해 금지를 전환하고 `Shift+C`로 알림을 모두 지울 수 있다. `Escape`로 닫는다.

클립보드 검색에서 항목을 선택하면 해당 내용이 시스템 클립보드로 복사된다. 이후 애플리케이션의 일반 붙여넣기 키를 사용한다.

Cliphist는 최근 텍스트와 이미지를 로컬 캐시에 저장하므로 복사한 비밀번호 같은 민감한 내용도 기록될 수 있다. 기본값은 최대 100개, 항목당 1 MiB로 제한한다. 민감한 내용을 복사한 뒤에는 `Super+Ctrl+C`로 기록을 지운다.

### 스크린샷

| 키 | 동작 |
|---|---|
| `Print` | 전체 화면을 클립보드로 복사 |
| `Shift+Print` | 선택 영역을 클립보드로 복사 |
| `Super+Print` | 선택 영역을 `~/Pictures/Screenshots`에 저장 |

영역 선택을 취소하려면 `Escape`를 누른다.

### 오디오, 밝기, 미디어

키보드에 해당 기능 키가 있을 때 다음 동작이 활성화된다.

| 키 | 동작 |
|---|---|
| 볼륨 높임/낮춤 | 기본 출력 볼륨 조절과 OSD 표시 |
| 음소거 | 출력 음소거 전환 |
| 마이크 음소거 | 기본 입력 음소거 전환 |
| 화면 밝기 높임/낮춤 | 백라이트가 있는 랩탑에서 밝기 조절 |
| 재생/일시정지 | 현재 MPRIS 플레이어 제어 |
| 이전/다음 트랙 | 현재 MPRIS 플레이어 제어 |

데스크톱처럼 배터리나 백라이트가 없는 시스템에서는 관련 Waybar 모듈과 키 동작이 조용히 비활성화된다.

### 세션

| 키 | 동작 |
|---|---|
| `Super+Ctrl+L` | 즉시 잠금 |
| `Super+Shift+C` | Sway 설정 다시 읽기 |
| `Super+Shift+E` | 잠금·절전·로그아웃·재부팅·종료 메뉴 |

종료와 재부팅에는 직접 단축키를 두지 않는다. 세션 메뉴를 거쳐 실수로 종료하는 일을 막는다.

## 일상 작업 예시

### 터미널 두 개를 좌우로 배치하기

1. `Super+Enter`로 첫 터미널을 연다.
2. `Super+B`로 좌우 분할을 선택한다.
3. `Super+Enter`로 두 번째 터미널을 연다.
4. `Super+H/L`로 두 창을 오간다.

### 브라우저를 다른 워크스페이스로 보내기

1. 브라우저에 초점을 둔다.
2. `Super+Shift+2`로 창을 워크스페이스 2에 보낸다.
3. `Super+2`로 브라우저 워크스페이스로 이동한다.

### 임시 창을 자유 배치하기

1. 창에 초점을 둔다.
2. `Super+Shift+Space`로 Floating으로 바꾼다.
3. `Super`를 누른 채 마우스 왼쪽 버튼으로 이동한다.
4. `Super`를 누른 채 마우스 오른쪽 버튼으로 크기를 바꾼다.

### 발표나 긴 영상 중 자동 잠금 막기

Waybar의 `IDLE` 항목을 클릭해 `INHIBIT`으로 바꾼다. 작업이 끝나면 다시 클릭해 잠금과 절전을 활성화한다.

## 한글 입력

Fcitx5가 세션 입력기를 관리한다.

- `Right Alt`: 한/영 전환
- `Ctrl+Space`: 한/영 전환 대체 키
- Neovim에서 Insert 모드를 나오면 영문 입력으로 자동 복귀

입력기가 보이지 않거나 일부 애플리케이션에서만 동작하지 않으면 다음을 확인한다.

```sh
systemctl --user status fcitx5.service
fcitx5-remote
fcitx5-diagnose
```

`fcitx5-remote` 결과는 일반적으로 비활성 `1`, 활성 `2`, 실행되지 않음 `0`을 의미한다.

## 데스크톱과 랩탑 출력 구성

공용 Sway 설정은 출력 이름, PCI 주소, 해상도, 배율을 하드코딩하지 않는다. 연결된 출력은 우선 Sway의 기본값으로 켜지고, `Super+Ctrl+D`의 Wdisplays로 현재 세션에서 조정한다.

자주 사용하는 구성을 자동 적용하려면 먼저 안정적인 출력 설명을 확인한다.

```sh
swaymsg -t get_outputs
```

`name`은 도킹 순서에 따라 달라질 수 있으므로 가능하면 `make`, `model`, `serial`을 결합한 설명을 Kanshi에서 사용한다. 다음은 실제 값으로 바꾸기 위한 예시다.

```conf
profile desktop {
  output "EXTERNAL_VENDOR MODEL SERIAL" mode preferred position 0,0 scale 1
}

profile laptop {
  output "INTERNAL_VENDOR PANEL SERIAL" mode preferred position 0,0 scale 1.25
}

profile docked {
  output "INTERNAL_VENDOR PANEL SERIAL" disable
  output "EXTERNAL_VENDOR MODEL SERIAL" mode preferred position 0,0 scale 1
}
```

프로필은 `~/.config/kanshi/local.conf`에 기록한 뒤 다음 명령으로 다시 읽는다. 이 파일은 공용 dotfile의 include 대상이지만 리포 복사본 밖에 있으므로 `setup_dotfiles.sh`를 다시 실행해도 유지된다.

```sh
systemctl --user reload-or-restart kanshi.service
```

랩탑 덮개 동작은 systemd-logind의 Arch 기본 정책을 따른다. 일반적으로 배터리 사용 중 덮개를 닫으면 절전하고, 도킹 상태에서는 외부 모니터 사용을 방해하지 않는다. 공용 설정에서 특정 내장 패널 이름을 끄는 규칙을 만들지 않는다.

## Waybar 사용법

오른쪽 상태 영역은 하드웨어와 서비스가 존재할 때만 의미 있는 값을 표시한다.

- `IDLE/INHIBIT`: 자동 잠금과 절전 허용 여부
- 네트워크: 클릭하면 연결 편집기
- Bluetooth: 클릭하면 장치 관리자
- 볼륨: 클릭하면 믹서, 오른쪽 클릭하면 음소거
- 밝기: 랩탑에서 스크롤로 조절
- 배터리: 랩탑의 충전량과 예상 시간
- 전원 프로필: balanced, performance, power saver
- 알림: 클릭하면 알림센터, 오른쪽 클릭하면 방해 금지
- `POWER`: 세션 메뉴

트레이에는 NetworkManager, Blueman, Fcitx5, 이동식 미디어 상태처럼 백그라운드 서비스가 제공하는 아이콘이 표시된다.

로그인 비밀번호는 GNOME 셸이 아니라 독립형 Secret Service인 GNOME Keyring을 잠금 해제하는 데에도 사용된다. NetworkManager, Chrome, Flatpak 애플리케이션의 비밀번호를 세션마다 다시 입력하지 않도록 하기 위한 구성이다.

## 화면 공유

Sway에서는 `xdg-desktop-portal-wlr`가 화면 캡처를 담당하고 `xdg-desktop-portal-gtk`가 파일 선택 같은 일반 인터페이스를 보완한다. 브라우저나 회의 앱에서 화면 공유를 시작하면 출력 또는 영역 선택 UI가 나타나야 한다.

문제가 있으면 세션 환경과 서비스를 확인한다.

```sh
systemctl --user show-environment | rg 'WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP'
systemctl --user status xdg-desktop-portal.service xdg-desktop-portal-wlr.service
journalctl --user -b -u xdg-desktop-portal -u xdg-desktop-portal-wlr
```

## 자동 잠금과 절전

- 15분 동안 입력이 없으면 잠금
- 잠금 후 1분이 지나면 출력 절전
- 입력이 재개되면 출력 복구
- 2시간 동안 입력이 없으면 시스템 절전
- systemd가 절전에 들어가기 직전에 항상 잠금

영상 플레이어나 브라우저가 idle inhibit 프로토콜을 사용하면 재생 중 잠금이 지연될 수 있다. 수동 제어가 필요하면 Waybar의 `IDLE` 항목을 사용한다.

## 문제 해결과 복구

### Sway가 시작되지 않을 때

1. `Ctrl+Alt+F3`으로 TTY로 이동한다.
2. 로그인한다.
3. greetd와 현재 부팅 로그를 확인한다.

```sh
systemctl status greetd.service
journalctl -b -u greetd.service
```

Sway를 직접 실행해 설정 오류를 확인할 수 있다.

```sh
/usr/local/bin/start-sway -d
```

NVIDIA 모듈이 로드된 시스템에서는 런처가 `--unsupported-gpu`를 자동으로 추가한다. Intel/AMD 전용 시스템에는 해당 플래그를 추가하지 않는다.

### 패널이나 알림이 사라졌을 때

```sh
systemctl --user status sway-session.target
systemctl --user restart waybar.service swaync.service
journalctl --user -b -u waybar.service -u swaync.service
```

### 전체 데스크톱 서비스를 다시 시작할 때

열린 애플리케이션과 Sway 자체는 유지하면서 패널·알림·입력기·애플릿만 다시 시작한다.

```sh
systemctl --user restart sway-session.target
```

### 설정 오류 검사

실행 중인 Sway에서 다음 명령을 사용한다.

```sh
swaymsg reload
swaymsg -t get_version
swaymsg -t get_outputs
swaymsg -t get_inputs
```

### GNOME 제거 전 임시 복구

최종 검증 전까지 GDM이 아직 설치돼 있다면 TTY에서 로그인 관리자를 되돌릴 수 있다.

```sh
sudo systemctl disable greetd.service
sudo systemctl enable --force gdm.service
sudo reboot
```

GNOME을 제거한 뒤에는 TTY에서 `/usr/local/bin/start-sway`를 직접 실행해 문제를 진단한다. 리포에는 GNOME과 Sway의 이중 설정을 유지하지 않는다.

## 키맵 변경 규칙

1. 전역 창 관리 키는 `Super`를 기본 수정자로 사용한다.
2. 애플리케이션 내부의 `Ctrl`·`Alt` 단축키를 불필요하게 가로채지 않는다.
3. 방향 동작은 H/J/K/L과 방향키 문법을 유지한다.
4. 종료·재부팅처럼 상태를 잃을 수 있는 동작은 확인 메뉴를 거친다.
5. 새로운 모드는 `Escape`로 빠져나올 수 있어야 한다.
6. `config/sway/config`와 이 문서를 같은 변경에서 갱신한다.
7. 데스크톱과 랩탑 중 한쪽에만 있는 키나 장치는 존재하지 않을 때 조용히 실패해야 한다.

## 주요 설정 위치

| 대상 | 위치 |
|---|---|
| Sway와 키맵 | `~/.config/sway/config` |
| 패널 | `~/.config/waybar/` |
| 알림센터 | `~/.config/swaync/` |
| 실행기 | `~/.config/fuzzel/fuzzel.ini` |
| 클립보드 기록 | `~/.config/cliphist/config` |
| 화면 잠금 | `~/.config/swaylock/config` |
| 공용 모니터 설정 | `~/.config/kanshi/config` |
| 장비별 모니터 프로필 | `~/.config/kanshi/local.conf` |
| 한글 입력 | `~/.config/fcitx5/` |
| 세션 서비스 | `~/.config/systemd/user/` |

각 프로그램의 상세 문법은 Arch에 설치된 매뉴얼에서 확인한다.

```sh
man 5 sway
man 5 sway-input
man 5 sway-output
man 5 kanshi
man 1 swayidle
```
