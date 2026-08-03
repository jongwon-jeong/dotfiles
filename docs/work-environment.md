# 업무 개발 환경 준비와 검증

개인 장비를 업무 개발에 사용해야 할 때, 이 dotfiles가 제공할 수 있는 기반과
회사·프로젝트가 결정해야 할 항목을 구분하고 실제 작업 전까지 검증할 순서를
정리한다. 목표는 개인 환경을 회사 환경처럼 미리 꾸미는 것이 아니라, 허용된
장비와 OS인지 먼저 확인한 뒤 드러난 요구사항만 machine-owned state로 적용하는
것이다.

회사 이름, email, 내부 host, SSH key, 인증서, VPN profile, token과 secret은
이 저장소에 기록하지 않는다. 실제 desktop·shell 동작은 이 저장소의 source와
현재 machine의 배포 상태를 기준으로 확인한다.

## 이 문서의 범위

이 문서는 다음 판단과 검증 순서를 소유한다.

- 개인 장비와 Arch Linux 사용이 허용되는지 판단한다.
- 업무 identity와 credential을 공유 dotfiles 밖에 둔다.
- VPN, SSH, project toolchain과 desktop workflow를 실제 업무 경로에서 검증한다.
- 지원되지 않는 보안 요구사항을 개인 설정으로 우회하지 않는다.

Git branch·review·release 방식, 지원 runtime과 container engine, VPN client,
보안 agent는 회사와 프로젝트의 문서가 우선한다. 이 저장소가 실제로 제공하는
동작은 다음 canonical source를 기준으로 확인한다.

| 제공 기능 | Canonical source |
|---|---|
| 경로별 Git identity 선택 | [`home/.gitconfig`](../home/.gitconfig) |
| Sway session SSH agent | [`ssh-agent.service`](../config/systemd/user/ssh-agent.service) |
| `sshload`, `sshkill`, `keep_awake` | [`aliases.sh`](../config/shell/aliases.sh) |
| desktop 운영과 개인정보 수명주기 | [Sway workflow](./sway-workflow.md) |

## 1. 회사 정책을 먼저 확인한다

개인 장비에 도구를 추가하기 전에 다음 항목을 확인한다.

- BYOD와 개인 network 사용이 허용되는가
- Arch Linux와 Sway가 지원 대상인가
- 회사 지급 장비만 사용해야 하는가
- MDM, EDR, DLP 또는 device certificate가 필수인가
- Secure Boot, TPM과 전체 disk 암호화 증빙이 필요한가
- 승인된 browser, VPN client와 password manager가 정해져 있는가
- source code와 업무 자료의 local backup이 허용되는가
- Codex와 다른 LLM에 입력할 수 있는 정보의 범위는 어디까지인가

회사 지급 장비나 지원 OS가 필수라면 개인 환경을 우회해서 연결하지 않는다.
이 단계에서 통과하지 못한 요구사항은 dotfiles 수정으로 해결할 문제가 아니다.
요구사항이 아직 확인되지 않았다면 VPN, container engine이나 보안 client를
추측해서 설치하지 않고 onboarding 정보가 확정될 때까지 보류한다.

## 2. 업무 정보는 machine-owned state로 둔다

업무 repository는 `~/Projects/work/` 아래에 두어 `home/.gitconfig`의
`includeIf`가 `~/.gitconfig-work`를 선택하게 한다. 실제 이름과 email은 local
file이 소유하며 그 값을 dotfiles에 기록하지 않는다.

```gitconfig
[user]
    name = <WORK_NAME>
    email = <WORK_EMAIL>
```

SSH host, key, certificate와 VPN profile의 실제 위치는 회사 절차에 맞추되 모두
machine-owned state로 유지한다. 회사에서 commit signing을 요구할 때만 회사가
정한 key와 방식을 `~/.gitconfig-work`에 추가한다.

실제 업무 repository에서 적용 결과를 확인한다.

```sh
git config --show-origin --get user.name
git config --show-origin --get user.email
git remote --verbose
```

구체적인 host alias와 `includeIf` 구조는 회사 요구와 machine-owned local
설정을 기준으로 정한다.

