#!/usr/bin/env bash
# claude-skills-hub installer
# 使用方法见 README.md 的 "在线安装" 章节

set -euo pipefail

REPO_OWNER="${CSH_OWNER:-AriesOxO}"
REPO_NAME="${CSH_REPO:-claude-skills-hub}"
REPO_BRANCH="${CSH_BRANCH:-master}"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CLAUDE_MD="${CLAUDE_MD_PATH:-$HOME/.claude/CLAUDE.md}"
CSH_CACHE_TTL="${CSH_CACHE_TTL:-300}"

TARBALL_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_BRANCH}.tar.gz"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"
CACHE_DIR="${TMPDIR:-/tmp}/csh-cache-${REPO_OWNER}-${REPO_NAME}-${REPO_BRANCH}"

if [ -t 1 ] && [ -t 2 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; NC=""
fi

log_info()    { echo "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo "${GREEN}[OK]${NC}   $1" >&2; }
log_warn()    { echo "${YELLOW}[WARN]${NC} $1" >&2; }
log_error()   { echo "${RED}[ERR]${NC}  $1" >&2; }

usage() {
  cat >&2 <<EOF
Claude Skills Hub 安装器

用法:
  csh <command> [options] [args...]

命令:
  install [--auto-config] [--local <path>] <skill>...
                         安装 skill（支持自动配置 CLAUDE.md 和本地路径安装）
  list [--verbose]       列出仓库中所有可用 skills（-v 显示描述）
  installed              列出本地已安装的 skills
  update [skill]...      更新（不指定则更新所有已安装）
  uninstall <skill>...   卸载 skill
  help                   显示此帮助

选项:
  --auto-config    安装后自动将 claude-md-snippet.md 追加到 CLAUDE.md
  --local <path>   从本地目录安装（用于贡献者本地验证）
  --verbose / -v   list 命令显示每个 skill 的描述

示例:
  bash -c "\$(curl -sSL ${RAW_URL}/install.sh)" csh install --auto-config parallel-agent
  csh install --local ./skills/my-skill my-skill
  csh list --verbose

环境变量:
  CLAUDE_SKILLS_DIR    自定义 skills 安装目录（默认: ~/.claude/skills）
  CLAUDE_MD_PATH       自定义 CLAUDE.md 路径（默认: ~/.claude/CLAUDE.md）
  CSH_BRANCH           使用特定分支/tag（默认: master）
  CSH_CACHE_TTL        tarball 缓存有效期秒数（默认: 300）
  CSH_OWNER / CSH_REPO 自定义仓库源（默认: ${REPO_OWNER}/${REPO_NAME}）
EOF
}
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { log_error "缺少命令: $1，请先安装"; exit 1; }
}

http_download() {
  local url="$1" out="$2" retries=3
  local i=0
  while [ $i -lt $retries ]; do
    if command -v curl >/dev/null 2>&1; then
      if curl -fsSL --retry 2 --connect-timeout 15 -H "User-Agent: csh-installer" "$url" -o "$out" 2>/dev/null; then
        return 0
      fi
    elif command -v wget >/dev/null 2>&1; then
      if wget -qO "$out" --timeout=15 --tries=2 --header="User-Agent: csh-installer" "$url" 2>/dev/null; then
        return 0
      fi
    else
      log_error "需要 curl 或 wget"; exit 1
    fi
    i=$((i + 1))
    [ $i -lt $retries ] && log_warn "下载失败，重试 ($i/$retries)..." && sleep 2
  done
  log_error "下载失败: $url（已重试 $retries 次）"
  log_error "如果是网络问题，尝试设置代理: export https_proxy=http://your-proxy:port"
  exit 1
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

fetch_tarball() {
  local tmpdir="$1"
  local tarpath="$tmpdir/repo.tar.gz"
  local skills_root="$tmpdir/${REPO_NAME}-${REPO_BRANCH}/skills"

  # 缓存机制：如果缓存目录存在且未过期，直接复用
  if [ -d "$CACHE_DIR" ] && [ -f "$CACHE_DIR/.timestamp" ]; then
    local cached_time now_time age
    cached_time=$(cat "$CACHE_DIR/.timestamp")
    now_time=$(date +%s)
    age=$((now_time - cached_time))
    if [ $age -lt "$CSH_CACHE_TTL" ]; then
      log_info "使用缓存（${age}s 前下载）"
      echo "$CACHE_DIR/skills"
      return 0
    fi
  fi

  log_info "下载 ${REPO_NAME}@${REPO_BRANCH}..."
  http_download "$TARBALL_URL" "$tarpath"
  tar -xzf "$tarpath" -C "$tmpdir"

  # 写入缓存
  rm -rf "$CACHE_DIR"
  cp -r "$tmpdir/${REPO_NAME}-${REPO_BRANCH}" "$CACHE_DIR"
  date +%s > "$CACHE_DIR/.timestamp"

  echo "$skills_root"
}

# 从 SKILL.md 的 frontmatter 提取 description
extract_description() {
  local skill_md="$1"
  [ ! -f "$skill_md" ] && return
  sed -n '/^---$/,/^---$/p' "$skill_md" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | head -1
}
cmd_list() {
  require_cmd tar
  local verbose=0
  if [ "${1:-}" = "--verbose" ] || [ "${1:-}" = "-v" ]; then
    verbose=1
  fi
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
      if [ "$verbose" = "1" ]; then
        local desc
        desc=$(extract_description "$d/SKILL.md")
        if [ -n "$desc" ]; then
          printf "  ${CYAN}%-20s${NC} %s\n" "$name" "$desc" >&2
        else
          printf "  ${CYAN}%-20s${NC} (无描述)\n" "$name" >&2
        fi
      else
        echo "  - $name" >&2
      fi
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
      echo "  - $(basename "$d")" >&2
      found=1
    fi
  done
  if [ "$found" = "0" ]; then
    log_warn "没有已安装的 skills"
  fi
}

auto_config_claude_md() {
  local skill="$1" snippet_path="$SKILLS_DIR/$1/claude-md-snippet.md"
  [ ! -f "$snippet_path" ] && return 0

  # 提取代码块中的内容（````markdown 和 ```` 之间）
  local content
  content=$(sed -n '/^````markdown$/,/^````$/p' "$snippet_path" | sed '1d;$d')
  if [ -z "$content" ]; then
    log_warn "无法从 $snippet_path 提取配置内容，请手动查看"
    return 0
  fi

  # 检查是否已经配置过
  if [ -f "$CLAUDE_MD" ] && grep -qF "## 并行子代理策略" "$CLAUDE_MD" 2>/dev/null; then
    log_info "$skill 的 CLAUDE.md 配置已存在，跳过"
    return 0
  fi

  mkdir -p "$(dirname "$CLAUDE_MD")"
  printf "\n\n%s\n" "$content" >> "$CLAUDE_MD"
  log_success "已将 $skill 配置追加到 $CLAUDE_MD"
}

cmd_install() {
  local auto_config=0 local_path="" skills_to_install=()
  local failed=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --auto-config) auto_config=1; shift ;;
      --local)
        [ $# -lt 2 ] && { log_error "--local 需要指定路径"; exit 1; }
        local_path="$2"; shift 2 ;;
      -*) log_error "未知选项: $1"; exit 1 ;;
      *) skills_to_install+=("$1"); shift ;;
    esac
  done

  [ ${#skills_to_install[@]} -eq 0 ] && { log_error "需要指定至少一个 skill 名称"; usage; exit 1; }

  mkdir -p "$SKILLS_DIR"

  local src_root=""
  if [ -n "$local_path" ]; then
    # 本地模式：直接从指定路径安装
    if [ ! -d "$local_path" ]; then
      log_error "本地路径不存在: $local_path"
      exit 1
    fi
    src_root="$local_path"
    log_info "从本地路径安装: $local_path"
  else
    require_cmd tar
    ensure_tmpdir
    src_root=$(fetch_tarball "$CSH_TMPDIR")
  fi

  local needs_snippet=()
  for skill in "${skills_to_install[@]}"; do
    local src_skill_dir
    if [ -n "$local_path" ]; then
      # 本地模式：local_path 本身就是 skill 目录
      src_skill_dir="$local_path"
      if [ ! -f "$src_skill_dir/SKILL.md" ]; then
        log_error "目录中缺少 SKILL.md: $src_skill_dir"
        failed=1
        continue
      fi
    else
      src_skill_dir="$src_root/$skill"
      if [ ! -d "$src_skill_dir" ]; then
        log_error "skill 不存在: $skill（运行 'csh list' 查看可用 skills）"
        failed=1
        continue
      fi
    fi
    local dest="$SKILLS_DIR/$skill"
    if [ -d "$dest" ]; then
      log_warn "已存在，将覆盖: $dest"
      rm -rf "$dest"
    fi
    cp -r "$src_skill_dir" "$dest"
    log_success "已安装: $skill -> $dest"

    if [ -f "$dest/claude-md-snippet.md" ]; then
      needs_snippet+=("$skill")
    fi
  done

  # 处理 CLAUDE.md 配置
  if [ ${#needs_snippet[@]} -gt 0 ]; then
    echo "" >&2
    if [ "$auto_config" = "1" ]; then
      for s in "${needs_snippet[@]}"; do
        auto_config_claude_md "$s"
      done
    elif [ -t 0 ]; then
      log_warn "以下 skill 需要在 CLAUDE.md 中追加配套配置:"
      for s in "${needs_snippet[@]}"; do
        echo "    - $SKILLS_DIR/$s/claude-md-snippet.md" >&2
      done
      echo "" >&2
      printf "  是否自动追加到 %s? [y/N] " "$CLAUDE_MD" >&2
      read -r answer
      if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        for s in "${needs_snippet[@]}"; do
          auto_config_claude_md "$s"
        done
      else
        log_info "跳过自动配置。请手动查看上述文件并追加到 CLAUDE.md"
      fi
    else
      log_warn "以下 skill 需要在 CLAUDE.md 中追加配套配置:"
      for s in "${needs_snippet[@]}"; do
        echo "    - $SKILLS_DIR/$s/claude-md-snippet.md" >&2
      done
      log_info "提示: 使用 --auto-config 可自动追加"
    fi
  fi

  return "$failed"
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
    list|ls)              cmd_list "$@" ;;
    installed)            cmd_installed ;;
    update|upgrade)       cmd_update "$@" ;;
    uninstall|remove|rm)  cmd_uninstall "$@" ;;
    help|-h|--help|"")    usage ;;
    *) log_error "未知命令: $cmd"; usage; exit 1 ;;
  esac
}

main "$@"
