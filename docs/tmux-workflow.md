# tmux 사용법

이 문서는 [`tmux.conf`](../config/tmux/tmux.conf)를 기준으로 한다. 설정이
바뀌면 이 문서보다 `tmux list-keys`와 실제 설정 파일을 우선한다.

prefix:

    `

아래의 "prefix d"는 backtick을 한 번 누른 뒤 d를 누른다는 뜻이다.
기본 prefix인 Ctrl-b는 해제되어 있다.


---

## 1. 기본 개념

    session : tmux의 가장 큰 작업 단위. 여러 window를 가진다.
    window  : session 안의 탭에 해당한다.
    pane    : window 안에서 분할된 terminal 영역이다.

detach는 session과 process를 종료하지 않고 현재 terminal에서만 빠져나온다.
shell에서 exit하면 현재 pane의 shell이 종료되며, 마지막 pane이면 window나
session도 함께 끝날 수 있다.


---

## 2. session

    tmux
        기본 이름으로 새 session 시작

    tmux new -s <session-name>
        이름을 지정해 새 session 생성

    tmux new -s <session-name> -n <window-name>
        session과 첫 window 이름을 함께 지정

    tmux ls
    tmls
        session 목록

    tmux attach -t <session-name>
    tmat <session-name>
        지정한 session에 attach

    tmux attach
        가장 최근 session에 attach

    tmux detach
    tmdt
        현재 client를 detach

    tmux kill-session -t <session-name>
    tmkl -t <session-name>
        지정한 session 종료

    prefix d
        현재 session에서 detach

    prefix s
        session 선택

    prefix (
        이전 session

    prefix )
        다음 session

    prefix $
        session 이름 변경


---

## 3. window

    prefix c
        현재 pane의 working directory에서 새 window 생성

    prefix <number>
        번호로 window 전환

    prefix n
        다음 window

    prefix p
        이전 window

    prefix `
        직전에 사용한 window로 전환

    prefix w
        window 목록

    prefix ,
        현재 window 이름 변경

    prefix &
        현재 window 종료

    Ctrl-Shift-Left
        prefix 없이 현재 window를 앞 번호로 이동하고 선택

    Ctrl-Shift-Right
        prefix 없이 현재 window를 뒤 번호로 이동하고 선택


---

## 4. pane 생성과 이동

    prefix |
        현재 pane의 working directory에서 좌우 분할

    prefix -
        현재 pane의 working directory에서 위아래 분할

    prefix h
        왼쪽 pane으로 이동

    prefix j
        아래 pane으로 이동

    prefix k
        위 pane으로 이동

    prefix l
        오른쪽 pane으로 이동

    prefix q
        pane 번호 표시

    prefix o
        다음 pane으로 이동

    prefix z
        현재 pane 확대 또는 원래 layout으로 복원

    prefix x
        현재 pane 종료 확인

    prefix !
        현재 pane을 새 window로 분리

    prefix Space
        predefined pane layout 전환


---

## 5. pane 크기와 동기화

    prefix Shift-Left
        왼쪽으로 2칸 조절

    prefix Shift-Right
        오른쪽으로 2칸 조절

    prefix Shift-Up
        위로 2칸 조절

    prefix Shift-Down
        아래로 2칸 조절

resize key는 repeat가 활성화되어 있어 prefix를 다시 누르지 않고 연속 입력할 수
있다.

정확한 크기를 지정하려면 command prompt를 사용한다.

    prefix :
    resize-pane -L 10

    prefix :
    resize-pane -R 10

    prefix :
    resize-pane -U 5

    prefix :
    resize-pane -D 5

    prefix y
        현재 window의 synchronize-panes를 toggle

synchronize-panes가 켜지면 한 pane의 키 입력이 모든 pane에 전달된다. 여러
서버에서 같은 명령을 실행할 때 유용하지만, 삭제·종료·암호 입력 전에 status를
확인한다. 다시 prefix y를 눌러 끈다.


---

## 6. copy mode와 clipboard