## 3. VPN과 내부 network

VPN package를 미리 여러 개 설치하지 않는다. 회사가 지정한 protocol과 client를
확인한 뒤 필요한 하나만 설치한다.

| 회사 요구 | 검토 대상 |
|---|---|
| WireGuard profile | NetworkManager의 native WireGuard 지원 |
| OpenVPN | NetworkManager OpenVPN plugin 또는 회사 지정 client |
| OpenConnect 계열 | NetworkManager OpenConnect plugin 또는 회사 지정 client |
| 전용 보안 client | Arch Linux 지원 여부와 회사 설치 절차 |

VPN profile, certificate와 credential은 NetworkManager나 회사가 지정한
credential store가 소유한다. 연결 후에는 인터넷 접속만 확인하지 말고 다음을
검증한다.

```text
내부 DNS
Git server
artifact 또는 package registry
issue tracker와 사내 문서
SSH bastion 또는 개발 server
```

개인 DNS나 firewall 정책을 바꾸기 전에 split DNS, local resolver와 container
network에 미치는 영향을 확인한다.

## 4. SSH 준비

dotfiles가 배포된 Sway session에서는 desktop이 관리하는 agent 하나를 사용한다.
agent의 socket, identity 수명과 종료 동작은 dotfiles의 실제 unit과 shell 함수를
기준으로 확인한다. key는 자동 탐색하지 않고 필요한 identity만 명시한다.

```sh
sshload ~/.ssh/id_ed25519_work
ssh-add -l
```

회사별 SSH config에서는 다음 원칙을 유지한다.

- `IdentityFile`과 `IdentitiesOnly yes`를 host별로 지정한다.
- `ForwardAgent`는 기본적으로 끈다.
- bastion이 필요하면 회사가 제공한 `ProxyJump` 구성을 사용한다.
- keepalive는 필요한 업무 host에만 제한한다.
- private key와 SSH config 권한을 확인한다.

첫 업무 전에 다음 흐름을 실제로 통과시킨다.

```text
key 등록
→ 회사 Git server 인증
→ MFA 또는 SSH certificate 발급
→ bastion 경유 접속
→ 연결 종료 후 재접속
→ tmux session detach와 attach
```

## 5. 프로젝트의 도구를 발견한다

개인 전역 설정을 적용하기 전에 repository가 추적하는 정책과 도구를 확인한다.

```sh
git status
rg --files --hidden -g '!.git/**' \
  -g 'README*' -g 'CONTRIBUTING*' -g 'AGENTS.md' \
  -g '.github/workflows/**' -g '.gitlab-ci.yml' \
  -g 'compose.y?ml' -g 'Dockerfile*' -g '.devcontainer/**' \
  -g 'mise.toml' -g '.mise.toml' -g '.tool-versions' \
  -g '.nvmrc' -g '.node-version' -g 'pyproject.toml' \
  -g 'package.json' -g 'Makefile' -g '*lock*' \
  -g '.editorconfig' -g '.pre-commit-config.yaml'
```

확인 대상:

```text
CI workflow
lockfile
mise.toml, .mise.toml, .tool-versions
.nvmrc, .node-version, pyproject.toml
compose.yaml, Dockerfile, .devcontainer/
formatter, linter와 test config
package script와 Makefile
```

프로젝트가 선언한 package manager, runtime version, formatter, linter, test와
build 명령이 개인 선호와 전역 `mise` 설정보다 우선한다. 상세한 웹 개발 흐름은
해당 프로젝트의 정책과 문서를 따른다.

## 6. 컨테이너는 프로젝트 요구에 맞춘다

Docker와 Podman을 근거 없이 동시에 설치하지 않는다.

1. repository의 `compose.yaml`, `.devcontainer/`, CI와 onboarding 문서를 읽는다.
2. 팀이 지원하는 engine과 version을 확인한다.
3. Docker socket, Testcontainers, BuildKit이나 devcontainer 의존성을 확인한다.
4. Docker 전용 요구가 없을 때만 rootless Podman을 대안으로 검토한다.
5. 선택한 engine 하나로 build, test, Compose와 registry 인증을 검증한다.

