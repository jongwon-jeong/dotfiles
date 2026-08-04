# Neovim 웹 프런트엔드 개발 워크플로우

이 문서는 이 저장소의 Neovim 설정을 기준으로 HTML, CSS,
JavaScript, TypeScript, React, Tailwind CSS 프로젝트를 개발하는 전체
워크플로우를 정리한다.

목표는 Neovim 안에 IDE의 모든 화면을 복제하는 것이 아니다. 코드 편집과
탐색은 Neovim, 개발 서버와 테스트는 터미널, 렌더링과 런타임 디버깅은
브라우저가 담당한다. 각 도구가 가장 잘하는 역할을 유지하면서 하나의
일관된 개발 루프를 만드는 것이 이 구성의 핵심이다.

이 문서가 설명하는 설정의 canonical source는
[`init.lua`](../config/nvim/init.lua), [`config.toml`](../config/mise/config.toml),
[`aliases.sh`](../config/shell/aliases.sh)다.

실제로 Neovim이 읽는 설정은 dotfile 배포 후 다음 경로에 연결된다.

```text
~/.config/nvim/init.lua
~/.config/mise/config.toml
```

설정이 변경되면 이 문서보다 `init.lua`, `:map`, `:set`, `:checkhealth
vim.lsp`의 실제 결과를 우선한다.

---

## 목차