현재 copy mode는 vi key를 사용한다.

    prefix [
        copy mode 진입

    h j k l
        vi 방식으로 이동

    v
        문자 단위 선택 시작

    V
        줄 단위 선택 시작

    r
        rectangle selection toggle

    y
        선택을 복사하고 copy mode 종료

    q
        copy mode 종료

    prefix ]
        tmux paste buffer 붙여넣기

기본 copy-mode-vi의 Enter 복사는 해제되어 있으므로 선택 후 y를 사용한다.

clipboard 연동은 실행 환경에 따라 자동으로 선택된다.

    macOS            pbcopy
    Linux Wayland    wl-copy
    Linux X11        xclip
    WSL              clip.exe
    Git Bash/MINGW    /dev/clipboard

해당 명령이나 display 환경이 없으면 tmux 자체 buffer를 portable fallback으로
사용한다. SSH 서버에서 시스템 clipboard 도구가 없어도 y로 tmux buffer에는
복사할 수 있고 prefix ]로 붙여넣을 수 있다.

마우스 drag selection도 같은 clipboard 정책을 사용한다.


---

## 7. nested tmux와 prefix 전달

SSH로 접속한 서버 안에서도 tmux를 실행해 local tmux 안에 remote tmux가 중첩될
수 있다.

    prefix e
        현재 tmux의 prefix 입력을 안쪽 application에 전달

예를 들어 안쪽 tmux에서 새 window를 만들려면 바깥 tmux에서 다음 순서로
입력한다.

    prefix e c

`prefix + backtick`은 send-prefix가 아니라 last-window에 할당되어 있으므로
nested tmux prefix 전달에는 e를 사용한다.


---

## 8. 설정 확인과 reload

    prefix ?
        현재 key binding 목록

    tmux list-keys
        전체 binding 출력

    tmux show-options -g
        global session option 확인

    tmux show-options -gw
        global window option 확인

설정 reload:

    tmux source-file ~/.config/tmux/tmux.conf

dotfile이 ~/.tmux.conf에 연결된 환경이라면 실제 symlink 경로를 확인한 뒤 해당
파일을 지정한다.

    readlink -f ~/.tmux.conf

색상이 이상하면 tmux 안팎의 terminal 정보를 비교한다.

    printf '%s\n' "$TERM" "$COLORTERM" "$TERM_PROGRAM"
    tmux display-message -p '#{client_termname}'

현재 설정은 tmux 안에서 tmux-256color를 사용하고, 적합한 desktop terminal에만
COLORTERM=truecolor를 전달한다.


---

9. 입력이나 Enter가 동작하지 않을 때

증상:

    ssh-add, sudo password, REPL, fzf, shell prompt 등에서 입력 후 Enter가
    반응하지 않거나 terminal 상태가 꼬인 것처럼 보인다.

먼저 현재 modal state를 빠져나온다.

    Esc
    Ctrl-g
    q

    Esc    : application의 불완전한 입력 상태 취소
    Ctrl-g : readline, tmux command prompt, prefix 대기 취소
    q      : tmux copy mode 종료

그래도 이상하면 현재 pane에서 실행한다.

    stty sane
    reset

Enter가 동작하지 않으면 Ctrl-j를 Enter 대신 사용할 수 있다.

    stty sane
    Ctrl-j
    reset
    Ctrl-j

실행 중인 foreground process를 중단해도 될 때:

    Ctrl-c
    stty sane
    reset

pane의 process를 모두 버려도 될 때만 다음을 사용한다.

    tmux respawn-pane -k

`respawn-pane -k`는 window와 layout은 유지하지만 해당 pane에서 실행 중이던
process를 종료한다.


---

10. 빠른 요약

    prefix                 `
    이전 window            prefix `
    새 window              prefix c
    좌우 분할              prefix |
    위아래 분할            prefix -
    pane 이동              prefix h/j/k/l
    pane 크기              prefix Shift-arrow
    pane 동기화 toggle     prefix y
    copy mode              prefix [
    선택/복사              v 또는 V, y
    paste                  prefix ]
    detach                 prefix d
    nested prefix 전달     prefix e
