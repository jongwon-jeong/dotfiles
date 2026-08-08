# Sway 데스크톱 사용 안내

이 문서는 이 리포가 구성하는 Sway 단일 데스크톱의 사용법과 복구 절차를 설명한다. 공용 설정의 기준 파일은 `config/sway/config`이며, 키를 변경할 때는 이 문서도 같은 변경에서 갱신한다.

## 5분 빠른 시작

`Super`는 일반 키보드의 Windows 키 또는 Command 키에 해당한다.

처음에는 다음 키만 기억하면 된다.

| 키 | 동작 |
|---|---|
| `Super+Enter` | 터미널 열기 |
| `Super+D` | 애플리케이션 검색 |
| `Super+P` | 열린 창 전체 검색 |
| `Super+Shift+P` | 표준 사용자 폴더의 파일 검색 |
| `Super+H/J/K/L` 또는 방향키 | 창 사이의 초점 이동 |
| `Super+Shift+H/J/K/L` 또는 방향키 | 창 위치 이동 |
| `Super+Tab` | 직전에 사용한 워크스페이스로 돌아가기 |
| `Super+1` … `Super+0` | 워크스페이스 1~10으로 이동 |
| `Super+Shift+1` … `Super+Shift+0` | 현재 창을 워크스페이스로 보내기 |
| `Super+F` | 전체 화면 전환 |
| `Super+Q` | 현재 창 닫기 |
| `Super+Esc` | 화면 잠금 |
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
- `Super+O`: 출력 조작 모드

H/J/K/L이 익숙하지 않으면 방향키를 그대로 사용해도 된다.

## 전체 키맵

### 애플리케이션과 도구

| 키 | 동작 |
|---|---|
| `Super+Enter` | Alacritty 터미널 |
| `Super+D` | Fuzzel 애플리케이션 실행기 |
| `Super+P` | 모든 워크스페이스의 열린 창 검색 |
| `Super+Shift+P` | Documents, Downloads, 미디어와 Projects 파일 검색 |
| `Super+F1` | 이 안내서 열기 |
| `Super+Shift+C` | Sway 설정 다시 읽기 |

Chrome, Thunar, Calculator, Disk Usage Analyzer와 그래픽 설정 도구는 `Super+D`에서 이름을 검색해 실행한다. `System Monitor (btop)`과 `Text Editor (Neovim)`도 동일한 실행기에서 찾을 수 있다.

`Super+P`는 창 제목과 애플리케이션 이름을 사용해 현재 열려 있는 모든 워크스페이스의 창을 찾는다. 목록은 호출한 동안에만 표시하며 Waybar에는 창 제목을 계속 노출하지 않는다. `Super+Shift+P`는 별도 색인을 만들지 않고 표준 사용자 폴더와 `~/Projects`를 호출할 때 검색한 뒤 기본 애플리케이션으로 연다. 대규모 의존성·빌드·IDE 메타데이터 디렉터리는 검색에서 제외한다.

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
| `Super+Shift+A` | 자식 컨테이너로 초점 복귀 |
| `Super+Space` | 타일 창과 Floating 창 사이의 초점 전환 |
| `Super+Shift+Space` | 현재 창의 Floating 상태 전환 |
| `Super+Q` | 현재 창 닫기 |

파일 선택창, 저장창, 오디오·네트워크·블루투스 설정창은 자동으로 Floating 배치된다.
일반 창이 예상과 달리 작은 창으로만 보이면 먼저 그 창에 초점을 두고
`Super+Shift+Space`를 눌러 타일 상태로 되돌린다. 이동과 상태 전환 단축키는
마우스 아래 창이 아니라 현재 초점을 받은 창에 적용된다.

### 레이아웃

| 키 | 동작 |
|---|---|
| `Super+B` | 현재 컨테이너를 좌우 분할로 전환 |
| `Super+V` | 현재 컨테이너를 위아래 분할로 전환 |
| `Super+S` | Stacking 레이아웃 |
| `Super+W` | Tabbed 레이아웃 |
| `Super+E` | 현재 컨테이너의 분할 방향 전환 |
| `Super+Shift+E` | 불필요한 단일 자식 분할 한 단계 해제 |
| `Super+F` | 전체 화면 전환 |

`Super+B`와 `Super+V`는 현재 컨테이너의 레이아웃을 직접 바꾼다. 반복 입력해도 다음 창을 위한 단일 자식 컨테이너가 중첩되지 않으므로 Tabbed 제목에 `H[V[…]]` 같은 내부 구조가 나타나지 않는다.

컨테이너 구조를 확인하려면 `Super+A`로 부모 방향으로 올라가고 `Super+Shift+A`로 자식 방향으로 돌아온다. 실수로 만든 단일 자식 분할은 그 안의 창에 초점을 둔 채 `Super+Shift+E`를 누르면 한 단계 제거된다. `H[V[V[…]]]`처럼 여러 단계라면 표시가 사라질 때까지 같은 키를 반복한다. 여러 창을 실제로 묶고 있는 컨테이너에는 이 명령이 적용되지 않으므로 정상적인 그룹을 실수로 풀지 않는다.

### 크기 조절

`Super+R`을 누르면 Resize 모드가 된다. Waybar에 현재 모드가 표시된다.

| Resize 모드 키 | 동작 |
|---|---|
| `H` 또는 `Left` | 너비 10px 줄이기 |
| `L` 또는 `Right` | 너비 10px 늘리기 |
| `K` 또는 `Up` | 높이 10px 줄이기 |
| `J` 또는 `Down` | 높이 10px 늘리기 |
| 위 조합에 `Shift` 추가 | 같은 방향으로 1px 미세 조절 |
| `Enter` 또는 `Escape` | Resize 모드 종료 |

### 워크스페이스와 모니터

| 키 | 동작 |
|---|---|
| `Super+Tab` | 직전에 사용한 워크스페이스로 돌아가기 |
| `Super+1` … `Super+0` | 워크스페이스 1~10으로 이동 |
| `Super+Shift+1` … `Super+Shift+0` | 현재 창을 워크스페이스 1~10으로 이동 |
| `Super+O` | Output 모드 시작 |

| Output 모드 키 | 동작 |
|---|---|
| `H/L` 또는 `Left/Right` | 왼쪽/오른쪽 모니터로 초점 이동 |
| `Shift+H/L` 또는 `Shift+Left/Right` | 현재 워크스페이스를 다른 모니터로 이동 |
| `D` | Wdisplays를 실행하고 Output 모드 종료 |
| `Enter` 또는 `Escape` | Output 모드 종료 |

Waybar에는 해당 출력에서 현재 사용 중인 워크스페이스만 표시된다. 워크스페이스 번호를 클릭하거나 마우스 휠로 이동할 수도 있다.

제스처를 지원하는 터치패드에서는 세 손가락을 왼쪽으로 밀면 다음 워크스페이스, 오른쪽으로 밀면 이전 워크스페이스로 이동한다. 별도 제스처 daemon을 사용하지 않으며 터치패드가 없는 데스크톱에는 영향을 주지 않는다.

### Scratchpad

| 키 | 동작 |
|---|---|
| `Super+Shift+-` | 현재 창을 Scratchpad로 보내기 |
| `Super+-` | Scratchpad 창 표시 또는 숨기기 |

Scratchpad에 창이 있으면 Waybar 왼쪽에 `SP n`으로 개수만 표시한다. 창 제목과
애플리케이션 이름은 표시하지 않는다.

Scratchpad는 다른 데스크톱의 최소화 기능과 다르다. 창을 다시 표시하면 원래
창이나 위치를 복원하지 않고 현재 작업공간 위에 Floating으로 띄우며, 여러 창을
보냈다면 `Super+-`를 반복할 때 차례로 표시한다. 따라서 창을 보내기 전에 제목
테두리로 초점을 확인한다. 일반 창을 실수로 보냈다면 `Super+-`로 표시하고
`Super+Shift+Space`로 타일 상태로 되돌린다.

계산기, 음악 플레이어, 임시 터미널처럼 항상 열어 두되 화면을 차지하지 않아야
하는 창에 적합하다. JetBrains Toolbox처럼 알림 영역에 상주하는 애플리케이션은
창을 닫아도 백그라운드 실행을 유지하도록 설정하고 Waybar 알림 영역에서 다시
여는 편이 자연스럽다.