1. [워크플로우의 기본 철학](#1-워크플로우의-기본-철학)
2. [현재 개발 환경의 구성](#2-현재-개발-환경의-구성)
3. [최초 준비와 상태 점검](#3-최초-준비와-상태-점검)
4. [프로젝트를 여는 올바른 방법](#4-프로젝트를-여는-올바른-방법)
5. [프로젝트 유형별 시작 방법](#5-프로젝트-유형별-시작-방법)
6. [LSP가 파일별로 제공하는 기능](#6-lsp가-파일별로-제공하는-기능)
7. [Biome과 ESLint 선택 규칙](#7-biome과-eslint-선택-규칙)
8. [매일 사용하는 기본 개발 루프](#8-매일-사용하는-기본-개발-루프)
9. [자동완성과 snippet](#9-자동완성과-snippet)
10. [코드 탐색과 리팩터링](#10-코드-탐색과-리팩터링)
11. [진단과 quickfix](#11-진단과-quickfix)
12. [포맷과 lint](#12-포맷과-lint)
13. [파일 탐색과 파일 작업](#13-파일-탐색과-파일-작업)
14. [프로젝트 검색](#14-프로젝트-검색)
15. [버퍼, 창, 탭, 세션](#15-버퍼-창-탭-세션)
16. [HTML 개발](#16-html-개발)
17. [CSS 개발](#17-css-개발)
18. [JavaScript 개발](#18-javascript-개발)
19. [TypeScript 개발](#19-typescript-개발)
20. [React 개발](#20-react-개발)
21. [Tailwind CSS 개발](#21-tailwind-css-개발)
22. [개발 서버와 브라우저](#22-개발-서버와-브라우저)
23. [테스트, 타입 검사, 빌드](#23-테스트-타입-검사-빌드)
24. [Git 작업](#24-git-작업)
25. [SSH와 원격 개발](#25-ssh와-원격-개발)
26. [문제 해결](#26-문제-해결)
27. [설정 유지보수](#27-설정-유지보수)
28. [핵심 키맵 요약](#28-핵심-키맵-요약)
29. [작업 완료 체크리스트](#29-작업-완료-체크리스트)
30. [참고 문서](#30-참고-문서)

---

## 1. 워크플로우의 기본 철학

### Neovim은 코드 작업의 중심이다

Neovim은 다음 작업을 담당한다.

- 파일과 디렉터리 탐색
- 코드 작성과 텍스트 편집
- LSP 자동완성
- snippet 확장
- 정의, 참조, 구현, 타입 정의 탐색
- symbol rename과 code action
- 타입 오류와 lint 진단 확인
- 프로젝트 전체 문자열 및 경로 검색
- 포맷
- diff 확인
- 파일 경로와 줄 참조 복사

### 터미널은 프로세스 실행의 중심이다

터미널은 다음 작업을 담당한다.

- Vite 개발 서버
- npm script
- 테스트 watch process
- 타입 검사
- production build
- Git
- Biome 또는 저장소 고유 CLI 검사
- 패키지 설치와 업데이트

지속 실행되는 개발 서버를 Neovim 내부 terminal buffer에 넣을 수도 있지만,
별도 터미널이나 tmux pane을 사용하는 편이 프로세스 수명과 로그 확인에 더
단순하다.

### 브라우저는 런타임 검증의 중심이다

브라우저는 다음 작업을 담당한다.

- 실제 렌더링 확인
- 반응형 레이아웃 확인
- DOM과 CSS 검사
- Console 오류 확인
- Network 요청과 캐시 확인
- 성능과 접근성 검사
- React 런타임 동작 확인

LSP 진단이 깨끗하다는 사실은 브라우저 동작이 올바르다는 뜻이 아니다.
반대로 브라우저에서 동작한다는 사실도 타입 검사, lint, build가 통과한다는
뜻은 아니다. 편집기, 브라우저, 프로젝트 검증 명령을 모두 통과해야 작업이
완료된다.

### 프로젝트 정책이 개인 선호보다 우선한다

새 개인 프로젝트에서는 Biome을 기본 도구로 사용한다. 기존 회사 저장소에서는
그 저장소의 package manager, Node 버전, formatter, linter, 테스트 명령,
build 명령을 그대로 따른다.

다음 작업은 팀 합의 없이 하지 않는다.

- 회사 저장소에 `biome.json` 추가
- ESLint 또는 Prettier 제거
- lockfile 교체
- npm, pnpm, Yarn, Bun 사이의 package manager 변경
- 저장소 전체 포맷
- lint rule 대량 변경

---

## 2. 현재 개발 환경의 구성

### Neovim과 plugin

현재 구성은 plugin을 최소화한다.

| 구성 요소 | 역할 |
|---|---|
| Neovim 0.12+ | 편집기, LSP client, 자동완성, snippet, diagnostics, quickfix |
| nvim-lspconfig | 각 language server의 기본 실행 명령과 root 감지 |
| oil.nvim | 파일 시스템을 일반 buffer처럼 편집 |
| vim-closetag | HTML, JSX, TSX에서 `>` 입력 시 닫는 tag 생성 |
| tagalong.vim | 여는 tag와 닫는 tag 이름을 함께 변경 |

의도적으로 사용하지 않는 구성은 다음과 같다.

- Treesitter
- nvim-cmp 또는 blink.cmp
- LuaSnip
- Conform
- Prettier 전역 설치
- nvim-dap
- Git UI plugin
- 테스트 runner plugin

기능이 없어서 제외한 것이 아니다. Neovim 내장 기능, 프로젝트 CLI,
브라우저 DevTools로 현재 요구를 충족하기 때문에 제외한다. 반복적으로
불편한 실제 문제가 확인될 때만 plugin을 추가한다.

### mise가 관리하는 주요 도구

웹 프런트엔드와 직접 관련된 도구는 다음과 같다.

```text
node
neovim
biome
typescript
typescript-language-server
vscode-langservers-extracted
@olrtg/emmet-language-server
@tailwindcss/language-server
ripgrep
fd
```

`vscode-langservers-extracted`는 HTML, CSS, JSON, ESLint language server
실행 파일을 제공한다.

### shell 진입점

Neovim이 설치되어 있으면 다음 환경 변수가 모두 Neovim을 가리킨다.

```text
VISUAL=nvim
EDITOR=nvim
GIT_EDITOR=nvim
FCEDIT=nvim
```

다음 명령은 모두 현재 `VISUAL`을 실행한다.

```sh
v .
vi .
vim .
```

이 문서에서는 가장 짧은 `v`를 주로 사용한다.

### Leader 표기

현재 leader는 backslash다.

```text
<leader> = \
```

따라서 문서의 `<leader>fg`는 실제로 다음 키를 순서대로 누른다는 뜻이다.

```text
\ f g
```

---

## 3. 최초 준비와 상태 점검

### dotfile 배포

저장소 root에서 다음 스크립트를 일반 사용자로 실행한다.

```sh
./scripts/setup_dotfiles.sh
```

이 스크립트는 `~/.dotfiles` 배포본과 실제 설정 경로의 symlink를 관리한다.

### mise 도구 설치

설정에 선언된 도구를 설치한다.

```sh
mise install
```

설정 파일에 새 도구를 추가한 직후에는 upgrade 명령만 실행하지 말고
`mise install`을 실행한다. upgrade는 이미 설치된 도구의 갱신과 새 도구
설치를 같은 의미로 보장하지 않는다.

### 필수 실행 파일 점검

```sh
command -v nvim
command -v node
command -v npm
command -v biome
command -v typescript-language-server
command -v vscode-html-language-server
command -v vscode-css-language-server
command -v vscode-json-language-server
command -v vscode-eslint-language-server
command -v emmet-language-server
command -v tailwindcss-language-server
command -v rg
command -v fd
```

경로가 출력되지 않는 도구가 있다면 다음을 확인한다.

```sh
mise ls --current
mise install
mise doctor
```

### Neovim 상태 점검

Neovim을 열고 다음을 실행한다.

```vim
:checkhealth
:checkhealth vim.lsp
```

현재 buffer에 실제로 붙은 LSP client 이름만 간단히 확인하려면:

```vim
:lua =vim.tbl_map(function(client) return client.name end, vim.lsp.get_clients({ bufnr = 0 }))
```

일반적인 React TypeScript 파일에서는 프로젝트 구성에 따라 다음과 비슷한
결과가 나온다.

```text
ts_ls
biome
tailwindcss
emmet_language_server
```

ESLint 저장소이고 Biome 저장소가 아니라면 `biome` 대신 `eslint`가 붙는다.

### plugin 상태 점검

plugin은 Neovim 내장 package manager로 관리한다. 업데이트가 필요할 때:

```vim
:lua vim.pack.update()
```

특정 plugin만 업데이트하려면:

```vim
:lua vim.pack.update({ 'nvim-lspconfig' })
:lua vim.pack.update({ 'oil.nvim' })
:lua vim.pack.update({ 'vim-closetag' })
:lua vim.pack.update({ 'tagalong.vim' })
```

업데이트 후에는 Neovim을 재시작하고 다음을 다시 확인한다.

```vim
:checkhealth vim.lsp
```

---

## 4. 프로젝트를 여는 올바른 방법

### 프로젝트 root에서 시작한다

현재 설정은 `autochdir`를 끄고 working directory를 명시적으로 유지한다.
프로젝트 검색과 상대 경로는 Neovim을 시작한 디렉터리를 기준으로 동작한다.

권장 흐름:

```sh
cd ~/Projects/example-app
git status
npm install
v .
```

`v .`를 실행하면 Oil이 프로젝트 디렉터리를 연다.

특정 파일부터 시작해도 된다.

```sh
cd ~/Projects/example-app
v src/main.tsx
```

잘못된 예:

```sh
cd ~
v ~/Projects/example-app/src/main.tsx
```

이렇게 열면 LSP root는 감지되더라도 `<leader>fg`, `<leader>ff`, 상대 파일
참조가 home directory 기준으로 동작할 수 있다.

### 잘못된 working directory를 고치는 방법

Neovim 안에서:

```vim
:pwd
:cd /absolute/path/to/project
```

현재 파일이 속한 디렉터리로 바꾸려면:

```vim
:cd %:p:h
```

다만 monorepo에서는 현재 파일 디렉터리가 전체 프로젝트 root가 아닐 수
있으므로 lockfile과 `.git` 위치를 보고 직접 project root를 선택한다.

### 권장 terminal 배치

단순한 프로젝트는 터미널 두 개면 충분하다.

```text
Terminal 1: Neovim
Terminal 2: npm run dev
```

테스트 watch가 필요하면 세 번째 terminal 또는 tmux pane을 추가한다.

```text
Pane 1: Neovim
Pane 2: npm run dev
Pane 3: npm run test
```

---

## 5. 프로젝트 유형별 시작 방법

### 5.1 기존 회사 저장소

기존 저장소에서는 먼저 문서를 읽는다.

```sh
git status
git log --oneline -n 10
rg --files -g 'README*' -g 'CONTRIBUTING*' -g 'AGENTS.md'
```

다음 파일을 확인한다.

```text
package.json
package-lock.json
pnpm-lock.yaml
yarn.lock
bun.lock
.nvmrc
.node-version
mise.toml
.mise.toml
biome.json
biome.jsonc
eslint.config.*
.eslintrc*
.prettierrc*
tsconfig.json
vite.config.*
```

package manager는 lockfile을 따른다.

```text
package-lock.json  -> npm
pnpm-lock.yaml     -> pnpm
yarn.lock          -> Yarn
bun.lock           -> Bun
```

설치와 실행 명령은 `package.json` script를 우선한다.

```sh
npm install
npm run
npm run dev
```

CI에서 `npm ci`를 쓴다고 해서 일상적인 local dependency 변경에도 항상
`npm ci`가 적합한 것은 아니다. 저장소 문서를 따른다.

### 5.2 단순 HTML, CSS, JavaScript

한 번만 빠르게 확인할 때:

```sh
cd path/to/static-site
npx vite --open
```

지속적으로 개발할 프로젝트라면 Vite와 Biome을 project dependency로 둔다.

```sh
mkdir static-site
cd static-site
npm init -y
npm install --save-dev vite
npm install --save-dev --save-exact @biomejs/biome
npx biome init
```

`package.json` script의 기본 형태:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "check": "biome check .",
    "fix": "biome check --write ."
  }
}
```

최소 구조:

```text
static-site/
├── biome.json
├── index.html
├── package.json
└── src/
    ├── main.js
    └── style.css
```

시작:

```sh
npm run dev -- --open
```

### 5.3 Vite Vanilla JavaScript

```sh
npm create vite@latest vanilla-app -- --template vanilla
cd vanilla-app
npm install
npm install --save-dev --save-exact @biomejs/biome
npx biome init
npm run dev
```

### 5.4 Vite Vanilla TypeScript

```sh
npm create vite@latest vanilla-ts-app -- --template vanilla-ts
cd vanilla-ts-app
npm install
npm install --save-dev --save-exact @biomejs/biome
npx biome init
npm run dev
```

### 5.5 React JavaScript

```sh
npm create vite@latest react-app -- --template react
cd react-app
npm install
npm run dev
```

template에 ESLint가 포함되어 있다면 먼저 그대로 사용해도 된다. Biome으로
전환하기로 결정했다면:

```sh
npm install --save-dev --save-exact @biomejs/biome
npx biome init
npx biome migrate eslint
```

migration 결과는 반드시 검토한다. Biome과 ESLint의 rule은 완전히 동일하지
않으므로 migration이 성공했다는 이유만으로 ESLint 설정과 dependency를 바로
삭제하지 않는다.

### 5.6 React TypeScript

개인 SPA, 학습 프로젝트, internal tool의 기본 시작점:

```sh
npm create vite@latest react-ts-app -- --template react-ts
cd react-ts-app
npm install
npm run dev
```

Biome을 선택하면:

```sh
npm install --save-dev --save-exact @biomejs/biome
npx biome init
```

React 공식 문서는 새로운 production 앱에 routing, data fetching,
code splitting이 필요하면 React framework를 먼저 검토하도록 권장한다.
Vite 기반 React SPA는 학습, client-only SPA, internal tool, custom setup에
적합하다. 팀 프로젝트에서는 이미 선택된 framework를 따른다.

### 5.7 기존 HTML 프로젝트에 React 추가

기존 프로젝트가 이미 module bundler를 사용한다면 그 환경을 유지한다.
module build 환경이 없다면 Vite 도입을 검토한다.

```sh
npm install react react-dom
```

전체 사이트를 한 번에 React로 재작성하지 않아도 된다. 특정 DOM root에 작은
component부터 마운트하고 점진적으로 확장할 수 있다.

---

## 6. LSP가 파일별로 제공하는 기능

현재 설정은 LSP가 completion을 지원하면 Neovim 내장 popup menu에 연결한다.
server별 capability는 Neovim과 `nvim-lspconfig`의 현재 기본 설정을 사용하며,
공통 capability를 별도로 덮어쓰지 않는다.

### Server 구성표

| Server | 주요 filetype | 역할 |
|---|---|---|
| `html` | HTML | tag, attribute, HTML completion과 문서 |
| `cssls` | CSS, SCSS, Less | property, value, validation, completion |
| `ts_ls` | JS, JSX, TS, TSX | 타입, 자동 import, 탐색, rename, code action |
| `jsonls` | JSON, JSONC | schema 기반 completion과 validation |
| `emmet_language_server` | HTML, CSS, JSX, TSX 등 | Emmet abbreviation |
| `tailwindcss` | HTML, CSS, JS, JSX, TS, TSX 등 | class completion, hover, validation |
| `biome` | Biome 지원 web file | lint, format, code action |
| `eslint` | JS, JSX, TS, TSX 등 | ESLint 진단과 fix |

React 전용 language server는 필요하지 않다. React의 JSX와 TSX 지원은
`ts_ls`, Emmet, Tailwind, Biome 또는 ESLint 조합으로 제공된다.

### 하나의 buffer에 여러 server가 붙는 이유

각 server의 책임이 다르기 때문이다.

예를 들어 `src/App.tsx`에는 다음 client가 동시에 붙을 수 있다.

```text
ts_ls                 타입과 symbol 탐색
biome                 lint와 format
tailwindcss            utility class completion
emmet_language_server  JSX abbreviation
```

중복 자체가 문제는 아니다. 같은 책임을 가진 도구가 충돌할 때만 우선순위를
정해야 한다. 현재 구성은 lint client 선택과 공통 LSP format 동작을 명시한다.

### LSP와 project dependency의 관계

language server 실행 파일이 전역 mise 환경에 있어도 실제 프로젝트 library와
설정 파일이 필요할 수 있다.

예:

- `ts_ls`는 프로젝트의 TypeScript와 `tsconfig.json`을 참고한다.
- ESLint server는 프로젝트의 ESLint library와 config를 찾아야 한다.
- Tailwind server는 프로젝트가 Tailwind를 사용하는지 감지해야 한다.
- Biome server는 `biome.json`, `biome.jsonc` 또는 Biome package 선언을
  감지해야 한다.

따라서 server binary가 존재한다는 사실만으로 모든 프로젝트에서 client가
붙는 것은 아니다.

---

## 7. Biome과 ESLint 선택 규칙

### Biome 프로젝트

다음 중 하나를 감지하면 Biome project로 본다.

- `biome.json`
- `biome.jsonc`
- package manifest의 Biome 사용 선언

Biome project에서는:

- Biome LSP가 붙는다.
- ESLint config가 함께 있어도 Neovim에서는 ESLint LSP를 붙이지 않는다.
- save와 `<leader>cf`의 format 동작은 공통 LSP format 규칙을 따른다.

마지막 규칙은 migration 중 중복 진단과 상충하는 fix를 방지하기 위한 개인
정책이다.

### ESLint 프로젝트

Biome project가 아니고 ESLint config가 존재하면 ESLint LSP가 붙는다.

감지 가능한 대표 파일:

```text
eslint.config.js
eslint.config.mjs
eslint.config.cjs
eslint.config.ts
eslint.config.mts
eslint.config.cts
.eslintrc
.eslintrc.js
.eslintrc.cjs
.eslintrc.json
.eslintrc.yaml
.eslintrc.yml
```

ESLint project에서는:

- ESLint 진단이 표시된다.
- `gra`로 ESLint code action을 실행할 수 있다.
- save와 `<leader>cf`의 format 동작은 공통 LSP format 규칙을 따른다.
- 필요하면 `:LspEslintFixAll`을 명시적으로 실행한다.

### 둘 다 없는 프로젝트

Biome과 ESLint가 모두 붙지 않는다. 이 경우:

- TypeScript/JavaScript 기능은 `ts_ls`가 제공한다.
- attached LSP가 format을 지원하면 save와 `<leader>cf`에서 사용할 수 있다.
- lint 규칙은 프로젝트 CLI가 없다면 제공되지 않는다.

### Prettier 프로젝트

현재 Neovim 설정은 Prettier를 직접 실행하지 않는다.

회사 저장소가 Prettier를 강제한다면 다음 중 저장소가 정한 방법을 사용한다.

```sh
npm run format
npm run format:check
npx prettier --check .
npx prettier --write path/to/file
```

Prettier 저장소에서 `<leader>cf` 결과가 CI와 같을 것이라고 가정하지 않는다.
저장소의 script가 최종 기준이다.

---

## 8. 매일 사용하는 기본 개발 루프

### 1단계: 작업 상태 확인

```sh
cd ~/Projects/example-app
git status
git pull --ff-only
```

회사 workflow가 rebase 또는 다른 branch 전략을 사용한다면 팀 규칙을 따른다.

### 2단계: dependency 확인

lockfile이나 `package.json`이 변경되었다면:

```sh
npm install
```

설치 후 의도치 않은 lockfile 변경이 생겼는지 확인한다.

```sh
git status
git diff -- package-lock.json
```

### 3단계: 개발 서버 시작

별도 terminal:

```sh
npm run dev
```

브라우저를 자동으로 열고 싶다면 Vite project에서:

```sh
npm run dev -- --open
```

### 4단계: Neovim 시작

```sh
v .
```

또는:

```sh
v src/App.tsx
```

### 5단계: LSP 확인

처음 여는 저장소이거나 completion이 이상하면:

```vim
:checkhealth vim.lsp
```

### 6단계: 작은 단위로 구현

한 번에 큰 기능 전체를 작성하지 않는다.

```text
component 골격
-> data와 type
-> interaction
-> style
-> error/loading/empty state
-> accessibility
-> test
```

각 단위에서 브라우저와 diagnostics를 확인한다.

### 7단계: save와 feedback

LSP가 attached된 buffer에서 `:w` 시:

- client capability에 따른 save edit 또는 LSP format
- trailing whitespace 정리
- LSP가 변경 내용을 다시 분석
- Vite가 변경을 감지해 HMR 또는 reload

diagnostic virtual text는 꺼져 있다. 오류는 sign과 underline으로 보고
필요할 때 float 또는 quickfix를 연다.

### 8단계: 브라우저 검증

- Console error가 없는가
- Network 요청이 예상대로인가
- keyboard만으로 조작 가능한가
- focus가 보이는가
- 좁은 화면과 넓은 화면 모두 올바른가
- loading, empty, error state가 올바른가
- refresh 후 route가 유지되는가

### 9단계: 프로젝트 검증

저장소 script를 확인한다.

```sh
npm run
```

대표 검증:

```sh
npm run check
npm run lint
npm run typecheck
npm run test
npm run build
```

존재하는 script만 실행한다.

### 10단계: Git diff 검토

```sh
git status
git diff
git diff --check
```

의도한 파일만 변경되었는지 확인한 뒤 stage한다.

---

## 9. 자동완성과 snippet

### 현재 completion 구조

별도 completion plugin 없이 Neovim 내장 completion을 사용한다.

```text
LSP semantic candidates
+ current buffer keyword
+ other loaded buffer keyword
+ unloaded buffer keyword
```

LSP candidate가 더 높은 의미를 가지며 buffer keyword는 가벼운 fallback이다.

현재 주요 option:

```text
autocomplete = true
autocompletedelay = 80ms
completeopt = menuone,noinsert,popup
```

### completion 키

| 키 | 동작 |
|---|---|
| `<leader><Space>` | LSP completion을 명시적으로 요청 |
| `<Up>` / `<Down>` | 이전/다음 candidate 선택 |
| `<Tab>` | candidate 확정 또는 다음 snippet stop |
| `<S-Tab>` | 이전 candidate 또는 이전 snippet stop |
| `<C-y>` | 선택한 candidate 확정 |
| `<C-e>` | popup 취소 |
| `<CR>` | 선택한 candidate 확정, 선택이 없으면 newline |

`<CR>`은 popup에서 candidate가 실제로 선택된 경우에만 확정한다. 단순히
popup이 열려 있거나 아무 항목도 선택되지 않았다면 newline을 입력한다.

### 자동 import

TypeScript server가 import text edit를 포함한 completion item을 반환하면
`<C-y>`로 확정할 때 import가 함께 삽입될 수 있다.

예:

```tsx
useState
```

completion에서 React의 `useState`를 선택하면 다음 import가 자동으로 추가될
수 있다.

```tsx
import { useState } from "react";
```

자동 import가 삽입되지 않으면:

1. candidate를 `<C-y>`로 확정했는지 확인한다.
2. `ts_ls`가 attached 상태인지 확인한다.
3. project dependency가 설치되었는지 확인한다.
4. `tsconfig.json`의 module resolution을 확인한다.
5. `gra`에서 import 관련 code action을 확인한다.

### Emmet

HTML 예:

```text
main.container>section.card>h1{Title}+p{Description}
```

JSX/TSX 예:

```text
div.flex>button[type=button]{Save}
```

abbreviation을 입력하고 completion을 명시적으로 열려면:

```text
<leader><Space>
```

candidate를 선택하고:

```text
<C-y>
```

placeholder 사이 이동:

```text
<Tab>
<S-Tab>
```

### Tailwind completion

Tailwind project의 `class` 또는 `className` 문자열 안에서 utility candidate가
표시된다.

현재 다음 class helper 이름도 인식하도록 설정되어 있다.

```text
cn
clsx
cva
tw
```

예:

```tsx
const className = cn("flex items-center", active && "bg-blue-500");
```

candidate가 자동으로 뜨지 않으면 `<leader><Space>`를 사용한다.

---

## 10. 코드 탐색과 리팩터링

### 정의와 선언

| 키 | 동작 |
|---|---|
| `gd` | definition |
| `gD` | declaration |
| `gri` | implementation |
| `grt` | type definition |
| `grr` | references |
| `K` | hover documentation |
| `<C-s>` | insert mode signature help |

React component, hook, function, type, interface, imported symbol 탐색에 같은
키를 사용한다.

### symbol 탐색

| 키 | 동작 |
|---|---|
| `gO` | 현재 문서 symbol |
| `<leader>sS` | workspace symbol |
| `gai` | incoming calls |
| `gao` | outgoing calls |

workspace symbol은 큰 monorepo에서 시간이 걸릴 수 있다. server indexing이
끝나지 않았다면 결과가 불완전할 수 있다.

### rename

```text
grn
```

변수, 함수, component, type처럼 언어 의미를 가진 symbol rename은 문자열
치환보다 `grn`을 우선한다.

rename 후:

```sh
git diff
npm run typecheck
npm run test
```

CSS class, data attribute, API 문자열처럼 LSP symbol이 아닌 값은 project
grep과 확인 치환을 사용한다.

현재 파일은 `:%s`, 프로젝트 전체는 검색 결과를 검토한 뒤 `:cdo` 또는
`:cfdo`로 치환한다.

### code action

```text
gra
```

normal mode와 visual mode에서 사용할 수 있다.

대표 용도:

- missing import 추가
- unused import 제거
- ESLint fix
- Biome safe fix
- 간단한 refactor
- diagnostic quick fix

code action은 실행 전에 제목을 읽고, 실행 후 diff를 확인한다.

### inlay hint

server가 지원하는 buffer에서:

```text
<leader>h
```

항상 켜 두지 않고 복잡한 generic, inferred return type, parameter name을
확인할 때만 켠다.

---

## 11. 진단과 quickfix

### 진단 표시 정책

현재 diagnostics 설정:

```text
signs = true
underline = true
virtual_text = false
update_in_insert = false
severity_sort = true
```

입력 중 화면을 과도하게 흔들지 않고, 필요할 때 상세 정보를 여는 방식이다.

### 진단 이동

| 키 | 동작 |
|---|---|
| `[d` / `]d` | 이전/다음 diagnostic과 float |
| `[e` / `]e` | 이전/다음 error |
| `[w` / `]w` | 이전/다음 warning |
| `<leader>d` | cursor 위치 diagnostic |
| `<leader>cd` | 현재 줄 diagnostic |

error와 warning 이동 후 화면은 cursor를 중심으로 정렬된다.

### quickfix로 전체 진단 보기

```text
<leader>ld
```

이 명령은 diagnostics를 quickfix에 넣는다.

quickfix 조작:

| 키 | 동작 |
|---|---|
| `<leader>co` | quickfix 열기 |
| `<leader>qf` | quickfix 열기/닫기 |
| `[q` / `]q` | 이전/다음 항목 |
| `[Q` / `]Q` | 첫/마지막 항목 |
| `<CR>` | 선택 항목을 열고 quickfix 닫기 |

### 진단이 서로 중복될 때

현재 설정은 Biome project에서 ESLint를 억제한다. 그래도 비슷한 diagnostic이
두 번 보이면 attached client를 확인한다.

```vim
:lua =vim.tbl_map(function(client) return client.name end, vim.lsp.get_clients({ bufnr = 0 }))
```

프로젝트가 의도치 않게 Biome과 다른 lint tool을 동시에 실행하는지
`package.json`, config file, monorepo 상위 디렉터리를 확인한다.

---

## 12. 포맷과 lint

### format-on-save

자동 format-on-save는 특정 formatter 이름이 아니라 attached LSP capability를
기준으로 모든 일반 buffer에 적용된다.

save 순서:

1. `textDocument/willSaveWaitUntil`을 지원하는 client가 있으면 Neovim의 save
   요청이 해당 edit를 적용하고 별도 format 요청은 보내지 않는다.
2. 그런 client가 없고 `textDocument/formatting`을 지원하는 client가 있으면
   `vim.lsp.buf.format()`을 동기적으로 실행한다.
3. 지원하는 client가 없으면 LSP format 없이 저장한다.

동기 포맷을 사용하므로 디스크에 기록되는 내용과 화면의 내용이 어긋나지
않는다. timeout은 2초다. formatter 이름을 기준으로 client를 선택하거나
우선순위를 정하지 않으므로, 여러 formatter가 동시에 attached되면 실제 client
목록과 project CLI 결과를 함께 확인한다.

### 수동 포맷

```text
<leader>cf
```

수동 포맷은 formatter 이름을 필터링하지 않고 attached LSP formatter를
비동기로 실행한다.

### trailing whitespace

저장 시 trailing whitespace를 제거한다. 다음 filetype 또는 buffer는 제외한다.

```text
diff
gitcommit
markdown
help
nofile
prompt
terminal
```

수동 실행:

```vim
:TrimWhitespace
```

### EditorConfig

Neovim 내장 EditorConfig 지원이 활성화되어 있다. 기본 들여쓰기는 space 2칸이지만
프로젝트의 `.editorconfig`가 있으면 프로젝트 정책을 따른다.

기본값:

```text
expandtab = true
tabstop = 2
shiftwidth = 2
softtabstop = 2
```

현재 buffer의 실제 값을 확인:

```vim
:set expandtab?
:set tabstop?
:set shiftwidth?
:set softtabstop?
```

어디서 설정되었는지 확인:

```vim
:verbose set shiftwidth?
```

### Biome CLI

편집기의 실시간 feedback과 별개로 commit 전에는 project-local CLI를 실행한다.

검사만:

```sh
npx biome check .
```

safe rewrite 포함:

```sh
npx biome check --write .
```

package script가 있다면 script를 우선한다.

```sh
npm run check
npm run fix
```

`check --write`는 여러 파일을 바꿀 수 있으므로 실행 전후에 반드시 확인한다.

```sh
git status
git diff
```

### ESLint CLI

기존 ESLint 저장소:

```sh
npm run lint
```

fix script가 정의되어 있다면:

```sh
npm run lint:fix
```

script 이름을 추측하지 말고 먼저 확인한다.

```sh
npm run
```

### import 정리

Biome project에서 import 정리는 Biome assist 설정에 따라 code action 또는
CLI fix로 수행한다.

```text
gra
```

또는:

```sh
npx biome check --write path/to/file.ts
```

side-effect import는 순서 변경이 동작을 바꿀 수 있다. CSS import,
polyfill, web component registration을 자동 정렬하기 전에 diff와 런타임을
확인한다.

---

## 13. 파일 탐색과 파일 작업

### Oil 열기

| 키 | 기준 위치 |
|---|---|
| `-` | 현재 파일의 parent directory |
| `<leader>-` | floating Oil |
| `<leader>ef` | Neovim working directory |
| `<leader>ec` | 현재 파일이 있는 directory |

Oil 안에서:

| 키 | 동작 |
|---|---|
| `<CR>` | 파일 또는 directory 열기 |
| `<C-s>` | vertical split로 열기 |
| `<C-h>` | horizontal split로 열기 |
| `<C-t>` | tab으로 열기 |
| `q` | Oil 닫기 |
| `g?` | 현재 Oil keymap 도움말 |

### Oil의 핵심 개념

Oil은 tree sidebar가 아니라 directory를 editable buffer로 표현한다.

일반 buffer처럼 다음 작업을 할 수 있다.

- 파일명 수정
- 줄 삭제
- 새 줄에 새 파일명 입력
- 여러 파일 이동 또는 rename 계획

변경을 실제 파일 시스템에 적용:

```vim
:w
```

저장하기 전에는 계획된 operation을 확인한다. 삭제는 현재 설정에서 trash로
보내도록 구성되어 있지만, 대량 작업은 항상 Git 상태와 backup 여부를 먼저
확인한다.

### hidden file

Oil은 hidden file을 기본 표시한다.

다음 파일을 놓치지 않는다.

```text
.env.example
.editorconfig
.gitignore
.npmrc
.nvmrc
.prettierrc
.eslintrc
```

실제 `.env`와 secret 파일은 열어 볼 수 있더라도 Git에 추가하지 않는다.

---

## 14. 프로젝트 검색

### 문자열 검색

| 키 | 동작 |
|---|---|
| `<leader>fg` | smart-case project grep |
| `<leader>fG` | case-sensitive project grep |

현재 환경에서는 ripgrep을 사용한다. 입력은 정규식으로 해석된다.

예:

```text
useEffect
TODO|FIXME
className=
fetch\(
interface\s+\w+
```

smart-case 검색은 소문자 query에서는 대소문자를 무시하고 대문자가 포함되면
대소문자를 구분한다.

### 경로 검색

| 키 | 동작 |
|---|---|
| `<leader>ff` | 대소문자를 무시한 경로 검색 |
| `<leader>fF` | 대소문자를 구분한 경로 검색 |

파일과 directory를 모두 결과에 포함한다. directory 결과를 열면 Oil로
탐색할 수 있다.

### 기본 제외 directory

project grep과 find는 다음과 같은 생성물과 dependency directory를 제외한다.

```text
.git
node_modules
dist
build
.next
.cache
.turbo
.vite
coverage
target
__pycache__
.venv
.mypy_cache
.pytest_cache
.ruff_cache
```

dependency 구현을 검색해야 할 때는 terminal에서 별도 `rg` 명령을 사용한다.

```sh
rg --hidden 'pattern' node_modules/specific-package
```

### 검색 결과 처리

검색 결과는 quickfix에 들어간다.

```text
[q / ]q
[Q / ]Q
<leader>qf
```

여러 파일 치환이 필요하면 검색 결과를 충분히 좁힌 뒤 `:cdo` 또는 `:cfdo`를
사용하고 Git diff로 결과를 검토한다.

---

## 15. 버퍼, 창, 탭, 세션

### buffer 이동

| 키 | 동작 |
|---|---|
| `[b` / `]b` | 이전/다음 buffer |
| `[B` / `]B` | 첫/마지막 buffer |
| `<leader>ss` | alternate buffer |
| `<leader>bb` | jump backward |
| `<leader>gg` | jump forward |

`alternate buffer`는 두 파일 사이를 빠르게 오갈 때 가장 유용하다.

### window 이동과 크기

| 키 | 동작 |
|---|---|
| `<leader>w` | Neovim window command prefix |
| `<leader>1` | 왼쪽 window |
| `<leader>2` | 아래 window |
| `<leader>3` | 위 window |
| `<leader>4` | 오른쪽 window |
| `<leader>5` | 폭 줄이기 |
| `<leader>6` | 높이 줄이기 |
| `<leader>7` | 높이 늘리기 |
| `<leader>8` | 폭 늘리기 |

기본 split은 오른쪽과 아래에 열린다.

### tab 이동

```text
[t
]t
```

Neovim tab은 일반적인 IDE의 파일 tab과 다르다. 하나의 tab page는 window
layout 묶음이다. 단순 파일 전환은 buffer를 사용한다.

### 수동 session

현재 프로젝트 layout 저장:

```vim
:mksession! .session.vim
```

복원:

```sh
nvim -S .session.vim
```

또는 Neovim 안에서:

```vim
:source .session.vim
```

`.session.vim`을 개인 local state로 쓸 경우 `.gitignore`에 포함되는지
확인한다.

### persistent undo와 cursor 복원

- undo history는 Neovim state directory에 영구 저장된다.
- 파일을 다시 열면 이전 cursor 위치를 복원한다.
- swap file은 사용하지 않는다.
- backup과 writebackup도 사용하지 않는다.

따라서 Git과 filesystem backup은 여전히 중요하다. persistent undo는
repository backup을 대체하지 않는다.

---

## 16. HTML 개발

### 기본 작업

HTML buffer에서는 다음 기능을 기대할 수 있다.

- element와 attribute completion
- snippet
- Emmet
- linked tag 또는 document link 기능
- Biome project에서 format과 lint
- Tailwind project에서 class completion

### 권장 작성 순서

1. landmark와 document 구조를 먼저 작성한다.
2. semantic element를 선택한다.
3. keyboard interaction이 필요한 element를 확인한다.
4. form label과 validation message를 연결한다.
5. CSS와 JavaScript를 추가한다.
6. 브라우저 accessibility tree와 keyboard navigation을 확인한다.

### Emmet 예

```text
header>nav>ul>li*3>a[href="#"]{Link $}
```

```text
main>section.hero>h1{Title}+p{Description}+button[type=button]{Start}
```

확장:

```text
<leader><Space>
<Tab>
<C-y>
```

### tag 자동 닫기

HTML, JSX, TSX에서 여는 tag의 `>`를 입력하면 `vim-closetag`가 닫는 tag를
만든다.

```html
<section>
  |
</section>
```

첫 번째 `>`는 닫는 tag를 만들고, 바로 다시 `>`를 입력하면 여는 tag와 닫는
tag를 여러 줄로 펼친다. HTML void element는 닫는 tag를 만들지 않는다.

현재 설정은 empty tag 이름을 대소문자로 구분한다. 따라서 HTML의 `<link>`는
void element로 처리하지만 React component인 `<Link>`는 일반 component처럼
닫는다.

현재 buffer에서 자동 닫기를 잠시 끄거나 다시 켤 수 있다.

```vim
:CloseTagToggleBuffer
:CloseTagDisableBuffer
:CloseTagEnableBuffer
```

### 여는 tag와 닫는 tag를 함께 변경

`tagalong.vim`은 한쪽 tag 이름을 일반적인 insert/change 동작으로 수정하고
insert mode를 나가면 짝 tag도 변경한다.

```html
<section>Content</section>
```

여는 `section` 안에서 `ciw`로 `article`을 입력하고 `<Esc>`를 누르면 다음처럼
변경된다.

```html
<article>Content</article>
```

cursor가 tag의 `<`와 `>` 안에 있을 때 `c`, visual change, `i`, `a` 계열로
수정하는 흐름이 가장 안정적이다. 다음 변경은 자동 동기화를 보장하지 않는다.

- `:substitute`
- yank한 text로 덮어쓰기
- `r` 또는 `x`로 한 글자만 변경
- tag 밖에서 insert mode에 들어간 뒤 cursor를 이동해 수정
- `<C-c>`로 insert mode 종료

적용은 `InsertLeave` 시점에 일어나므로 평소처럼 `<Esc>`로 insert mode를
종료한다. 현재 buffer에서 동작이 이상하면 즉시 끄고 수동으로 diff를 확인한다.

```vim
:TagalongDeinit
:TagalongInit
```

### HTML을 file protocol로 열지 않는다

다음 방식은 module, fetch, CORS, path 처리에서 실제 server와 다르게 동작할
수 있다.

```text
file:///path/to/index.html
```

대신:

```sh
npx vite --open
```

또는 project script:

```sh
npm run dev
```

---

## 17. CSS 개발

### 제공 기능

CSS, SCSS, Less buffer에서는 `cssls`가 property, value, validation,
completion을 제공한다.

Biome project의 지원 filetype에서는 Biome format과 lint가 추가된다.

Tailwind project에서는 Tailwind LSP가 utility class와 directive 정보를
제공한다.

### CSS 작업 순서

1. layout model을 결정한다.
2. component 구조와 cascade boundary를 정한다.
3. spacing과 typography token을 사용한다.
4. interaction state를 작성한다.
5. responsive breakpoint를 확인한다.
6. browser computed style을 확인한다.

최소 확인 state:

```text
:hover
:focus-visible
:active
:disabled
[aria-expanded="true"]
loading
error
empty
```

### 브라우저를 함께 사용한다

CSS LSP는 syntax와 알려진 property를 검사하지만 다음을 판단하지 못한다.

- 실제 cascade 우선순위
- containing block
- stacking context
- layout overflow
- font loading
- browser별 rendering
- 실제 viewport에서의 가독성

Elements panel, Computed panel, Layout panel을 함께 사용한다.

### generated CSS를 직접 수정하지 않는다

다음 directory의 output은 source가 아닐 가능성이 높다.

```text
dist
build
.next
coverage
```

원본 source나 build configuration을 수정한다.

---

## 18. JavaScript 개발

### `ts_ls`는 JavaScript에도 사용된다

TypeScript language server는 `.js`와 `.jsx`에서도 다음 기능을 제공한다.

- completion
- JSDoc 기반 type inference
- definition과 references
- rename
- auto import
- signature help
- 일부 diagnostic

`checkJs`와 `allowJs` 같은 정책은 프로젝트의 `jsconfig.json` 또는
`tsconfig.json`을 따른다.

### module 경로

import가 해결되지 않으면 다음을 확인한다.

```text
package dependency 설치 여부
package.json type
파일 확장자
tsconfig/jsconfig paths
Vite alias
대소문자
```

Linux에서는 파일명의 대소문자가 구분된다. macOS에서 우연히 동작하는 잘못된
import path가 Linux CI에서 실패할 수 있다.

### browser API와 Node API를 구분한다

Vite client code에서 다음과 같은 Node 전용 API를 직접 사용하지 않는다.

```text
fs
path
process의 Node 전용 동작
서버 secret
```

client bundle에 들어가는 환경 변수는 공개 정보로 취급한다. Vite의 client
환경 변수 prefix와 저장소 정책을 확인한다.

---

## 19. TypeScript 개발

### editor diagnostic과 compiler는 다르다

`ts_ls` diagnostic은 빠른 feedback을 제공하지만 최종 판정은 프로젝트의
compiler command다.

```sh
npm run typecheck
```

script가 없다면 프로젝트 정책을 확인한 뒤:

```sh
npx tsc --noEmit
```

Vite template의 build script가 이미 `tsc -b`를 포함할 수도 있으므로
`package.json`을 먼저 본다.

### type 탐색

```text
K    현재 symbol의 inferred type
grt  type definition
gd   definition
grr  references
```

복잡한 generic 또는 inferred parameter가 필요할 때:

```text
<leader>h
```

### rename은 LSP를 사용한다

```text
grn
```

TypeScript symbol rename은 import와 reference를 함께 처리할 수 있다. 단순
문자열 치환보다 안전하다.

rename 후 compiler와 test를 실행한다.

### `any`를 completion 문제 해결책으로 쓰지 않는다

completion이 나오지 않을 때 type을 `any`로 바꾸기 전에 다음을 확인한다.

- dependency type package
- generic type parameter
- union narrowing
- generated type
- tsconfig include/exclude
- project reference
- LSP root

---

## 20. React 개발

### 파일 역할

일반적인 React TypeScript 구조:

```text
src/
├── app/
├── components/
├── features/
├── hooks/
├── lib/
├── styles/
├── types/
├── App.tsx
└── main.tsx
```

실제 저장소 구조가 있다면 그것을 따른다. 개인 취향으로 directory 구조를
재편하지 않는다.

### component 작성 루프

1. props type을 먼저 정의한다.
2. pure rendering 구조를 만든다.
3. event handler를 연결한다.
4. loading, empty, error state를 작성한다.
5. keyboard와 focus 동작을 확인한다.
6. style을 적용한다.
7. test를 추가한다.

예:

```tsx
type UserCardProps = {
  name: string;
  onSelect: () => void;
};

export function UserCard({ name, onSelect }: UserCardProps) {
  return (
    <button type="button" onClick={onSelect}>
      {name}
    </button>
  );
}
```

JSX와 TSX에서는 HTML tag와 React component tag의 대소문자를 보존한다.
`<link>`는 HTML void element지만 `<Link>`는 component이므로 현재 closetag
설정이 `</Link>`를 만든다. React fragment는 React filetype에서 `<>` 입력 시
`</>`로 닫힌다.

component tag 이름을 바꿀 때는 tag 안에서 일반적인 insert/change 동작 후
`<Esc>`를 사용하면 tagalong이 짝 tag를 함께 바꾼다. component symbol 자체와
모든 참조를 바꾸려는 작업은 tagalong이 아니라 LSP rename `grn`을 사용한다.

### 자주 쓰는 LSP 흐름

새 component 사용:

```text
component 이름 입력
-> completion
-> <C-y>
-> import 자동 삽입 확인
```

props 확인:

```text
K
<C-s>
```

component 구현으로 이동:

```text
gd
```

사용처 확인:

```text
grr
```

component 또는 prop rename:

```text
grn
```

quick fix:

```text
gra
```

### HMR을 신뢰하되 최종 검증은 reload한다

Vite HMR은 빠르지만 state를 보존하기 때문에 초기 mount에서만 발생하는
문제를 숨길 수 있다.

다음 시점에는 full reload도 확인한다.

- route 진입
- authentication 초기화
- persisted state 복원
- environment variable 변경
- module side effect 변경
- error boundary

### runtime 오류

TypeScript가 통과해도 다음 오류는 브라우저에서만 나타날 수 있다.

- API response shape 불일치
- hydration 문제
- stale closure
- effect timing
- DOM measurement
- network failure
- permission failure

Console과 Network panel을 확인하고 재현 가능한 test를 추가한다.

---

## 21. Tailwind CSS 개발

### Vite project에 Tailwind 추가

현재 Tailwind CSS의 Vite plugin 방식:

```sh
npm install tailwindcss @tailwindcss/vite
```

React Vite 설정 예:

```ts
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

CSS entry:

```css
@import "tailwindcss";
```

기존 저장소가 Tailwind v3 또는 PostCSS 구성을 사용한다면 이 예제로 임의
변환하지 않는다. 저장소의 현재 major version과 공식 upgrade guide를 따른다.

### completion

HTML:

```html
<main class="mx-auto max-w-5xl px-6">
```

React:

```tsx
<main className="mx-auto max-w-5xl px-6">
```

helper:

```tsx
const className = cn(
  "rounded-md px-3 py-2",
  active && "bg-blue-600 text-white",
);
```

`cn`, `clsx`, `cva`, `tw` 안에서도 class completion을 지원하도록 설정되어
있다.

### completion이 없을 때

1. dependency 확인:

   ```sh
   npm ls tailwindcss
   ```

2. attached client 확인:

   ```vim
   :checkhealth vim.lsp
   ```

3. 수동 completion:

   ```text
   <leader><Space>
   ```

4. project root와 config/package 감지를 확인한다.
5. monorepo package에서 Neovim을 올바른 root로 열었는지 확인한다.
6. `:lsp restart tailwindcss`를 실행한다.

### 동적 class name

다음처럼 class 일부를 문자열 조합하면 Tailwind scanner와 LSP가 완전한
class를 인식하지 못할 수 있다.

```tsx
const className = `bg-${color}-500`;
```

가능하면 완전한 class 문자열을 명시적으로 mapping한다.

```tsx
const colorClasses = {
  blue: "bg-blue-500",
  red: "bg-red-500",
};
```

---

## 22. 개발 서버와 브라우저

### Vite를 기본으로 사용한다

Vite project:

```sh
npm run dev
```

브라우저 자동 실행:

```sh
npm run dev -- --open
```

port 지정:

```sh
npm run dev -- --port 3000
```

일회성 정적 site:

```sh
npx vite --open
```

### Live Server와의 관계

VS Code Live Server와 가장 비슷한 CLI는 다음과 같다.

```sh
npx live-server . --host=127.0.0.1 --port=8080
```

그러나 지속적인 현대 프런트엔드 프로젝트에서는 Vite를 project dependency와
`npm run dev` script로 관리한다.

### network 공개

기본적으로 local development server는 local machine에서만 접근하도록 둔다.

다음 옵션은 LAN 또는 container에서 접근해야 할 때만 사용한다.

```sh
npm run dev -- --host
```

`0.0.0.0` binding은 같은 network의 다른 장치에서 접근할 수 있게 만들 수
있다. 회사 network, 공용 Wi-Fi, 민감한 mock data가 있는 환경에서는 의미를
이해하지 않고 사용하지 않는다.

### Neovim 내부 terminal

필요하면:

```vim
:terminal npm run dev
```

terminal mode에서 normal mode로:

```text
<C-\><C-n>
```

프로세스 중지:

```text
<C-c>
```

지속 server는 별도 shell 또는 tmux pane이 관리하기 더 쉽다.

### 브라우저 확인 순서

1. Console
2. Network
3. Elements와 computed style
4. keyboard navigation
5. responsive viewport
6. hard reload
7. production preview

production build를 실제로 preview:

```sh
npm run build
npm run preview
```

development server와 production preview는 같지 않다.

---

## 23. 테스트, 타입 검사, 빌드

### script를 먼저 발견한다

```sh
npm run
```

`package.json`에서 다음 script를 찾는다.

```text
test
test:unit
test:e2e
lint
check
typecheck
build
preview
```

### unit test

저장소가 Vitest, Jest 또는 다른 runner를 사용한다면 해당 script를 실행한다.

```sh
npm run test
```

watch와 single-run 옵션은 runner마다 다르다. CI 명령을 추측하지 않고
`package.json`과 CI workflow를 확인한다.

### end-to-end test

Playwright 같은 E2E test는 개발 서버 또는 webServer 설정이 필요할 수 있다.

```sh
npm run test:e2e
```

test 실패 시:

- screenshot
- trace
- browser console
- network
- test artifact

를 함께 확인한다.

### 타입 검사

```sh
npm run typecheck
```

### lint와 format 검사

```sh
npm run lint
npm run check
```

### production build

```sh
npm run build
```

build는 다음 문제를 찾을 수 있다.

- typecheck 차이
- unresolved import
- environment variable 문제
- bundle-only transform 오류
- asset path 오류
- SSR/client boundary 문제

### Neovim에 test plugin이 없는 이유

test runner는 terminal output, watch mode, browser artifact, CI command와 강하게
연결된다. 현재 workflow에서는 terminal에서 project script를 직접 실행하는
편이 가장 투명하고 재현 가능하다.

실패 위치가 출력되면 Neovim에서 파일을 열거나 quickfix 형식으로 변환할 수
있다. 반복적인 필요가 확인되기 전에는 test plugin을 추가하지 않는다.

---

## 24. Git 작업

### 작업 중 확인

shell alias:

```sh
gs
gd
gds
```

원래 명령:

```sh
git status
git diff
git diff --stat
```

### stage 후 확인

```sh
git add path/to/file
git diff --cached
git status
```

alias:

```sh
ga path/to/file
gdc
gs
```

### commit 전 권장 순서

```sh
npm run check
npm run typecheck
npm run test
npm run build
git diff --check
git status
git diff --cached
```

저장소에 존재하는 검증 명령만 실행한다.

### Neovim diff

두 파일 비교:

```sh
vimdiff path/to/old path/to/new
```

Git difftool:

```sh
gdt
```

staged difftool:

```sh
gdts
```

### file reference 복사

코드 리뷰, issue, Codex prompt에 정확한 위치를 전달할 때:

| 키 | 결과 |
|---|---|
| `<leader>or` | 상대 경로와 line |
| `<leader>of` | 상대 경로 |
| `<leader>oe` | 절대 경로와 line |
| `<leader>od` | 절대 경로 |

visual selection에서 실행하면 line range를 포함한다.

예:

```text
src/components/UserCard.tsx:12-28
```

---

## 25. SSH와 원격 개발

### 기본 원칙

원격 개발에서도 다음을 유지한다.

```text
SSH
tmux
Neovim
project CLI
```

desktop 전용 동작은 환경 검사를 통과할 때만 실행된다.

### clipboard

SSH 환경에서는 OSC52 clipboard를 사용하도록 설정되어 있다. terminal이
OSC52를 지원하면 remote Neovim의 yank를 local clipboard로 전달할 수 있다.

clipboard가 동작하지 않으면:

- terminal의 OSC52 지원
- tmux passthrough
- SSH client
- `SSH_TTY` 또는 `SSH_CONNECTION`

을 확인한다.

### remote 개발 서버

안전한 SSH port forwarding 예:

local machine:

```sh
ssh -L 5173:127.0.0.1:5173 user@example-host
```

remote machine:

```sh
npm run dev -- --host 127.0.0.1 --port 5173
```

local browser:

```text
http://127.0.0.1:5173
```

서버를 무조건 `0.0.0.0`에 공개하는 대신 SSH tunnel을 우선한다.

### remote server의 도구 부족

설정만 배포되고 language server가 없다면 Neovim은 기본 편집기로 계속
사용할 수 있지만 LSP 기능은 붙지 않는다.

확인:

```sh
command -v typescript-language-server
command -v biome
command -v rg
command -v fd
```

remote host 정책에 따라 mise 설치 또는 project-local 도구를 사용한다.

---

## 26. 문제 해결

### LSP가 붙지 않는다

순서대로 확인한다.

```vim
:set filetype?
:checkhealth vim.lsp
:pwd
```

shell:

```sh
command -v <language-server>
```

확인 항목:

- filetype이 올바른가
- server executable이 `PATH`에 있는가
- project root marker가 있는가
- config 파일이 있는가
- dependency install이 끝났는가
- Neovim을 project root에서 열었는가

LSP 재시작:

```vim
:lsp restart
```

특정 client:

```vim
:lsp restart ts_ls
:lsp restart biome
:lsp restart tailwindcss
```

### completion이 뜨지 않는다

1. 명시적으로 요청:

   ```text
   <leader><Space>
   ```

2. client 확인:

   ```vim
   :checkhealth vim.lsp
   ```

3. mapping 확인:

   ```vim
   :verbose imap <leader><Space>
   :verbose imap <Tab>
   :verbose imap <S-Tab>
   :verbose imap <CR>
   ```

4. popup 확정은 `<C-y>`를 사용하거나, 항목을 선택한 뒤 `<CR>`을 누른다.
5. `node_modules`가 있는지 확인한다.
6. import path와 tsconfig를 확인한다.

### Emmet이 동작하지 않는다

```sh
command -v emmet-language-server
```

```vim
:checkhealth vim.lsp
:set filetype?
```

JS 파일에서는 Emmet이 붙지 않을 수 있다. JSX는 `javascriptreact`, TSX는
`typescriptreact` filetype이어야 한다.

### tag가 자동으로 닫히거나 함께 변경되지 않는다

현재 filetype을 먼저 확인한다.

```vim
:set filetype?
:verbose imap >
```

`vim-closetag`은 현재 설정에서 HTML, XHTML, PHTML, JSX, TSX에 활성화된다.
buffer별 상태를 다시 켤 수 있다.

```vim
:CloseTagEnableBuffer
:TagalongInit
```

tagalong은 `:substitute`, paste overwrite, `r`, `x` 등 모든 수정 방식을
가로채지 않는다. 일반적인 change/insert 동작을 tag 내부에서 시작하고
`<Esc>`로 insert mode를 끝낸다. 자동 변경 후에는 반드시 `git diff`로 여는
tag와 닫는 tag가 모두 의도대로 바뀌었는지 확인한다.

### Tailwind completion이 없다

```sh
npm ls tailwindcss
command -v tailwindcss-language-server
```

```vim
:checkhealth vim.lsp
:lsp restart tailwindcss
```

Tailwind가 설치되지 않은 일반 CSS 프로젝트에는 server가 붙지 않는 것이
정상이다.

### format-on-save가 동작하지 않는다

현재 buffer의 attached client와 capability를 확인한다.

```vim
:checkhealth vim.lsp
:lua =vim.tbl_map(function(client) return client.name end, vim.lsp.get_clients({ bufnr = 0 }))
```

project formatter를 직접 확인할 때는 저장소의 script를 우선한다.

```sh
npm run
npx biome check path/to/file
```

`willSaveWaitUntil`을 지원하는 client가 있으면 별도
`textDocument/formatting` 요청 대신 save edit가 적용된다. 여러 formatter가
attached된 경우 현재 설정은 client 이름으로 하나를 선택하지 않으므로
`:LspInfo`, project config, 저장 전후 diff를 함께 확인한다.

### ESLint diagnostic이 없다

```sh
npm ls eslint
npm run lint
```

ESLint config 파일을 확인한다.

```sh
fd 'eslint\\.config|\\.eslintrc'
```

Biome config가 동시에 있으면 개인 Neovim 정책상 ESLint LSP가 억제된다.
회사 저장소에서 두 도구를 모두 반드시 실행해야 한다면 terminal의 저장소
script와 CI를 기준으로 검증한다.

### format 결과가 CI와 다르다

다음 가능성을 확인한다.

- CI는 Prettier를 사용한다.
- local Biome version과 CI version이 다르다.
- project-local binary가 설치되지 않았다.
- EditorConfig가 다르다.
- generated file을 포맷했다.
- monorepo의 다른 config가 적용되었다.

project-local 명령으로 재현한다.

```sh
npm run format
npm run check
```

### diagnostics가 오래된 것 같다

```vim
:edit
:lsp restart
```

외부 변경은 focus, buffer 진입, CursorHold에서 `checktime`으로 다시 읽도록
설정되어 있다.

### LSP log가 필요하다

기본 log level은 `off`다. 문제를 재현할 때만 일시적으로 켠다.

```vim
:lua vim.lsp.log.set_level('debug')
:lsp restart
```

문제를 재현한 뒤:

```vim
:LspLog
```

확인이 끝나면 Neovim을 재시작해 기본 `off` 상태로 돌아간다. debug log는
크게 증가할 수 있다.

### project grep이 너무 많은 결과를 낸다

- 더 구체적인 정규식을 쓴다.
- 대소문자가 중요하면 `<leader>fG`를 사용한다.
- symbol이면 문자열 검색 대신 `grr`을 사용한다.
- 파일 범위를 먼저 경로 검색으로 좁힌다.

### 브라우저는 갱신되지만 코드가 바뀌지 않는다

- 저장했는지 확인한다.
- Vite가 다른 root를 serve하는지 확인한다.
- browser Network cache를 확인한다.
- service worker를 확인한다.
- HMR 오류를 terminal과 Console에서 확인한다.
- full reload한다.
- dev server를 재시작한다.

### port가 이미 사용 중이다

```sh
ss -ltnp
```

다른 port:

```sh
npm run dev -- --port 5174
```

기존 프로세스를 종료할 때는 정확한 PID와 command를 확인한다.

---

## 27. 설정 유지보수

### mise 도구 업데이트

현재 설치된 사용자 개발 도구 업데이트:

```sh
upall
```

새 tool 선언 반영:

```sh
mise install
```

업데이트 후:

```sh
mise ls --current
nvim --version
biome --version
typescript-language-server --version
```

### Neovim plugin 업데이트

```vim
:lua vim.pack.update()
```

업데이트 후 최소 검증:

```sh
stylua --check config/nvim/init.lua
```

Neovim:

```vim
:checkhealth
:checkhealth vim.lsp
```

### 설정 변경 원칙

plugin이나 mapping을 추가하기 전에 다음 질문에 답한다.

1. 반복되는 실제 문제가 있는가
2. Neovim 내장 기능으로 해결할 수 없는가
3. project CLI로 해결하는 것이 더 재현 가능하지 않은가
4. SSH와 remote 환경에서도 안전한가
5. startup과 대형 monorepo 성능에 어떤 영향을 주는가
6. 기존 keymap과 충돌하지 않는가
7. 제거하기 쉬운가

### plugin을 추가할 만한 신호

다음 문제가 반복되고 측정 가능할 때 검토한다.

- native completion 정렬이 실제 업무를 지속적으로 방해한다.
- test 결과에서 파일 이동이 반복적으로 느리다.
- debugger를 Neovim 안에서 사용해야 하는 workflow가 정착했다.
- framework 전용 language support가 현재 LSP 조합으로 부족하다.
- structural syntax operation이 반복적으로 필요하다.

단순히 인기 있다는 이유만으로 추가하지 않는다.

---

## 28. 핵심 키맵 요약

### 편집

| 키 | 모드 | 동작 |
|---|---|---|
| `jk` | insert | normal mode |
| `,` | normal/visual | command line |
| `<S-u>` | normal | redo |
| `j` / `k` | normal | display line 이동 |
| `0` / `^` / `$` | normal | display line 기준 이동 |
| `<` / `>` | visual | selection을 유지하며 들여쓰기 |
| `n` / `N` / `*` / `#` | normal | 검색 후 화면 중앙 정렬 |
| `<leader>v` | normal | blockwise visual |
| `<leader>a` | normal | 전체 buffer 선택 |
| `<Esc>` | normal | 검색 highlight 제거, Hangul 입력 reset |

`c`, `C`, `x`, `X`, `s`, `S`는 black-hole register를 사용하도록 변경되어
있다. 수정 과정에서 기존 yank를 보존한다.

visual mode의 `p`는 선택 영역을 교체해도 unnamed register를 덮어쓰지 않는다.

### completion

| 키 | 동작 |
|---|---|
| `<leader><Space>` | LSP completion |
| `<Up>` / `<Down>` | 이전/다음 item 선택 |
| `<Tab>` | item 확정/다음 snippet stop |
| `<S-Tab>` | 이전 item/snippet stop |
| `<C-y>` | completion 확정 |
| `<CR>` | 선택한 item 확정/newline |

### LSP

| 키 | 동작 |
|---|---|
| `gd` | definition |
| `gD` | declaration |
| `gri` | implementation |
| `grt` | type definition |
| `grr` | references |
| `grn` | rename |
| `gra` | code action |
| `gO` | document symbols |
| `K` | hover |
| `<C-s>` | signature help |
| `<leader>sS` | workspace symbols |
| `<leader>cf` | format |
| `<leader>h` | inlay hints |

### diagnostics

| 키 | 동작 |
|---|---|
| `[d` / `]d` | diagnostic |
| `[e` / `]e` | error |
| `[w` / `]w` | warning |
| `<leader>d` | diagnostic float |
| `<leader>ld` | diagnostics to quickfix |

### 파일과 검색

| 키 | 동작 |
|---|---|
| `-` | parent directory Oil |
| `<leader>-` | floating Oil |
| `<leader>ef` | Oil at cwd |
| `<leader>ec` | Oil at current file |
| `<leader>fg` | smart-case grep |
| `<leader>fG` | case-sensitive grep |
| `<leader>ff` | path find |
| `<leader>fF` | case-sensitive path find |

### buffer와 window

| 키 | 동작 |
|---|---|
| `[b` / `]b` | 이전/다음 buffer |
| `[B` / `]B` | 첫/마지막 buffer |
| `<leader>ss` | alternate buffer |
| `<leader>bb` / `<leader>gg` | jump backward/forward |
| `<leader>1..4` | window 이동 |
| `<leader>5..8` | window resize |
| `[t` / `]t` | tab 이동 |

### quickfix

| 키 | 동작 |
|---|---|
| `[q` / `]q` | 이전/다음 item |
| `[Q` / `]Q` | 첫/마지막 item |
| `<leader>co` | 열기 |
| `<leader>qf` | toggle |
| `<CR>` | item 열고 quickfix 닫기 |

### file reference 복사

| 키 | 동작 |
|---|---|
| `<leader>or` | 상대 경로와 line |
| `<leader>of` | 상대 경로 |
| `<leader>oe` | 절대 경로와 line |
| `<leader>od` | 절대 경로 |

---

## 29. 작업 완료 체크리스트

### 코드

- [ ] 요구사항을 충족한다.
- [ ] 불필요한 변경이 없다.
- [ ] TypeScript error가 없다.
- [ ] LSP error와 warning을 검토했다.
- [ ] loading, empty, error state를 처리했다.
- [ ] keyboard와 focus 동작을 확인했다.
- [ ] responsive layout을 확인했다.
- [ ] Console error가 없다.
- [ ] Network 요청을 확인했다.

### 프로젝트 도구

- [ ] 저장소의 formatter를 실행했다.
- [ ] 저장소의 linter를 실행했다.
- [ ] typecheck를 실행했다.
- [ ] 관련 test를 실행했다.
- [ ] production build를 실행했다.
- [ ] 필요한 경우 production preview를 확인했다.

### Git

- [ ] `git status`를 확인했다.
- [ ] `git diff`를 읽었다.
- [ ] secret과 `.env`가 포함되지 않았다.
- [ ] generated file이 의도치 않게 포함되지 않았다.
- [ ] lockfile 변경이 의도적이다.
- [ ] `git diff --check`를 통과했다.
- [ ] stage한 diff를 다시 읽었다.
- [ ] commit은 한 가지 의도를 가진다.

---

## 30. 참고 문서

현재 도구의 동작과 명령은 다음 공식 문서를 기준으로 한다.

- [Neovim LSP](https://neovim.io/doc/user/lsp)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [Oil](https://github.com/stevearc/oil.nvim)
- [vim-closetag](https://github.com/alvan/vim-closetag)
- [tagalong.vim](https://github.com/AndrewRadev/tagalong.vim)
- [Vite Getting Started](https://vite.dev/guide/)
- [Biome](https://biomejs.dev/)
- [Biome configuration](https://biomejs.dev/reference/configuration/)
- [Biome organize imports](https://biomejs.dev/assist/actions/organize-imports/)
- [React installation](https://react.dev/learn/installation)
- [Add React to an existing project](https://react.dev/learn/add-react-to-an-existing-project)
- [Tailwind CSS with Vite](https://tailwindcss.com/docs/installation/using-vite)
