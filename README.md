# 개발 워크스테이션 구축 미션

## 1) 프로젝트 개요
터미널(리눅스 CLI), Docker, Git/GitHub을 직접 세팅하고 다뤄보며,
"내 컴퓨터에서만 되는" 문제를 줄이고 재현 가능한 개발 환경을 구성하는 것을 목표로 한 미션이다.
터미널 기본 조작 → 권한 관리 → Docker 설치/운영 → Dockerfile 기반 커스텀 이미지 제작 →
포트 매핑 → 바인드 마운트 → 볼륨 영속성 → Git/GitHub 연동 순으로 진행했다.

## 2) 실행 환경
- OS: Windows 11 + WSL2 (Ubuntu)
- Shell: bash (WSL)
- 컨테이너 엔진: Docker Desktop (WSL2 Integration)
- Docker: 29.6.2
- Git: 2.53.0

## 3) 수행 항목 체크리스트
- [x] 터미널 기본 조작 (pwd/ls/mkdir/cp/mv/rm/cat/touch)
- [x] 권한 변경 실습 (파일 1개 + 디렉토리 1개)
- [x] Docker 설치 및 점검 (`docker --version`, `docker info`)
- [x] Docker 기본 운영 명령 (`images`, `ps -a`, `logs`, `stats`)
- [x] hello-world / ubuntu 컨테이너 실행, run vs exec 차이 관찰
- [x] Dockerfile 기반 커스텀 이미지(my-web) 빌드
- [x] 포트 매핑 접속 (8080, 8081 — 2회)
- [x] 바인드 마운트 반영 확인
- [x] Docker 볼륨 영속성 검증
- [x] Git 설정 + GitHub 연동 (force push로 저장소 재구성)

## 4) 검증 방법 및 결과 위치

| 검증 항목 | 사용 명령 | 결과 로그 |
|---|---|---|
| 터미널 기본 조작 | `pwd`, `ls -la`, `mkdir`, `cp`, `mv`, `rm`, `cat`, `touch` | [logs/terminal_log.txt](logs/terminal_log.txt) |
| 권한 실습 | `chmod 600/700`, `ls -l`, `ls -ld` | [logs/terminal_log_02_permission.txt](logs/terminal_log_02_permission.txt) |
| Docker 기본/운영 명령 | `docker --version`, `docker info`, `docker run hello-world`, `docker run -it ubuntu bash`, `docker exec`, `docker images`, `docker ps -a`, `docker logs`, `docker stats` | [logs/terminal_log_03_docker_basics.txt](logs/terminal_log_03_docker_basics.txt) |
| Dockerfile 빌드/포트매핑 | `docker build`, `docker run -d -p 8080:80`, `docker run -d -p 8081:80`, `curl` | [logs/terminal_log_04_dockerfile_build.txt](logs/terminal_log_04_dockerfile_build.txt) |
| 인코딩 이슈 수정(8080) | `docker build`, `docker run`, `curl` | [logs/terminal_log_05_charset_fix.txt](logs/terminal_log_05_charset_fix.txt) |
| 인코딩 이슈 수정(8081) | `docker build`, `docker run`, `curl` | [logs/terminal_log_06_charset_8081_fix.txt](logs/terminal_log_06_charset_8081_fix.txt) |
| 바인드 마운트 | `docker run -v "$(pwd)/app:/usr/share/nginx/html"`, `curl` (전/후 비교) | [logs/terminal_log_07_bind_mount.txt](logs/terminal_log_07_bind_mount.txt) |
| 볼륨 영속성 | `docker volume create`, `docker exec`, `docker rm -f`, 재확인 | [logs/terminal_log_08_volume.txt](logs/terminal_log_08_volume.txt) |
| Git 설정/GitHub 연동 | `git config`, `git init`, `git remote add`, `git commit`, `git push -f` | [logs/terminal_log_09_git_setup.txt](logs/terminal_log_09_git_setup.txt) |

## 5) 웹 서버 컨테이너 구성

**Dockerfile** ([Dockerfile](Dockerfile)):
```dockerfile
FROM nginx:alpine
LABEL org.opencontainers.image.title="my-custom-nginx"
ENV APP_ENV=dev
COPY app/ /usr/share/nginx/html/
RUN echo "charset utf-8;" >> /etc/nginx/conf.d/charset.conf
```

- 베이스 이미지: `nginx:alpine`
- 커스텀 포인트:
  - `LABEL`로 이미지 메타데이터(제목) 명시
  - `ENV APP_ENV=dev`로 환경변수 주입
  - `COPY app/`로 직접 작성한 정적 페이지 삽입
  - nginx 설정에 `charset utf-8;` 추가하여 브라우저 한글 인코딩 깨짐 방지