### 알림, 클립보드, 패널

| 키 | 동작 |
|---|---|
| `Super+N` | 알림센터 열기/닫기 |
| `Super+C` | 클립보드 기록 검색 및 붙여넣기 준비 |
| `Super+Ctrl+C` | 확인 후 클립보드 기록 전체 삭제 |

알림센터 안에서는 `Shift+D`로 방해 금지를 전환하고 `Shift+C`로 알림을 모두 지울 수 있다. `Escape`로 닫는다.

알림센터 상단의 빠른 설정 버튼은 Network, Bluetooth, Audio, Displays, Disks와 Printers 관리 화면을 연다. 버튼은 이미 설치된 각 기능의 전용 GUI를 호출할 뿐 하드웨어 상태를 임의로 전환하지 않는다.

방해 금지는 로그인할 때 항상 켜지므로 팝업 배너가 자동으로 나타나지 않는다. 알림은 현재 세션의 알림센터에만 쌓이고 `Super+N`으로 직접 확인할 수 있으며, 로그아웃할 때 모두 지운다. 필요한 동안만 `Shift+D` 또는 Waybar 알림 항목의 오른쪽 클릭으로 팝업을 다시 허용할 수 있다.

클립보드 검색에서 항목을 선택하면 해당 내용이 시스템 클립보드로 복사된다. 이후 애플리케이션의 일반 붙여넣기 키를 사용한다.

Cliphist는 최근 텍스트와 이미지를 현재 로그인용 runtime DB에 저장하므로 복사한 비밀번호 같은 민감한 내용도 기록될 수 있다. 기본값은 최대 100개, 항목당 1 MiB로 제한하고 Sway 로그인 시작과 종료에 전체 기록을 자동 삭제한다. 현재 세션에서도 즉시 지워야 하면 `Super+Ctrl+C`를 사용한다.

### 스크린샷

| 키 | 동작 |
|---|---|
| `Print` | 전체 화면을 `~/Pictures/Screenshots`에 저장 |
| `Shift+Print` | 선택 영역을 `~/Pictures/Screenshots`에 저장 |
| `Ctrl+Print` | 전체 화면을 클립보드로 복사 |
| `Ctrl+Shift+Print` | 선택 영역을 클립보드로 복사 |
| `Super+Print` | 선택 영역을 캡처해 주석 편집기로 열기 |
| `Super+Shift+Print` | 선택 영역 녹화 시작/종료 |

스크린샷을 저장하거나 클립보드로 복사하면 짧은 OSD가 표시된다. `Super+Print`의 Swappy에서는 화살표·도형·텍스트·블러를 추가한 뒤 `~/Pictures/Screenshots`에 저장하거나 클립보드로 복사할 수 있다. 영역 선택을 취소하려면 `Escape`를 누른다.

화면 녹화는 `~/Videos/Recordings`에 MP4로 저장한다. 같은 키를 다시 누르면 이 workflow에서 시작한 녹화를 정상 종료하며, 시작·중지·저장 결과는 OSD로 표시한다. 녹화 중에는 Waybar에 빨간 `REC`를 계속 표시한다. 마이크나 시스템 오디오를 실수로 수집하지 않도록 기본 녹화에는 소리를 포함하지 않는다.

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

화면 색온도는 기본 Sway 세션에서 자동으로 바꾸지 않는다. 필요할 때 `sunset on`으로 시작하면 위치 정보나 네트워크 조회 없이 시스템의 현지 시각만 사용해 19:00부터 4000 K로 서서히 낮추고 07:00부터 6500 K로 되돌린다. `sunset off`로 현재 세션에서 즉시 중지하고 `sunset status` 또는 인자 없는 `sunset`으로 상태를 확인한다.

20% 배터리 경고는 기본 방해 금지 정책에 따라 알림센터에 쌓인다. 10% critical 상태는 데이터 손실을 피하기 위해 알림센터 기록과 함께 OSD로 즉시 표시한다. 5%까지 내려가면 60초 종료 유예를 OSD로 알린 뒤 정상 종료한다. 유예 중 전원을 연결하거나 충전이 시작되거나 잔량이 5%를 넘으면 자동 종료를 취소한다. 이 정책은 시스템 배터리에만 적용되며 주변기기 배터리는 제외한다.

### 세션

| 키 | 동작 |
|---|---|
| `Super+Esc` | 즉시 잠금 |
| `Super+Shift+Esc` | 잠금·절전·로그아웃·재부팅·종료 메뉴 |

세션 메뉴와 클립보드 삭제 확인 창은 같은 조작을 다시 실행하면 닫힌다. 확인 버튼을 선택해 작업을 실행한 뒤에도 화면에 남지 않는다.

종료와 재부팅에는 직접 단축키를 두지 않는다. 세션 메뉴를 거쳐 실수로 종료하는 일을 막는다.

## 일상 작업 예시

### 다른 워크스페이스의 창이나 파일 찾기

1. 열린 창으로 이동하려면 `Super+P`를 누르고 애플리케이션 또는 창 제목 일부를 입력한다.
2. 파일을 찾으려면 `Super+Shift+P`를 누르고 파일 이름 일부를 입력한다.
3. 선택한 파일은 MIME 기본 애플리케이션으로 열리며, 텍스트 파일은 Alacritty 안의 Neovim으로 연다.

### 터미널 두 개를 좌우로 배치하기

1. `Super+Enter`로 첫 터미널을 연다.
2. `Super+B`로 좌우 분할을 선택한다.
3. `Super+Enter`로 두 번째 터미널을 연다.
4. `Super+H/L`로 두 창을 오간다.

### 실행기로 브라우저를 열어 다른 워크스페이스로 보내기

1. `Super+D`를 누르고 `Chrome`을 검색해 실행한다.
2. `Super+Shift+2`로 브라우저를 워크스페이스 2에 보낸다.
3. `Super+2`로 브라우저 워크스페이스로 이동한다.

### 임시 창을 자유 배치하기

1. 창에 초점을 둔다.
2. `Super+Shift+Space`로 Floating으로 바꾼다.
3. `Super`를 누른 채 마우스 왼쪽 버튼으로 이동한다.
4. `Super`를 누른 채 마우스 오른쪽 버튼으로 크기를 바꾼다.

### 발표나 긴 영상 중 자동 잠금 막기

Waybar의 `IDLE` 항목을 클릭해 `INHIBIT`으로 바꾼다. 작업이 끝나면 다시 클릭해 잠금과 절전을 활성화한다.

### 타일 경계 크기 조절하기

1. 조절할 창에 초점을 둔다.
2. `Super+R`로 Resize 모드에 들어간다.
3. `H/J/K/L` 또는 방향키로 경계를 움직인다.
4. `Enter` 또는 `Escape`로 기본 모드로 돌아간다.

### 워크스페이스를 다른 모니터로 옮기기

1. 옮길 워크스페이스로 이동한다.
2. `Super+O`로 Output 모드에 들어간다.
3. `Shift+H/L` 또는 `Shift+Left/Right`로 워크스페이스를 다른 출력으로 옮긴다.
4. `Enter` 또는 `Escape`로 Output 모드를 종료한다.

출력의 위치·회전·배율을 그래픽으로 조정하려면 Output 모드에서 `D`를 눌러 Wdisplays를 연다. Wdisplays를 열면 모드는 자동으로 종료된다.

### 화면을 캡처하거나 녹화하기

- 전체 화면을 파일로 남기려면 `Print`를 누른다.
- 영역을 파일로 남기려면 `Shift+Print`를 누르고 영역을 선택한다.
- 붙여넣을 이미지는 `Ctrl+Print` 또는 `Ctrl+Shift+Print`로 클립보드에 복사한다.
- 캡처를 가리거나 설명해야 하면 `Super+Print`로 영역을 고른 뒤 Swappy에서 편집한다.
- 영역 녹화는 `Super+Shift+Print`로 시작하고 같은 키로 종료한다.

스크린샷은 `~/Pictures/Screenshots`, 녹화는 `~/Videos/Recordings`에 저장되며 결과는 OSD로 확인한다. Waybar의 `REC`가 사라지면 녹화 프로세스가 종료되고 파일 정리가 끝난 상태다.

