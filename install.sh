#!/usr/bin/env bash
# claude-skills-hub installer
# 使用方法见 README.md 的 "在线安装" 章节

set -euo pipefail

REPO_OWNER="${CSH_OWNER:-AriesOxO}"
REPO_NAME="${CSH_REPO:-claude-skills-hub}"
REPO_BRANCH="${CSH_BRANCH:-master}"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

TARBALL_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_BRANCH}.tar.gz"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"

if [ -t 1 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi

log_info()    { echo "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo "${GREEN}[OK]${NC}   $1" >&2; }
log_warn()    { echo "${YELLOW}[WARN]${NC} $1" >&2; }
log_error()   { echo "${RED}[ERR]${NC}  $1" >&2; }

usage() {
  cat <<EOF
Claude Skills Hub 安装器

用法:
  csh <command> [args...]

命令:
  install <skill>...   安装一个或多个 skill
  list                 列出仓库中所有可用 skills
  installed            列出本地已安装的 skills
  update [skill]...    更新（不指定则更新所有已安装）
  uninstall <skill>... 卸载 skill
  help                 显示此帮助

示例:
  # 一次性安装（无需保存脚本到本地）
  bash -c "\$(curl -sSL ${RAW_URL}/install.sh)" -- install parallel-agent

  # 安装到 PATH 长期使用
  curl -sSL ${RAW_URL}/install.sh -o ~/.local/bin/csh && chmod +x ~/.local/bin/csh
  csh install parallel-agent

环境变量:
  CLAUDE_SKILLS_DIR    自定义 skills 安装目录（默认: ~/.claude/skills）
  CSH_BRANCH           使用特定分支/tag（默认: master）
  CSH_OWNER / CSH_REPO 自定义仓库源（默认: ${REPO_OWNER}/${REPO_NAME}）
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { log_error "缺少命令: $1，请先安装"; exit 1; }
}

http_download() {
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -H "User-Agent: csh-installer" "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$out" --header="User-Agent: csh-installer" "$url"
  else
    log_error "需要 curl 或 wget"; exit 1
  fi
}

CSH_TMPDIR=""
cleanup() {
  if [ -n "${CSH_TMPDIR:-}" ] && [ -d "$CSH_TMPDIR" ]; then
    rm -rf "$CSH_TMPDIR"
  fi
}
trap cleanup EXIT

ensure_tmpdir() {
  if [ -z "${CSH_TMPDIR:-}" ]; then
    CSH_TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t csh)
  fi
}

cmd_list() {
  require_cmd tar
  log_info "从 ${REPO_OWNER}/${REPO_NAME}@${REPO_BRANCH} 获取可用 skills..."
  ensure_tmpdir
  local src_root
  src_root=$(fetch_tarball "$CSH_TMPDIR")
  local found=0
  for d in "$src_root"/*/; do
    if [ -d "$d" ]; then
      local name
      name=$(basename "$d")
      [ "$name" = "_template" ] && continue
      echo "  - $name"
      found=1
    fi
  done
  if [ "$found" = "0" ]; then
    log_warn "未找到任何 skill"
  fi
}

cmd_installed() {
  if [ ! -d "$SKILLS_DIR" ]; then
    log_info "skills 目录尚未创建: $SKILLS_DIR"
    return 0
  fi
  log_info "已安装的 skills（位于 $SKILLS_DIR）:"
  local found=0
  for d in "$SKILLS_DIR"/*/; do
    if [ -d "$d" ]; then
      echo "  - $(basename "$d")"
      found=1
    fi
  done
  if [ "$found" = "0" ]; then
    log_warn "没有已安装的 skills"
  fi
}

fetch_tarball() {
  local tmpdir="$1"
  local tarpath="$tmpdir/repo.tar.gz"
  log_info "下载 ${REPO_NAME}@${REPO_BRANCH}..."
  http_download "$TARBALL_URL" "$tarpath"
  tar -xzf "$tarpath" -C "$tmpdir"
  echo "$tmpdir/${REPO_NAME}-${REPO_BRANCH}/skills"
}

cmd_install() {
  [ $# -eq 0 ] && { log_error "需要指定至少一个 skill 名称"; usage; exit 1; }
  require_cmd tar

  mkdir -p "$SKILLS_DIR"
  ensure_tmpdir

  local src_root
  src_root=$(fetch_tarball "$CSH_TMPDIR")

  local needs_snippet=()
  for skill in "$@"; do
    if [ ! -d "$src_root/$skill" ]; then
      log_error "skill 不存在: $skill（运行 'csh list' 查看可用 skills）"
      continue
    fi
    local dest="$SKILLS_DIR/$skill"
    if [ -d "$dest" ]; then
      log_warn "已存在，将覆盖: $dest"
      rm -rf "$dest"
    fi
    cp -r "$src_root/$skill" "$dest"
    log_success "已安装: $skill -> $dest"

    if [ -f "$dest/claude-md-snippet.md" ]; then
      needs_snippet+=("$skill")
    fi
  done

  if [ ${#needs_snippet[@]} -gt 0 ]; then
    echo ""
    log_warn "以下 skill 需要在 CLAUDE.md 中追加配套配置:"
    for s in "${needs_snippet[@]}"; do
      echo "    - $SKILLS_DIR/$s/claude-md-snippet.md"
    done
  fi
}

cmd_update() {
  if [ $# -eq 0 ]; then
    if [ ! -d "$SKILLS_DIR" ]; then
      log_warn "skills 目录不存在: $SKILLS_DIR"
      return 0
    fi
    local skills=()
    for d in "$SKILLS_DIR"/*/; do
      [ -d "$d" ] && skills+=("$(basename "$d")")
    done
    if [ ${#skills[@]} -eq 0 ]; then
      log_info "没有已安装的 skills，无需更新"
      return 0
    fi
    log_info "将更新: ${skills[*]}"
    cmd_install "${skills[@]}"
  else
    cmd_install "$@"
  fi
}

cmd_uninstall() {
  [ $# -eq 0 ] && { log_error "需要指定至少一个 skill 名称"; exit 1; }
  for skill in "$@"; do
    local dest="$SKILLS_DIR/$skill"
    if [ ! -d "$dest" ]; then
      log_warn "未安装: $skill"
      continue
    fi
    rm -rf "$dest"
    log_success "已卸载: $skill"
  done
}

main() {
  local cmd="${1:-help}"
  [ $# -gt 0 ] && shift
  case "$cmd" in
    install)              cmd_install "$@" ;;
    list|ls)              cmd_list ;;
    installed)            cmd_installed ;;
    update|upgrade)       cmd_update "$@" ;;
    uninstall|remove|rm)  cmd_uninstall "$@" ;;
    help|-h|--help|"")    usage ;;
    *) log_error "未知命令: $cmd"; usage; exit 1 ;;
  esac
}

main "$@"