**빌드/실행**
```bash
docker build -t my-web:1.0 .
docker run -d -p 8080:80 --name my-web-8080 my-web:1.0
docker run -d -p 8081:80 --name my-web-8081 my-web:2.0
```

## 6) 포트 매핑 접속 증거
- `http://localhost:8080` → "안녕하세요 저는 코디세이 루키마리너2기 김주환입니다!"
- `http://localhost:8081` → "안녕하세요 저는 코디세이 루키마리너2기 김주환입니다!!!!"
- (서로 다른 이미지 버전이 각기 다른 포트에서 정상 응답함을 `curl` 및 브라우저로 확인)
- 스크린샷: [screenshots/](screenshots/) *(브라우저 주소창 포함 캡처 추가 예정)*

## 7) 바인드 마운트 반영 증거
```bash
docker run -d -p 8082:80 --name my-web-bind -v "$(pwd)/app:/usr/share/nginx/html" my-web:1.0
curl http://localhost:8082
# → 기존 내용

echo '...Updated via bind mount!...' > app/index.html
curl http://localhost:8082
# → 컨테이너 재시작 없이 즉시 변경 내용 반영 확인
```

## 8) Docker 볼륨 영속성 증거
```bash
docker volume create mydata
docker run -d --name vol-test -v mydata:/data ubuntu sleep infinity
docker exec -it vol-test bash -c "echo '볼륨 영속성 테스트 - 김주환' > /data/hello.txt && cat /data/hello.txt"
docker rm -f vol-test

docker run -d --name vol-test2 -v mydata:/data ubuntu sleep infinity
docker exec -it vol-test2 bash -c "cat /data/hello.txt"
# → vol-test 완전 삭제 후에도 동일 데이터 유지 확인
```

## 9) Git / GitHub 연동
```bash
git config --global user.name "joohwan231"
git config --global user.email "joohwan231@***"
git config --global init.defaultBranch main
git init
git remote add origin https://github.com/joohwan231/E1-1.git
git add .
git commit -m "Rebuild workstation mission from WSL environment"
git push -f origin main
```
- 인증은 GitHub Personal Access Token(PAT)을 사용 (비밀번호 직접 입력 방식은 미지원)

## 10) 트러블슈팅

**#1. 컨테이너 내부에서 `docker` 명령어 실행 시 오류**
- 문제: `docker run -it ubuntu bash`로 컨테이너에 진입한 뒤 내부에서 `docker ps` 실행 시 `command not found` 에러
- 원인 가설: 컨테이너는 호스트와 분리된 격리 환경이라 Docker 클라이언트 자체가 설치되어 있지 않음
- 확인: 컨테이너 밖(호스트)에서 동일 명령 실행 시 정상 동작
- 해결: `docker` 관련 명령은 항상 호스트 터미널에서 실행

**#2. 컨테이너 이름 충돌 오류**
- 문제: `docker run -d -p 8080:80 --name my-web-8080 ...` 실행 시 `Conflict. container name already in use` 에러
- 원인 가설: 동일한 이름의 컨테이너가 이미 존재
- 확인: `docker ps -a`로 기존 컨테이너 존재 확인
- 해결: `docker rm -f <컨테이너명>`으로 기존 컨테이너 제거 후 재실행

**#3. 브라우저에서 한글 깨짐 현상**
- 문제: `curl` 응답은 정상인데 브라우저로 접속 시 한글이 깨져서 표시됨
- 원인 가설: nginx 응답에 charset이 명시되지 않아 브라우저가 잘못된 인코딩으로 추측
- 확인: 응답 헤더에 charset 정보 부재
- 해결: nginx 설정에 `charset utf-8;` 추가 + HTML에 `<meta charset="UTF-8">` 추가로 이중 보완

## 11) 참고 사항 (재현성)
- Windows 사용자는 Docker Desktop 설치 후 **Settings → Resources → WSL Integration**에서 사용 중인 WSL 배포판 연동을 켜야 `docker` 명령을 WSL bash에서 사용할 수 있다.
- 윈도우 NTFS는 유닉스 `rwx` 권한 체계를 사용하지 않으므로, 권한(chmod) 실습은 WSL(Ubuntu) 환경에서 진행했다.
- 여러 줄 명령어를 터미널에 붙여넣을 때 발생하는 제어 문자 기록 문제는 `bind 'set enable-bracketed-paste off'` 설정으로 해결했다.