### 이전 클립보드 내용 다시 사용하기

1. `Super+C`로 클립보드 기록을 연다.
2. Fuzzel에서 텍스트 일부를 검색하거나 이미지 항목을 선택한다.
3. 대상 애플리케이션에서 일반 붙여넣기 키를 사용한다.

현재 세션의 기록을 모두 지우려면 `Super+Ctrl+C`를 누르고 확인한다. 확인 창은 같은 키로 취소할 수도 있다.

### 알림과 배터리 경고 확인하기

1. Waybar가 `DND!` 또는 `NOTIFY!`를 표시하면 `Super+N`으로 알림센터를 연다.
2. 팝업 알림이 필요한 동안에는 알림센터에서 `Shift+D`로 방해 금지를 해제한다.
3. 확인이 끝나면 `Escape`로 닫고 필요하면 방해 금지를 다시 켠다.

배터리 20% 경고는 알림센터에 쌓이며, 10% critical 상태는 OSD에도 즉시 표시된다. critical OSD가 보이면 작업을 저장하고 전원을 연결한다. 5%에서는 60초 뒤 자동 종료하므로 전원을 연결해 취소하거나 남은 작업을 즉시 정리한다.

### Thunar에서 일반 파일과 숨김 파일 오가기

1. `Super+D`에서 `Thunar`를 검색해 실행한다.
2. 왼쪽 `Places`에서 Downloads, Documents, Pictures 또는 Projects로 이동한다.
3. 숨김 설정 파일이 필요할 때만 `Ctrl+H`로 표시한다.
4. 작업이 끝나면 `Ctrl+H`를 다시 눌러 일반 파일 중심 보기로 돌아간다.

### Android 장치의 파일 열기

1. 잠금 해제한 Android 장치를 USB로 연결하고 장치에서 파일 전송 모드를 선택한다.
2. Thunar의 `Devices`에서 장치를 선택한다.
3. 작업이 끝나면 Thunar에서 마운트 해제한 뒤 케이블을 분리한다.

`gvfs-mtp`는 장치를 연결하고 파일을 열 때 D-Bus 요청으로 MTP backend를 활성화한다. 별도의 동기화나 원격 전송을 시작하지 않는다.

### 암호화 USB를 필요할 때만 열기

1. 외장 LUKS 장치를 연결하거나 연결된 상태로 부팅한다. 자동 암호창은 나타나지 않고 장치는 잠긴 상태로 남는다.
2. 사용할 때 Thunar의 `Devices` 또는 Udiskie 트레이 메뉴에서 장치를 직접 열고 암호를 입력한다.
3. 작업이 끝나면 열린 파일과 터미널을 닫고 파일시스템을 마운트 해제한다.
4. Udiskie 또는 Thunar에서 장치를 잠그거나 안전하게 제거한 뒤 분리한다.

잠금 해제는 사용자가 직접 요청할 때만 일어나며, 로그인이나 장치 연결만으로 암호를 묻지 않는다.

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

공용 Sway 설정은 출력 이름, PCI 주소, 해상도, 배율을 하드코딩하지 않는다. 연결된 출력은 우선 Sway의 기본값으로 켜지고, `Super+O` Output 모드에서 `D`를 눌러 Wdisplays로 현재 세션에서 조정한다.

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

전원 버튼은 실수로 즉시 종료하지 않도록 시스템 절전을 요청한다. 랩탑 덮개는 배터리와 외부 전원에서 모두 절전하고, 도킹됐거나 여러 출력이 연결된 상태에서는 외부 모니터 사용을 방해하지 않도록 무시한다. 이 정책은 systemd-logind가 담당하며 다음 부팅부터 적용된다. 공용 설정에서 특정 내장 패널 이름을 끄는 규칙은 만들지 않는다.

## GTK, 파일 관리자와 기본 애플리케이션

Thunar의 왼쪽 `Places`에는 Downloads, Documents, Pictures, Music, Videos와 Projects shortcut을 표시한다. Arch bootstrap을 실행할 때 GTK bookmarks를 이 기본 목록으로 교체한다.

Sway는 compositor이므로 GTK 애플리케이션 설정까지 직접 관리하지 않는다. 이 리포는 역할에 따라 다음처럼 분리한다.

- GTK 3·4의 밝은 테마, 고대비 아이콘·글꼴, 애니메이션, 시스템 이벤트음과 최근 파일 기록 여부는 각각의 `settings.ini`가 관리한다. `gtk.css`는 Paper 배경, 검정 글자와 작은 여백을 사용하는 공통 툴팁을 관리한다. 버튼·경고·입력 피드백음은 끄되 영상·음악의 일반 출력은 음소거하지 않는다.
- GTK 3·4 파일 선택기의 24시간 시계, 숨김 파일 기본 비표시, 폴더 우선 정렬, 목록 보기와 현재 디렉터리 시작은 GLib `gsettings`로 bootstrap 시 적용한다.
- Thunar는 상세 목록 보기, 숨김 파일 기본 비표시, 폴더 우선 정렬을 사용하고 이미지 미리보기와 썸네일 생성을 비활성화한다. 숨김 파일이 필요하면 `Ctrl+H`로 전환한다.
- 디렉터리는 Thunar, 텍스트·Markdown·JSON·XML·YAML은 Alacritty 안의 Neovim, 이미지는 Imv, 영상·음악은 mpv, PDF는 Zathura, 웹 URL은 Google Chrome으로 연다.
- `Text Editor (Neovim)`과 `System Monitor (btop)` 데스크톱 항목은 터미널 프로그램을 Fuzzel과 MIME 연결에서 일반 데스크톱 앱처럼 발견할 수 있게 한다. 별도 프로세스나 데이터를 추가하지 않는다.

`gsettings`는 GNOME Shell 전용 도구가 아니라 GLib 설정 저장 인터페이스이므로 Sway에서도 GTK 파일 선택기 설정에 사용하는 것이 맞다. 다만 Sway 설정을 다시 읽을 때마다 실행하지 않고, 설치 단계에서 한 번 적용해 compositor 수명주기와 분리한다.

관리하는 대화형 데스크톱 표면은 Paper 색을 기본 면으로 공유한다. 로그인 화면 바깥, 빈 출력과 잠금화면은 같은 따뜻한 중간 명도의 backdrop을 사용해 세션 전환 동안 이어지면서도 작업 면과 구분한다. ReGreet의 입력 frame과 swaylock 상태 표시는 Paper 면을 유지한다. 영역 구분이 필요하면 별도의 흰 카드보다 명확한 테두리를 먼저 사용한다. 평상시 글자는 기본 굵기와 읽는 데 필요한 최소 여백을 유지하며, 대비·크기·불필요한 그림자 제거로 먼저 가독성을 확보한다. 굵은 글자와 강한 배경색은 선택, 집중, 경고처럼 의미가 있는 상태에만 사용한다.

기본 시스템 사운드는 계층별로 끈다. GTK 이벤트·경고·입력 피드백음은 GTK 3·4 설정에서, 대화형 Zsh의 터미널 벨은 셸 설정에서, 커널의 레거시 PC 스피커 비프음은 `pcspkr`와 `snd_pcsp` 모듈 차단으로 비활성화한다. Alacritty와 GTK의 visual bell도 끄고, Sway 창과 Waybar 워크스페이스의 urgent 상태는 빨간색 대신 차분한 파란색으로만 구분한다. SwayNC는 항상 방해 금지 상태로 시작하므로 팝업 배너는 표시하지 않고 대기 중인 알림만 Waybar의 `DND!`로 알린다. 브라우저·메신저·알람 앱이 일반 미디어 스트림이나 자체 창으로 직접 표시하는 동작까지 막지는 않는다.

## Waybar 사용법

오른쪽 상태 영역은 하드웨어와 서비스가 존재할 때만 의미 있는 값을 표시한다.

- `IDLE/INHIBIT`: 자동 잠금과 절전 허용 여부
- 빨간 개인정보 표시: PipeWire 화면 공유 또는 마이크 입력 사용 중
- 빨간 `REC`: 이 구성에서 시작한 `wf-recorder` 녹화가 진행 중
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

