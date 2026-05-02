# git-alias

설정해두면 편한 git alias 모음과 플랫폼별 설치 스크립트입니다.

> Reference: https://johngrib.github.io/wiki/git-alias

## 목차

- [사전 요구사항](#사전-요구사항)
- [설치 방법](#설치-방법)
  - [빠른 설치](#빠른-설치)
  - [클론 후 설치](#클론-후-설치)
- [설치 스크립트 기능](#설치-스크립트-기능)
- [수동 설치](#수동-설치)
- [Alias 목록](#alias-목록)

---

## 사전 요구사항

일부 alias는 [fzf](https://github.com/junegunn/fzf)와 [pygments](https://pygments.org/)가 필요합니다.

| 도구     | 용도                                     | 필수 여부 |
| -------- | ---------------------------------------- | --------- |
| fzf      | 인터랙티브 선택 (브랜치, 커밋, stash 등) | 필수      |
| pygments | diff 미리보기 구문 강조                  | 선택      |

```bash
# macOS
brew install fzf pygments

# Linux (Debian/Ubuntu)
sudo apt-get install fzf python3-pygments

# Linux (RHEL/CentOS)
sudo dnf install fzf python3-pygments

# Windows
winget install junegunn.fzf
pip install pygments
```

---

## 설치 방법

### 빠른 설치

#### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/99mini/git-alias/main/install/mac.sh | bash
```

#### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/99mini/git-alias/main/install/linux.sh | bash
```

#### Windows (PowerShell)

```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/99mini/git-alias/main/install/windows.ps1" -UseBasicParsing).Content
```

---

### 클론 후 설치

레포지토리를 직접 클론한 뒤 설치 스크립트를 실행합니다.

```bash
git clone https://github.com/99mini/git-alias.git
cd git-alias
```

#### macOS

```bash
cd install
bash mac.sh
```

#### Linux

```bash
cd install
bash linux.sh
```

#### Windows (PowerShell)

```powershell
cd install
powershell -ExecutionPolicy Bypass -File windows.ps1
```

---

## 설치 스크립트 기능

스크립트를 실행하면 아래 메뉴가 나타납니다.

```
╔════════════════════════════════════╗
║       Git Alias Installer          ║
╚════════════════════════════════════╝

  Install
   1) Install ALL aliases  (local workspace)
   2) Install ALL aliases  (global)
   3) Install specific aliases  (local workspace)
   4) Install specific aliases  (global)

  Remove
   5) Remove ALL aliases   (local workspace)
   6) Remove ALL aliases   (global)
   7) Remove specific aliases   (local workspace)
   8) Remove specific aliases   (global)

  Other
   9) Check dependencies
   0) Exit
```

| 옵션      | 설명                                      |
| --------- | ----------------------------------------- |
| **1 / 2** | 모든 alias를 한 번에 설치 (로컬 / 글로벌) |
| **3 / 4** | 번호를 입력해 원하는 alias만 선택 설치    |
| **5 / 6** | 설치된 모든 alias 제거 (로컬 / 글로벌)    |
| **7 / 8** | 번호를 입력해 원하는 alias만 선택 제거    |
| **9**     | fzf, pygments 설치 여부 확인 및 설치 안내 |

**로컬 vs 글로벌**

| 범위                | 적용 대상                          | 설정 파일      | 실행 위치 조건                        |
| ------------------- | ---------------------------------- | -------------- | ------------------------------------- |
| **로컬 (local)**    | 현재 git 레포지토리에만 적용       | `.git/config`  | **git 레포지토리 안에서 실행해야 함** |
| **글로벌 (global)** | 시스템 전체 모든 레포지토리에 적용 | `~/.gitconfig` | 어느 경로에서 실행해도 무관           |

> **주의**: 로컬 옵션(1, 3, 5, 7)은 git 레포지토리 내부에서 실행해야 합니다.
> 글로벌 옵션(2, 4, 6, 8)은 홈 디렉토리(`~`) 등 어느 경로에서 실행해도 됩니다.

**특정 alias 선택 설치 예시**

```
Available aliases:

    1) a
    2) aa
    3) ci
   ...

Enter numbers separated by spaces (e.g. 1 3 5),
  'all' to select all, or 'q' to go back:
> 1 3 5
```

---

## 수동 설치

설치 스크립트 없이 `.gitconfig`에 직접 추가하려면 `alias/git-aliases.gitconfig` 내용을 `~/.gitconfig`에 복사하세요.

또는 아래 명령으로 include 방식으로 연결할 수 있습니다.

```bash
git config --global include.path /절대경로/alias/git-aliases.gitconfig
```

---

## Alias 목록

### View / Info

| Alias                | 설명                           |
| -------------------- | ------------------------------ |
| `git alias`          | 설정된 모든 alias 목록 출력    |
| `git aliases`        | alias 목록 출력 (전체)         |
| `git l`              | 컬러 그래프 로그 출력          |
| `git s`              | `git status`                   |
| `git ss`             | `git status -s` (short)        |
| `git br`             | `git branch`                   |
| `git co`             | `git checkout`                 |
| `git b0`             | 현재 브랜치명 출력             |
| `git main-or-master` | main 또는 master 브랜치명 출력 |
| `git b-l`            | 브랜치 목록 (최근 커밋 순)     |
| `git remote-branch`  | 원격 브랜치 정보 출력          |
| `git repo`           | 현재 레포지토리 이름 출력      |
| `git rf-d`           | reflog (상대 날짜 포함)        |
| `git s-l`            | stash 목록 (컬러)              |

### fzf 인터랙티브 선택

| Alias                           | 설명                                   |
| ------------------------------- | -------------------------------------- |
| `git alias-select`              | alias 목록에서 fzf로 선택              |
| `git exe`                       | alias를 선택해 즉시 실행               |
| `git diff-select`               | 변경 파일을 fzf로 선택 (diff 미리보기) |
| `git branch-select`             | 로컬 브랜치를 fzf로 선택               |
| `git branch-select-all`         | 전체 브랜치(remote 포함)를 fzf로 선택  |
| `git unmerged-branch-select`    | 미병합 브랜치를 fzf로 선택             |
| `git stash-select`              | stash 항목을 fzf로 선택                |
| `git reflog-select`             | reflog 항목을 fzf로 선택               |
| `git commit-select` / `git c-s` | 커밋을 그래프에서 fzf로 선택           |

### Add / Stage

| Alias                     | 설명                         |
| ------------------------- | ---------------------------- |
| `git a`                   | 변경 파일을 fzf로 선택해 add |
| `git aa`                  | `git add .`                  |
| `git unstage` / `git uns` | 파일을 fzf로 선택해 unstage  |
| `git uns-a`               | 전체 unstage                 |

### Discard / Restore

| Alias      | 설명                                   |
| ---------- | -------------------------------------- |
| `git d-a`  | 파일을 fzf로 선택해 변경 사항 되돌리기 |
| `git d-aa` | 전체 변경 사항 되돌리기                |

### Commit

| Alias                                 | 설명                                          |
| ------------------------------------- | --------------------------------------------- |
| `git ci <message>`                    | `git commit -m`                               |
| `git ci-amend <message>` / `git ci-a` | 직전 커밋 메시지 수정                         |
| `git ci-no-edit` / `git ci-ne`        | 직전 커밋에 현재 변경 사항 추가 (메시지 유지) |
| `git aa-c`                            | add all → commit                              |
| `git a-c`                             | fzf로 파일 선택 → add → commit                |
| `git aa-cp`                           | add all → commit → push                       |

### Checkout / Branch

| Alias             | 설명                                     |
| ----------------- | ---------------------------------------- |
| `git ch`          | 브랜치를 fzf로 선택해 checkout           |
| `git ch-m`        | main/master로 checkout                   |
| `git ch-n <name>` | 새 브랜치 생성 후 checkout               |
| `git ch-nc`       | 특정 커밋에서 새 브랜치 생성 후 checkout |
| `git back`        | 현재 브랜치의 백업 브랜치 생성           |
| `git ch-back`     | 백업 브랜치 생성 후 그 브랜치로 checkout |

### Branch Management

| Alias             | 설명                                   |
| ----------------- | -------------------------------------- |
| `git d-b`         | 브랜치를 fzf로 선택해 삭제             |
| `git d-bt <name>` | 브랜치명 직접 입력해 삭제              |
| `git d-b0`        | 현재 브랜치 삭제 (main으로 이동 후)    |
| `git rename`      | 현재 브랜치 이름 변경                  |
| `git c-b`         | 병합된 브랜치 정리                     |
| `git c-ub`        | 미병합 브랜치 정리                     |
| `git t-a`         | 모든 원격 브랜치 트래킹                |
| `git u-b`         | main pull 후 모든 원격 브랜치 업데이트 |

### Push / Pull / Fetch

| Alias      | 설명                              |
| ---------- | --------------------------------- |
| `git p`    | 현재 브랜치 push                  |
| `git p-f`  | force push (`--force-with-lease`) |
| `git pl`   | 현재 브랜치 pull                  |
| `git pl-m` | main/master로 이동 후 pull        |
| `git pp`   | pull 후 push                      |
| `git f`    | `git fetch`                       |
| `git f-p`  | `git fetch --prune`               |

### Stash

| Alias     | 설명                      |
| --------- | ------------------------- |
| `git s-p` | `git stash pop`           |
| `git s-s` | add all 후 stash save     |
| `git s-a` | fzf로 stash 선택 후 apply |
| `git s-d` | fzf로 stash 선택 후 drop  |
| `git s-c` | 모든 stash 삭제           |

### Rebase

| Alias      | 설명                               |
| ---------- | ---------------------------------- |
| `git rb-m` | main/master로 rebase               |
| `git rb-b` | 선택한 브랜치로 rebase             |
| `git rb-f` | 특정 커밋 이후부터 main으로 rebase |
| `git rb-c` | `git rebase --continue`            |
| `git rb-s` | `git rebase --skip`                |
| `git rb-a` | `git rebase --abort`               |

### Reset / Revert

| Alias      | 설명                                  |
| ---------- | ------------------------------------- |
| `git rs-h` | 선택한 커밋으로 hard reset            |
| `git rs-s` | 선택한 커밋으로 soft reset            |
| `git rs`   | 선택한 커밋으로 mixed reset           |
| `git rs-r` | reflog에서 선택한 시점으로 hard reset |
| `git rv`   | 선택한 커밋 revert                    |
| `git drop` | 선택한 커밋 drop (interactive rebase) |

### Cherry-pick

| Alias      | 설명                          |
| ---------- | ----------------------------- |
| `git cp`   | 선택한 커밋 cherry-pick       |
| `git cp-m` | 범위 선택 cherry-pick         |
| `git cp-b` | 새 브랜치 생성 후 cherry-pick |

### Deploy / Misc (macOS)

| Alias      | 설명                                 |
| ---------- | ------------------------------------ |
| `git o`    | GitHub 페이지 열기 (`git open` 필요) |
| `git dp`   | staging 배포 메시지 클립보드 복사    |
| `git dp-p` | production 배포 메시지 클립보드 복사 |