container engine은 package, service, storage와 network state를 추가한다. 실제
요구가 확인되기 전에는 bootstrap 기본 package에 넣지 않는다.

## 7. 업무 시간 desktop 사용

desktop은 조용한 기본 상태를 유지한다. 업무 중 팝업 알림이 필요하면 `Super+N`으로
SwayNC를 열고 `Shift+D`로 DND를 해제한다. 집중 작업이 끝나면 같은 방법으로
DND를 다시 활성화한다.

장시간 build, test, migration은 dotfiles가 제공하는 `keep_awake`로 실행한다.
명령이 끝나면 절전 inhibitor도 자동으로 해제된다.

```sh
keep_awake npm test
keep_awake docker compose up
```

회의 전에 실제 업무 서비스에서 다음을 확인한다.

- microphone 입력과 mute
- speaker 또는 Bluetooth headset 출력
- camera
- 전체 화면과 특정 영역 공유
- 잠금과 절전 복귀 후 audio·portal 재동작

## 8. secret과 local data

secret은 회사가 지정한 password manager나 secret manager에 둔다. 다음 위치에
credential을 저장하지 않는다.

```text
repository
dotfiles와 공유 문서
shell argument
shell history
공유 가능한 log와 screenshot
```

비밀번호나 token을 clipboard로 복사했다면 사용 직후 `Super+Ctrl+C`로 desktop의
clipboard history를 삭제한다. debug log를 공유하기 전에는 내부 host, 요청
header, path, token과 고객 데이터가 포함됐는지 검토한다.

Git remote는 commit된 데이터만 보관한다. commit하지 않은 작업, local database,
개발용 certificate와 environment file의 보존 방식은 회사의 승인된 backup
정책을 따른다. 허가 없이 개인 cloud storage로 동기화하지 않는다.

## 9. 업데이트와 변경 시점

rolling release와 개발 도구 업데이트는 업무 직전이나 배포 직전에 한꺼번에
실행하지 않는다. 정해 둔 maintenance 시간에 수동으로 갱신하고 다음 항목을
다시 확인한다.

```text
kernel과 reboot
VPN과 DNS
SSH agent와 key 등록
audio와 화면 공유
container build와 registry
프로젝트 test와 build
```

회사 프로젝트의 runtime과 dependency version은 개인 도구 최신화와 분리한다.
lockfile이나 tool version file은 팀 절차 없이 교체하지 않는다.

## 10. 첫 업무 전 acceptance checklist

### 정책과 계정

- [ ] 개인 장비와 Arch Linux 사용이 허용된다.
- [ ] 필요한 보안 agent와 device 정책을 충족한다.
- [ ] Codex와 LLM 사용 범위를 확인했다.
- [ ] 업무 Git identity가 `~/Projects/work/`에서만 적용된다.

### 연결

- [ ] VPN과 내부 DNS가 동작한다.
- [ ] 회사 Git server에 SSH로 인증한다.
- [ ] MFA, SSH certificate와 jump host가 필요한 경우 동작한다.
- [ ] package와 container registry에 인증한다.

### 개발

- [ ] 프로젝트가 요구하는 runtime과 package manager를 사용한다.
- [ ] dependency 설치가 완료된다.
- [ ] formatter, lint, typecheck, test와 production build가 통과한다.
- [ ] container 또는 devcontainer workflow가 필요한 경우 동작한다.
- [ ] tmux detach 후에도 의도한 remote process가 유지된다.

### desktop과 복구

- [ ] microphone, camera와 화면 공유가 동작한다.
- [ ] 장시간 명령 중 자동 절전을 막을 수 있다.
- [ ] 잠금·절전 복귀 후 VPN, SSH, audio와 portal이 복구된다.
- [ ] commit하지 않은 업무 데이터의 승인된 보존 방법을 안다.

이 checklist는 특정 machine의 합격 기록이 아니다. 실제 회사 정책이나
프로젝트가 바뀌면 해당 onboarding 문서와 현재 system 상태를 다시 확인한다.