Sway에서는 `xdg-desktop-portal-wlr`가 화면 캡처를 담당하고 `xdg-desktop-portal-gtk`가 파일 선택 같은 일반 인터페이스를 보완한다. 브라우저나 회의 앱에서 화면 공유를 시작하면 출력 또는 영역 선택 UI가 나타나고 Waybar에 빨간 화면 공유 표시가 나타나야 한다. PipeWire 마이크 입력을 사용하는 동안에도 별도의 빨간 표시가 나타난다. 개인정보를 위해 표시의 툴팁에는 애플리케이션 이름을 노출하지 않는다.

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

현재 저장장치는 zram swap만 사용하고 resume 구성이 없으므로 최대 절전은 제공하지 않는다. 배터리가 5%까지 내려가면 저장되지 않은 메모리 상태에 의존하는 절전 대신 60초 유예 후 정상 종료해 완전 방전 시 데이터 손실 위험을 줄인다.

장시간 build, test나 migration처럼 명령이 끝날 때까지만 시스템 절전을 막아야
하면 해당 명령을 `keep_awake`로 실행한다. Linux에서는 `systemd-inhibit`,
macOS에서는 `caffeinate`를 사용하며 명령이 끝나면 inhibitor도 함께 사라진다.

```sh
keep_awake npm test
keep_awake docker compose up
```

## SSH agent

Sway 세션은 `%t/ssh-agent.socket`에서 OpenSSH agent 하나를 관리한다. Fuzzel에서
실행한 GUI application과 terminal은 같은 socket을 사용하며, agent는 로그아웃할
때 세션 서비스와 함께 종료된다. 복호화된 identity는 메모리에만 유지되고 기본
수명은 8시간이다.

`sshload`는 `~/.ssh`의 key를 자동으로 탐색하지 않는다. 필요한 private key를
명시해야 하며 이때도 8시간 수명을 적용한다.

```sh
sshload ~/.ssh/id_ed25519_personal
sshload ~/.ssh/id_ed25519_work
ssh-add -l
```

`sshkill`은 다른 terminal이나 IDE가 만든 agent process를 검색해서 종료하지
않는다. 현재 shell이 직접 시작한 agent만 종료하고, Sway가 관리하는 agent에서는
현재 등록된 identity만 제거한다. SSH로 전달받은 agent와 macOS가 관리하는 agent는
기존 `SSH_AUTH_SOCK`을 우선하므로 Sway 전용 socket으로 덮어쓰지 않는다.

## 개인정보와 로컬 데이터 수명주기

이 데스크톱 구성은 백그라운드 텔레메트리나 자동 업데이트 조회를 추가하지 않는다. 패키지 갱신은 기존 `bubu`, `upall` 명령으로 사용자가 명시적으로 실행한다. Arch가 제공하는 NetworkManager의 주기적 HTTP 연결 상태 확인도 끄며, captive portal은 Wi-Fi 연결 후 브라우저를 직접 열어 사용한다. 야간 색온도는 위치를 조회하지 않고, 배터리 경고는 로컬 전원 정보만 읽으며, 화면 녹화는 기본적으로 오디오를 수집하지 않는다.

Waybar에는 활성 창 제목, Wi-Fi SSID, 네트워크 인터페이스·주소·게이트웨이, Bluetooth 장치 별칭과 오디오 장치명을 표시하지 않는다. 화면 공유나 촬영 중에도 연결 종류와 상태만 보이게 하며, 상세 정보가 필요할 때는 해당 상태 항목을 클릭해 사용자가 설정창을 연다.

로컬 정리 작업은 다음 항목만 대상으로 한다.

- GTK 최근 파일 기록은 생성 자체를 비활성화하고, 이를 무시하는 앱이 기록 파일을 만들면 path 감시가 즉시 삭제한다.
- 24시간이 지난 썸네일 캐시를 삭제한다. Thunar의 새 썸네일 생성 자체도 비활성화한다.
- 클립보드 기록은 권한이 `0700`인 `$XDG_RUNTIME_DIR/cliphist/` 아래에만 저장하고 Sway 로그인 시작에 DB를 비우며 종료할 때 runtime 디렉터리째 삭제한다.
- systemd journal은 최근 1일만 보존한다. bootstrap이 retention 설정을 설치하고 기존의 더 오래된 journal도 정리한다.
- ReGreet는 별도 파일 로그를 만들지 않고 경고 이상의 진단만 journal에 보내 같은 1일 보존 정책을 따른다.

`pclean`은 실행 전에 확인을 받고 표준 데스크톱 휴지통과 `del`이 사용하는 `~/.trash`, 클립보드와 Bash·Zsh 명령 기록, GTK 최근 파일, 전체 썸네일, 1일이 지난 setup 로그와 systemd journal을 정리한다. Arch에서는 `paccache`로 package별 최신 3개만 남기며 system journal과 package cache 단계에서 `sudo` 인증을 요청한다. 현재 셸의 메모리 기록과 표준 history 파일은 함께 비우지만 다른 열린 셸은 종료할 때 자체 메모리 기록을 다시 쓸 수 있으므로 함께 정리하거나 먼저 종료한다.

브라우저 방문 기록, 로그인 정보, 애플리케이션 데이터, 개발 도구의 빌드 캐시와 일반 다운로드 파일은 삭제하지 않는다. 범위를 넓히면 복구 기회를 잃거나 로그인 상태가 풀리고 반복 다운로드·재빌드가 발생할 수 있어, 개인정보 보호 효과와 복구 비용이 분명한 항목만 명시적으로 정리한다. 기존 NetworkManager MAC 무작위화, IPv6 privacy 주소와 firewalld 정책은 그대로 유지한다. Chrome이나 Flatpak 앱이 자체적으로 제공하는 동기화·사용 통계 전송은 각 애플리케이션의 설정 범위이며, 이 데스크톱 정책이 모든 앱의 외부 통신까지 차단한다고 가정하지 않는다.

1일 journal과 사용자가 실행하는 기록 정리는 장기 포렌식보다 로컬 개인정보 최소화를 우선하는 선택이다. 이 구성은 침해사고 조사 기록이나 조직의 보존 요구를 대신하지 않는다. AUR, upstream installer, release binary와 Flatpak remote도 각각 신뢰 경계이며, 이 저장소를 공급망 전체를 격리하는 hardened OS로 간주하지 않는다.

## 수동 업데이트와 유지관리

자동 업데이트 확인을 대신해 다음 명령을 사용자가 필요할 때 직접 실행한다. 예약 timer나 로그인 시 자동 실행은 구성하지 않으며, 각 명령은 실행한 시점에만 저장소나 vendor 서버에 접속한다.

| 명령 | 범위 | 참고 |
|---|---|---|
| `bubo` | Pacman, AUR, Flatpak의 사용 가능한 업데이트 확인 | 확인만 수행하며 실제 패키지를 변경하지 않는다. |
| `bubu` | `bubo` 확인 후 Pacman 전체 시스템, AUR, Flatpak 순서로 갱신 | Arch 시스템과 그래픽 애플리케이션의 일반 유지관리 명령이다. |
| `upall` | Mise, uv와 리포가 `cargo-binstall`로 관리하는 사용자 도구 갱신 | OS 패키지와 분리된 개발 도구만 다룬다. |
| `fwup` | 펌웨어 metadata 갱신과 사용 가능한 장치 firmware 설치 | AC 전원이나 재부팅이 필요할 수 있어 일반 패키지 갱신과 분리한다. |
| `pclean` | 휴지통, 로컬 개인정보 metadata, 셸 기록, 오래된 setup·system log와 Arch package cache 정리 | 실행 전 확인하며 journal과 setup log는 1일, package는 최신 3개를 남긴다. 브라우저 기록과 로그인 정보는 삭제하지 않는다. |

이 명령들은 서로 범위가 다르다. `bubu`만으로 개발 도구와 firmware까지 모두 갱신되거나, `upall`만으로 Arch 시스템이 갱신된다고 가정하지 않는다.

## 설치된 프로그램과 역할

Sway는 창 관리자 하나만 설치한다고 완전한 데스크톱이 되지 않는다. GNOME처럼 하나의 데스크톱 묶음이 제공하던 로그인 화면, 패널, 알림, 잠금, 화면 공유, 권한 요청, 저장장치 연결을 각각 작은 프로그램이 맡는다. 아래는 이번 Sway 전환에서 추가했거나 데스크톱 기능에 직접 연결한 주요 패키지다. compiler, 압축 도구, codec과 저수준 공용 library처럼 기존 CLI·개발 환경을 위한 패키지는 제외한다.

모든 프로그램이 계속 실행되는 것은 아니다.

- 시스템 서비스: 부팅 후 하드웨어나 운영체제 기능을 제공한다.
- Sway 세션 서비스: 로그인한 동안만 `sway-session.target`에 묶여 실행되고 로그아웃하면 함께 종료된다.
- 필요 시 실행: 단축키, 메뉴, 애플리케이션 요청이 있을 때만 잠깐 실행된다.
- 호환 계층과 라이브러리: 직접 창을 띄우지 않고 다른 애플리케이션이 Wayland나 시스템 기능을 사용하도록 돕는다.

### 로그인, 화면 구성과 Wayland 기반

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `sway` | Wayland compositor이자 타일링 창 관리자다. 모니터 출력, 입력 장치, 창 배치, 워크스페이스와 전역 단축키를 관리한다. | 로그인 후 실제 데스크톱 세션이 된다. `config/sway/config`가 공용 동작의 기준 파일이다. |
| `swaybg` | Sway 출력마다 배경 이미지 또는 단색 배경을 그리는 작은 보조 프로그램이다. | 현재는 로그인·잠금화면과 같은 따뜻한 중간 명도의 단색 backdrop을 모든 출력의 빈 공간에 표시한다. |
| `swayidle` | 사용자의 입력이 없는 시간을 감시하고 지정된 명령을 실행한다. | 잠금, 모니터 절전, 장시간 미사용 시 시스템 절전을 순서대로 실행하는 세션 서비스다. |
| `swaylock` | Wayland용 화면 잠금 프로그램이다. | 수동 잠금, idle 잠금, 시스템 절전 직전 잠금에 공통 backdrop과 Paper 상태 표시를 사용한다. 인증은 PAM을 사용한다. |
| `greetd` | 부팅 후 로그인과 사용자 세션 시작을 담당하는 display manager다. | GDM 대신 `tty1`을 소유하고, 인증이 끝나면 선택된 Sway 세션을 시작한다. 현재 세션을 방해하지 않도록 bootstrap에서는 활성화만 하고 다음 부팅부터 사용한다. |
| `greetd-regreet` | greetd용 GTK4 그래픽 로그인 화면인 ReGreet를 제공한다. 사용자, 비밀번호와 Wayland 세션을 선택한다. | 공통 backdrop 위에 Paper 입력 frame, 상단 시계와 하단의 재부팅·종료 버튼을 표시한다. `/usr/local/share/wayland-sessions`의 이 리포 전용 Sway 항목을 우선 발견하고 `/usr/local/bin/start-sway`를 실행한다. |
| `cage` | 애플리케이션 하나만 전체 화면으로 보여 주는 kiosk Wayland compositor다. | 사용자 데스크톱이 아니라 ReGreet 로그인 창만 안전하게 표시한다. 로그인 후 Cage는 끝나고 Sway가 별도 세션으로 시작된다. |
| `xorg-xwayland` | Wayland를 직접 지원하지 않는 X11 애플리케이션을 Sway 안에서 실행하는 호환 X 서버다. | 유지 대상은 native Wayland지만, 아직 X11만 지원하는 프로그램이 있을 때 자동으로 경계 역할을 한다. |
| `qt5-wayland`, `qt6-wayland` | Qt 5·6 애플리케이션이 XWayland를 거치지 않고 Wayland client로 실행되게 하는 platform plugin이다. | `QT_QPA_PLATFORM=wayland;xcb`와 함께 Wayland를 우선하고, 지원하지 않는 앱에는 X11 fallback을 허용한다. |
| `xdg-user-dirs` | Documents, Downloads, Pictures 같은 표준 사용자 디렉터리 위치를 관리한다. | 스크린샷 저장 위치와 GTK 파일 선택기 등이 동일한 사용자 디렉터리를 찾도록 한다. |

### 화면 공유, 파일 선택과 애플리케이션 연결

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `xdg-desktop-portal` | 브라우저, Flatpak과 일반 데스크톱 앱의 요청을 적절한 portal backend로 전달하는 D-Bus broker다. | 화면 공유, 파일 선택과 URI 열기 같은 portal 요청의 공통 입구다. 일반 애플리케이션 암호 저장은 별도의 Secret Service가 담당한다. |
| `xdg-desktop-portal-wlr` | wlroots compositor용 화면 캡처와 화면 공유 backend다. | Sway에서 브라우저와 회의 앱이 모니터 또는 영역을 공유할 때 PipeWire 영상 스트림을 만든다. |
| `xdg-desktop-portal-gtk` | GTK 기반 범용 portal backend다. | 파일 열기·저장처럼 `wlr` backend가 담당하지 않는 일반 데스크톱 요청을 처리한다. |
| `xdg-utils` | `xdg-open`, `xdg-mime`, `xdg-settings` 같은 데스크톱 독립 명령을 제공한다. | 터미널이나 애플리케이션이 URL과 파일을 기본 앱으로 열고 기본 브라우저를 조회·설정할 때 사용한다. |
| `gnome-keyring` | GNOME Shell과 독립적으로 사용할 수 있는 Secret Service와 암호 저장소다. | greetd PAM이 로그인 비밀번호로 keyring을 잠금 해제한다. NetworkManager, Chrome과 Flatpak 앱이 저장한 암호를 세션마다 다시 묻지 않게 한다. |
| `libsecret` | 애플리케이션이 Secret Service에 암호를 저장하고 읽는 공용 라이브러리와 도구다. | `gnome-keyring` 저장소를 사용하는 GTK·CLI 애플리케이션의 연결 계층이다. |

### 패널, 알림과 일상 조작

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `waybar` | Sway용 패널이다. 워크스페이스, Scratchpad 개수, 트레이, 일반화한 연결 상태, 개인정보 사용, 녹화, 오디오, 배터리, 시계와 세션 메뉴를 표시한다. | 활성 창 제목과 네트워크·장치 식별자는 숨긴다. PipeWire 화면 공유·마이크 사용과 이 구성의 녹화만 강한 상태색으로 알리고, 해당 기능이 끝나면 표시를 숨긴다. |
| `swaync` | 알림 daemon과 알림센터를 함께 제공한다. | 기본 방해 금지 상태에서 현재 세션의 알림을 모으고, 상단 빠른 설정 버튼으로 이미 설치된 네트워크·장치·오디오·출력·디스크·프린터 GUI를 연다. |
| `fuzzel` | Wayland native 애플리케이션 실행기이며 dmenu 호환 선택기다. | `Super+D`의 앱 검색, Cliphist 기록, 열린 창과 파일 선택 메뉴에 재사용한다. 창·파일 목록은 직접 호출한 동안에만 만든다. |
| `swayosd` | 볼륨, 마이크와 밝기 변경을 화면 중앙의 OSD로 보여 주고 해당 값을 조절한다. | 키보드의 미디어·밝기 키를 `swayosd-client`가 처리하고 세션의 `swayosd-server`가 결과를 표시한다. |
| `playerctl` | MPRIS 표준을 지원하는 미디어 player를 명령행에서 제어한다. | 재생·일시정지와 이전·다음 미디어 키를 현재 활성 player에 전달한다. player가 없으면 명령만 조용히 실패한다. |
| `libnotify` | 데스크톱 알림을 보내는 라이브러리와 `notify-send` 명령을 제공한다. | 스크립트와 프로그램이 SwayNC로 표준 알림을 보낼 때 사용한다. 알림을 직접 표시하는 daemon은 아니다. |
| `papirus-icon-theme` | GTK 앱, 트레이와 파일 형식에 일관된 아이콘을 제공한다. | 완전한 데스크톱 환경을 설치하지 않아도 실행기와 설정창에 아이콘이 빠지지 않게 한다. |

### 스크린샷과 클립보드

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `grim` | Wayland 출력 또는 지정한 좌표 영역을 이미지로 캡처한다. | 전체 화면을 클립보드로 보내거나 선택 영역을 PNG로 저장하는 실제 캡처 도구다. |
| `slurp` | 마우스로 화면의 사각형 영역을 선택하고 좌표를 출력한다. | `grim -g`에 전달할 영역을 정한다. `Escape`로 취소하면 파일을 만들지 않는다. |
| `swappy` | Wayland 스크린샷에 주석을 추가하는 편집기다. | `Super+Print`로 선택한 영역을 전달받아 화살표·도형·텍스트·블러를 추가하고 저장하거나 복사한다. 요청할 때만 실행한다. |
| `wf-recorder` | wlroots compositor의 화면을 영상 파일로 녹화한다. | `Super+Shift+Print`로 선택 영역을 녹화하고 같은 키로 종료한다. 개인정보 보호를 위해 기본 명령은 오디오를 포함하지 않는다. |
| `wl-clipboard` | Wayland 클립보드 명령인 `wl-copy`와 `wl-paste`를 제공한다. | 스크린샷·텍스트 복사, Cliphist 감시와 선택 항목 복원에 사용한다. |
| `cliphist` | Wayland 클립보드 내용을 로컬 데이터베이스에 기록하고 검색·복원한다. | 텍스트와 이미지를 별도 systemd 서비스가 수집한다. `Super+C`로 Fuzzel에서 고르고 `Super+Ctrl+C`로 기록을 지운다. |

### 입력기와 한글

`fcitx5-im`은 하나의 실행 파일이 아니라 Arch 패키지 그룹이며 다음 구성 요소를 함께 설치한다.

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `fcitx5` | 입력기 core daemon, 상태 제어 명령과 기본 모듈을 제공한다. | Sway 세션 서비스로 한 번만 실행되며 `Right Alt`와 `Ctrl+Space` 전환 상태를 관리한다. |
| `fcitx5-configtool` | 입력기 목록, 전환 키와 addon을 확인·조정하는 그래픽 설정 도구다. | 공용 설정에 없는 장비별 입력 문제를 진단하거나 현재 구성을 확인할 때 사용한다. |
| `fcitx5-gtk` | GTK 2·3·4 애플리케이션용 입력 모듈과 input method integration을 제공한다. | GTK 파일 관리자, 설정 도구와 XWayland GTK 앱에서도 조합 중인 한글이 정상 전달되게 한다. |
| `fcitx5-qt` | Qt 애플리케이션용 입력 모듈을 제공한다. | Qt 5·6의 native Wayland와 XWayland fallback 양쪽에서 Fcitx5 입력을 연결한다. |
| `fcitx5-hangul` | libhangul 기반 한국어 입력 엔진이다. | 두벌식 한글 조합과 한/영 전환의 실제 입력 엔진이다. Fcitx5 core만 설치하면 한글 엔진은 생기지 않는다. |

### 모니터와 랩탑·데스크톱 하드웨어

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `kanshi` | 연결된 모니터 조합을 감지해 저장된 출력 profile을 자동 적용한다. | 데스크톱, 랩탑 단독, docked 구성을 `~/.config/kanshi/local.conf`에서 장비별로 정의한다. profile이 없으면 Sway의 preferred mode를 그대로 둔다. |
| `wdisplays` | wlroots output-management protocol용 그래픽 모니터 설정 도구다. | `Super+O` Output 모드의 `D`에서 해상도, 위치, 회전과 배율을 시험한다. 자주 쓰는 결과만 Kanshi profile로 옮긴다. |
| `brightnessctl` | 커널 backlight와 LED 장치를 조회·조절하는 CLI다. | Waybar 밝기 모듈에서 스크롤 조절에 사용한다. 백라이트가 없는 데스크톱에서는 할 일이 없다. |
| `batsignal` | 배터리 충전량을 가볍게 감시해 경고와 위험 단계 동작을 실행한다. | 시스템 배터리를 대상으로 20%에서 알림센터 경고, 10%에서 OSD를 표시한다. 5%에서는 60초 유예 후 정상 종료하며 전원이 연결되거나 충전이 시작되면 취소한다. 주변기기 배터리는 제외하고 배터리가 없는 데스크톱에서는 조용히 종료한다. |
| `wlsunset` | Wayland 출력의 색온도를 현지 시각에 따라 조절한다. | 기본 Sway 세션에서는 시작하지 않는 선택 기능이다. `sunset on`, `sunset off`, `sunset status`로 현재 세션에서 제어하며 실행 중에도 위치나 네트워크를 사용하지 않는다. |
| `upower` | 배터리와 전원 장치 정보를 D-Bus로 제공하는 시스템 daemon이다. | Waybar와 데스크톱 앱이 충전량, 충전 상태와 남은 시간을 하드웨어별 구현 없이 읽게 한다. |
| `power-profiles-daemon` | `power-saver`, `balanced`, `performance` 전원 profile을 제공한다. | bootstrap이 기본값을 `balanced`로 맞추고 Waybar에서 현재 상태를 표시한다. profile 전환은 `powerprofilesctl set`으로 할 수 있으며, 지원하지 않는 하드웨어에서는 가능한 profile만 노출된다. |
| `switcheroo-control` | 내장 GPU와 외장 GPU가 함께 있는 시스템의 GPU 선택 정보를 D-Bus로 제공한다. | 하이브리드 그래픽 랩탑에서 지원 앱이 고성능 GPU 실행을 요청할 수 있게 한다. 단일 GPU 시스템에서는 사실상 대기한다. |

### 네트워크, Bluetooth, 저장장치와 인쇄

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `networkmanager`, `network-manager-applet` | NetworkManager는 유선·Wi-Fi·VPN 연결을 관리하고 applet 패키지는 트레이 아이콘과 `nm-connection-editor`를 제공한다. | 시스템 NetworkManager는 부팅 후 실행되고 `nm-applet`은 Sway 세션 동안만 실행된다. Waybar 네트워크 항목을 클릭하면 연결 편집기를 연다. |
| `firewalld` | 네트워크 zone과 입·출력 firewall 정책을 관리하는 시스템 서비스다. | fresh local bootstrap에서는 Arch `public` zone의 패키지 기본 SSH 허용을 제거한다. 기존 사용자 zone은 보존하고 SSH로 bootstrap을 실행하면 접속 유지를 위해 SSH를 허용한다. 그 밖의 unsolicited inbound 연결은 기본 차단하며 DNS, VPN과 기존 routing은 변경하지 않는다. |
| `bluez`, `bluez-utils`, `blueman` | BlueZ는 Linux Bluetooth protocol stack과 daemon, utils는 `bluetoothctl` 같은 CLI, Blueman은 그래픽 관리자와 선택적인 트레이 applet을 제공한다. | `bluetooth.service`는 시스템 기능을 제공한다. 중복되는 applet은 상주시하지 않고 Waybar가 연결 상태를 표시하며, 상태 항목이나 알림센터의 Bluetooth 버튼을 누르면 `blueman-manager`를 연다. |
| `polkit`, `lxqt-policykit` | Polkit은 일반 사용자의 권한 있는 시스템 작업을 중개하고 LXQt agent는 비밀번호 확인창을 표시한다. | 디스크 마운트, 네트워크 변경과 일부 시스템 설정이 필요할 때만 인증창이 나타난다. agent가 없으면 GUI 작업이 설명 없이 실패하거나 터미널 인증이 필요할 수 있다. |
| `udisks2`, `udiskie` | UDisks2는 디스크와 이동식 저장장치 작업을 D-Bus로 제공하고 Udiskie는 사용자 세션에서 자동 마운트·알림·트레이를 담당한다. | 일반 USB 저장장치는 사용자 권한으로 자동 마운트한다. 외장 LUKS 장치는 연결하거나 그 상태로 부팅해도 암호창을 자동으로 띄우지 않으며, Thunar나 Udiskie 트레이에서 직접 열 때만 암호를 묻는다. |
| `gnome-disk-utility` | GNOME 세션과 독립적으로 실행되는 GTK 디스크 관리 도구다. | Fuzzel에서 Disks를 찾아 필요할 때만 실행한다. UDisks2와 Polkit을 통해 장치 상태 확인, 파티션·파일시스템 관리와 디스크 이미지 작업을 제공하며 상시 서비스나 네트워크 연결을 추가하지 않는다. |
| `gvfs-mtp` | GVfs의 Android·미디어 장치용 MTP backend다. | USB 파일 전송 모드의 Android 장치를 Thunar `Devices`에 연결한다. 장치 접근 요청이 있을 때만 활성화하며 동기화 서비스는 제공하지 않는다. |
| `cups`, `system-config-printer`, `bluez-cups` | CUPS는 인쇄 queue와 driver backend, system-config-printer는 그래픽 설정, bluez-cups는 Bluetooth 프린터 연결을 제공한다. | 로컬 Unix socket은 준비해 두되 cupsd는 인쇄 클라이언트가 연결할 때만 시작한다. 프린터를 쓰지 않는 장비에는 scheduler process가 상주하지 않는다. |

### 기본 애플리케이션과 파일 통합

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `alacritty` | GPU 가속 터미널 emulator다. | `Super+Enter`의 기본 터미널이며 문서와 터미널 기반 도구를 여는 기반이다. |
| `pavucontrol` | PulseAudio 호환 API를 사용하는 PipeWire 그래픽 mixer다. | Fuzzel에서 실행하거나 Waybar 볼륨을 클릭해 앱별 볼륨, 입력·출력 장치와 profile을 조정한다. |
| `thunar` | 가벼운 GTK 파일 관리자다. | Fuzzel에서 실행하는 기본 파일 관리자다. GVfs, UDisks2와 함께 휴지통과 이동식 장치를 표시한다. |
| `tumbler` | Thunar가 썸네일 지원 형식을 조회하는 D-Bus 서비스다. | Thunar의 요청으로 활성화해 누락된 썸네일러 서비스 경고를 방지한다. 현재 설정에서는 Thunar가 미리보기 파일을 생성하지 않으며 Tumbler는 네트워크를 사용하지 않는다. |
| `thunar-volman` | 이동식 미디어가 연결됐을 때 Thunar 동작을 연결하는 volume manager다. | UDisks2가 발견한 USB 저장장치와 미디어를 파일 관리자 workflow에 통합한다. |
| `thunar-archive-plugin`, `xarchiver` | Thunar의 압축 메뉴와 실제 압축 파일 GUI backend를 제공한다. | 파일 관리자의 오른쪽 클릭 메뉴에서 압축 생성과 해제를 수행한다. plugin만 있고 backend가 없으면 메뉴가 작업을 완료하지 못한다. |
| `gvfs` | GTK 앱에 휴지통, 최근 파일, 마운트와 여러 가상 파일시스템 기능을 제공한다. | Thunar와 파일 선택기가 로컬 파일 외의 데스크톱 파일 기능을 일관되게 사용하도록 한다. |
| `gnome-calculator` | GNOME Shell과 독립적으로 실행되는 일반·공학·프로그래밍 계산기다. | Fuzzel에서 Calculator로 찾아 필요할 때만 실행하며 백그라운드 updater를 추가하지 않는다. 통화 변환은 외부 환율 정보에 의존하므로 네트워크를 원하지 않으면 해당 기능을 사용하지 않는다. 사용자 설정은 애플리케이션의 dconf 상태로 남으며 `pclean`이 지우지 않는다. |
| `baobab` | 폴더별 사용량을 트리와 그래프로 보여 주는 디스크 사용량 분석기다. | Fuzzel에서 Disk Usage Analyzer로 실행해 큰 디렉터리를 찾는다. 파일을 자동 정리하거나 삭제하지 않는다. |
| `imv` | Wayland와 X11을 지원하는 가벼운 이미지 viewer다. | 별도 데스크톱 사진 앱 없이 이미지 파일을 빠르게 확인한다. |
| `zathura`, `zathura-pdf-mupdf` | Zathura는 키보드 중심 문서 viewer이고 MuPDF plugin은 PDF를 실제로 해석한다. | PDF를 가볍게 열기 위한 조합이다. Zathura 본체만으로는 PDF backend가 없어 문서를 표시할 수 없다. |
| `mpv` | FFmpeg 기반 영상·음악 player다. | GPU 출력, 하드웨어 decoding과 이 리포의 회전·반전 키 설정을 사용하는 기본 미디어 player다. |
| `flatpak` | 배포판 패키지와 격리된 데스크톱 애플리케이션 runtime·설치 체계다. | bootstrap이 Flathub remote를 추가한다. Flatpak 앱의 파일 선택과 화면 공유는 위의 portal 계층을 통과한다. |

Bootstrap은 Intel GPU에 `vulkan-intel`과 `intel-media-driver`, AMD GPU에 Mesa와 `vulkan-radeon`, NVIDIA GPU에 `nvidia-utils`와 kernel에 맞는 open module을 설치한다. mpv는 안전 목록에 포함된 hardware decoder를 자동 선택하고 지원하지 않는 codec이나 실패한 driver에서는 software decoding으로 돌아간다. GStreamer 기반 애플리케이션은 `gst-plugin-va`로 Intel·AMD VA-API 경로를 사용하고, NVIDIA에서는 `gst-plugins-bad`의 NVDEC 경로를 사용한다.

### 어떤 프로세스가 언제 실행되는가

| 수명주기 | 주요 구성 요소 |
|---|---|
| 시스템 서비스, socket 또는 D-Bus 요청으로 실행 | greetd, NetworkManager, firewalld, Bluetooth, CUPS socket, UDisks2, UPower, power-profiles-daemon, switcheroo-control |
| 로그인 화면이 보이는 동안 실행 | Cage, ReGreet |
| Sway 로그인 동안 실행 | Sway, Waybar, SwayNC, Swayidle, SwayOSD, OpenSSH agent, Fcitx5, Kanshi, batsignal, nm-applet, LXQt Polkit agent, Udiskie, Cliphist 감시 서비스, 개인정보 정리 path·timer |
| 요청·이벤트·예약 시 활성화 | Fuzzel, Wdisplays, Grim, Slurp, Swappy, wf-recorder, Pavucontrol, Thunar, Blueman manager, CUPS scheduler, GVfs MTP backend, Calculator, Disk Usage Analyzer, Tumbler, portal backend, 파일·URL 기본 앱, 개인정보 정리 service |

Sway 세션용 daemon은 가능한 한 `config/systemd/user/`의 unit으로 관리한다. Sway 설정을 다시 읽어도 중복 실행되지 않는 것이 이 구조의 핵심이다. 로그아웃 helper는 먼저 제한 시간이 있는 정상 종료를 요청하고, launcher가 compositor 종료 직후 `sway-session.target`을 정리한다. 정상 종료에 실패한 경우에만 helper가 target을 멈춘 뒤 `SWAYSOCK`의 PID와 사용자·실행 명령을 다시 검증한 해당 process에 `SIGTERM`, 마지막으로 `SIGKILL`을 보낸다. 강제 종료까지 실패하고 Sway가 남으면 target을 다시 시작해 Waybar와 Fcitx5를 복구한다. 모든 종료 명령에 제한 시간을 두므로 응답 없는 IPC나 user service가 ReGreet 복귀를 무한정 막거나 실행 중인 desktop에서 세션 서비스만 사라진 상태를 유지하지 않는다. 비정상적인 compositor 종료 때도 즉시 재시작을 반복하지 않도록 그래픽 서비스의 재시작에는 짧은 지연을 둔다.

Sway, Xwayland와 직접 실행된 자식 process의 진단 출력은 로그인 TTY에 표시하지 않고 system journal의 `sway` identifier로 보낸다. 로그아웃 fallback은 `sway-logout` identifier를 사용하며 두 기록 모두 system journal의 1일 보존 정책을 따른다.

개인정보나 백그라운드 동작과 직접 관련된 구성 요소의 범위는 다음과 같다.

| 구성 요소 | 외부 네트워크 | 로컬 데이터와 종료 동작 | 하드웨어가 없을 때 |
|---|---|---|---|
| OpenSSH agent | 사용하지 않음 | 사용자가 등록한 복호화 identity를 최대 8시간 동안 메모리에만 유지하고 Sway 로그아웃 시 종료 | 하드웨어와 무관하게 동작하며 key를 등록하기 전에는 identity를 보관하지 않음 |
| SwayNC | 사용하지 않음 | 현재 세션의 알림을 보관하고 로그아웃 시 모두 지움 | 하드웨어와 무관하게 알림센터 제공 |
| Cliphist 감시 서비스 | 사용하지 않음 | 복사한 텍스트·이미지를 `0700` 전용 runtime 디렉터리의 DB에 저장하고 로그인 시작·종료에 전체 삭제 | 하드웨어와 무관하게 동작 |
| wlsunset | 사용하지 않음 | 기본적으로 실행하지 않으며, 직접 시작한 동안 현지 시각만 읽고 기록을 남기지 않음 | Sway 출력이 있는 세션에서만 의미 있음 |
| batsignal | 사용하지 않음 | 로컬 전원 정보를 읽고 별도 기록을 남기지 않으며 시스템 배터리 5%에서 유예 후 정상 종료 | 시스템 배터리가 없으면 조용히 종료 |
| 개인정보 정리 path·timer·service | 사용하지 않음 | `~/.local/share/recently-used.xbel`과 24시간이 지난 `~/.cache/thumbnails` 항목만 정리 | 대상 경로가 없으면 변경하지 않음 |
| NetworkManager | 실제 연결에 필요한 네트워크만 사용 | 연결 profile은 NetworkManager가 관리하며 주기적 HTTP 연결 확인은 비활성화 | Wi-Fi가 없어도 유선·VPN 관리에 사용 가능 |
| firewalld | 자체적인 외부 요청 없음 | 검토된 zone과 firewall 정책을 시스템에 유지 | 네트워크 장치 종류와 무관하게 정책 적용 |

## 문제 해결과 복구

### Sway가 시작되지 않을 때

1. `Ctrl+Alt+F3`으로 TTY로 이동한다.
2. 로그인한다.
3. greetd와 현재 부팅 로그를 확인한다.

```sh
systemctl status greetd.service
journalctl -b -u greetd.service
journalctl -b -t sway -t sway-logout
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

### 설정 적용 시점

설정 파일을 고친 뒤 필요한 적용 방법은 소유 구성 요소에 따라 다르다.

| 변경 대상 | 적용 방법 |
|---|---|
| `config/sway/config` | `scripts/setup_dotfiles.sh`로 배포한 뒤 `Super+Shift+C` 또는 `swaymsg reload` |
| `config/sway/scripts/logout-session` | `scripts/setup_dotfiles.sh`로 배포한 뒤 다음 로그아웃부터 적용 |
| `config/system/sway/start-sway` | bootstrap으로 `/usr/local/bin/start-sway`에 설치한 뒤 다음 Sway 로그인부터 적용 |
| Waybar·SwayNC 등 개별 user service 설정 | `scripts/setup_dotfiles.sh`로 배포하고 `systemctl --user daemon-reload` 후 해당 service 재시작 |
| 여러 Sway 세션 service와 unit 관계 | `scripts/setup_dotfiles.sh`로 배포하고 `systemctl --user daemon-reload` 후 `systemctl --user restart sway-session.target` |
| GTK `settings.ini`, MIME 연결, 애플리케이션별 설정 | `scripts/setup_dotfiles.sh`로 배포한 뒤 해당 애플리케이션을 완전히 다시 실행 |
| GTK 파일 선택기 GLib 설정 | bootstrap에서 적용하며, 이미 실행 중인 애플리케이션은 다시 실행 |
| NetworkManager privacy 설정 | bootstrap으로 `/etc`에 설치한 뒤 NetworkManager reload 또는 다음 부팅 |
| systemd journal 1일 보존 정책 | bootstrap으로 `/etc`에 설치하고 journald를 다시 시작한 직후 |
| systemd-logind 전원·덮개 정책, greetd, kernel module 차단 | bootstrap으로 설치한 뒤 재부팅 |

`systemctl --user restart sway-session.target`은 Sway 창 자체는 유지하지만 세션에 묶인 알림, 입력기, applet과 보조 service를 다시 시작한다. systemd-logind를 현재 그래픽 세션에서 강제로 재시작하는 대신 안전하게 재부팅한다.

### GNOME 제거 전 완료 확인

GNOME 제거는 다음 검증을 실제 사용하는 데스크톱과 랩탑에서 모두 통과한 뒤 별도의 검토된 변경으로 진행한다. 해당 장비에 없는 하드웨어 항목은 건너뛸 수 있지만 한 종류의 장비에서 성공한 결과를 다른 종류의 검증으로 대신하지 않는다.

이 목록은 공통 acceptance criteria이며 특정 장비의 완료 기록이 아니다. 여러 session에 걸쳐 검증한다면 작업을 소유한 issue나 PR에 기준 commit, 데스크톱·랩탑 구분, 실제 통과 항목, 건너뛴 이유, 남은 위험과 GNOME 제거 가능 여부를 기록한다. 대화에만 남은 결과나 다른 장비의 결과를 현재 장비의 evidence로 간주하지 않는다.

- [ ] 재부팅 후 ReGreet 로그인, Sway 시작과 GNOME Keyring 잠금 해제가 정상이다.
- [ ] ReGreet 로그인 직후 터미널을 먼저 열지 않아도 앱·창·파일 검색, btop·Neovim 실행과 텍스트 MIME 연결이 정상이다.
- [ ] 한글 입력, 키 반복, 터미널과 브라우저의 기본 키 동작이 정상이다.
- [ ] 단일·다중 모니터, hotplug, 해상도·배율·회전과 Kanshi profile이 정상이다.
- [ ] 랩탑의 밝기, 배터리 상태, 5% 자동 종료와 전원 연결 시 취소, 덮개, 전원 버튼, 절전과 복귀가 정상이다.
- [ ] 유선·Wi-Fi·VPN, Bluetooth, 오디오 입출력과 미디어 키가 정상이다.
- [ ] 화면 공유, 파일 선택기, 기본 파일·URL 연결과 권한 요청창이 정상이다.
- [ ] USB 저장장치, 휴지통과 필요한 경우 프린터가 정상이다.
- [ ] 수동·자동 화면 잠금, 알림센터, 클립보드 정리와 로그아웃 후 터미널 출력이나 수동 `Ctrl+C` 없이 ReGreet 복귀·재로그인이 정상이다.
- [ ] `Ctrl+Alt+F3` TTY 로그인과 `/usr/local/bin/start-sway` 진단 경로를 사용할 수 있다.

체크가 끝나기 전에는 GDM을 복구 수단으로 남길 수 있지만, 완료 후에는 GNOME과 Sway의 이중 데스크톱 구성을 정상 상태로 유지하지 않는다.

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
| 창·파일 검색과 화면 캡처 스크립트 | `~/.config/sway/scripts/` |
| 스크린샷 주석 편집기 | `~/.config/swappy/config` |
| 터미널 앱 데스크톱 항목 | `~/.local/share/applications/` |
| 클립보드 설정과 현재 세션 기록 | `~/.config/cliphist/config`, `$XDG_RUNTIME_DIR/cliphist/db` |
| GTK 3·4 외형과 최근 파일 정책 | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` |
| 기본 파일·URL 연결 | `~/.config/mimeapps.list` |
| Thunar 동작 | `~/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml` |
| 이동식 저장장치 자동 마운트 정책 | `~/.config/udiskie/config.yml` |
| 화면 잠금 | `~/.config/swaylock/config` |
| 공용 모니터 설정 | `~/.config/kanshi/config` |
| 장비별 모니터 프로필 | `~/.config/kanshi/local.conf` |
| 한글 입력 | `~/.config/fcitx5/` |
| 세션 서비스 | `~/.config/systemd/user/` |
| 로그인 화면과 ReGreet 외형 | `/etc/greetd/config.toml`, `/etc/greetd/regreet.toml`, `/etc/greetd/regreet.css` |
| 전원 버튼과 랩탑 덮개 정책 | `/etc/systemd/logind.conf.d/60-sway-desktop.conf` |
| system journal 보존 정책 | `/etc/systemd/journald.conf.d/60-privacy-retention.conf` |
| 레거시 PC 스피커 비프음 차단 | `/etc/modprobe.d/60-silent-system-sounds.conf` |

각 프로그램의 상세 문법은 Arch에 설치된 매뉴얼에서 확인한다.

```sh
man 5 sway
man 5 sway-input
man 5 sway-output
man 5 kanshi
man 1 swayidle
```
