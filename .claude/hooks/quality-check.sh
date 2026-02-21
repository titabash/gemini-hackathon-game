#!/usr/bin/env bash

# Hook InputからJSONをパース
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# ファイルパスが空の場合は終了
if [ -z "$file_path" ]; then
  exit 0
fi

# プロジェクトルート取得
project_root=""
if [[ "$file_path" =~ /frontend/ ]]; then
  project_root="${file_path%/frontend/*}"
elif [[ "$file_path" =~ /backend-py/ ]]; then
  project_root="${file_path%/backend-py/*}"
elif [[ "$file_path" =~ /supabase/ ]]; then
  project_root="${file_path%/supabase/*}"
elif [[ "$file_path" =~ /drizzle/ ]]; then
  project_root="${file_path%/drizzle/*}"
fi

# プロジェクトルートが取得できない場合は終了
if [ -z "$project_root" ]; then
  exit 0
fi

cd "$project_root" || exit 0

# 結果を収集
results=""
has_error=0

# Frontend (Flutter/Dart)
if [[ "$file_path" =~ /frontend/.*\.dart$ ]]; then
  # 自動生成ファイルはスキップ
  if [[ "$file_path" =~ \.g\.dart$ ]] || [[ "$file_path" =~ \.freezed\.dart$ ]] || [[ "$file_path" =~ \.gr\.dart$ ]] || [[ "$file_path" =~ /generated/ ]]; then
    exit 0
  fi

  echo "🔍 Running quality checks for Flutter/Dart..." >&2

  # Format check
  if ! make hook-dart-check FILE_PATH="$file_path" 2>&1; then
    has_error=1
    results+="❌ Dart format/analyze failed\n"
  else
    results+="✅ Dart format/analyze passed\n"
  fi
fi

# Backend Python
if [[ "$file_path" =~ /backend-py/app/.*\.py$ ]]; then
  echo "🔍 Running quality checks for backend-py..." >&2

  # Format + Lint + Type check
  if ! make hook-python-check FILE_PATH="$file_path" 2>&1; then
    has_error=1
    results+="❌ Python format/lint/type-check failed\n"
  else
    results+="✅ Python format/lint/type-check passed\n"
  fi
fi

# Edge Functions (Deno TypeScript)
if [[ "$file_path" =~ /supabase/functions/.*\.ts$ ]]; then
  echo "🔍 Running quality checks for edge functions..." >&2

  if ! make check-edge-functions 2>&1; then
    has_error=1
    results+="❌ Edge Functions check failed\n"
  else
    results+="✅ Edge Functions check passed\n"
  fi

  if ! make fix-format-edge-functions 2>&1; then
    has_error=1
    results+="❌ Edge Functions format failed\n"
  else
    results+="✅ Edge Functions format passed\n"
  fi
fi

# Drizzle (TypeScript)
if [[ "$file_path" =~ /drizzle/.*\.ts$ ]]; then
  echo "🔍 Running quality checks for drizzle..." >&2

  # Note: Drizzleには専用のlint/formatコマンドがないため、
  # Edge Functionsのチェックで代用（同じTypeScript）
  if command -v deno >/dev/null 2>&1; then
    if ! deno fmt --check "$file_path" 2>&1; then
      has_error=1
      results+="❌ Drizzle format failed\n"
    else
      results+="✅ Drizzle format passed\n"
    fi

    if ! deno lint "$file_path" 2>&1; then
      has_error=1
      results+="❌ Drizzle lint failed\n"
    else
      results+="✅ Drizzle lint passed\n"
    fi
  else
    results+="⚠️  Deno not found, skipping Drizzle checks\n"
  fi
fi

# 結果を表示
if [ -n "$results" ]; then
  if [ "$has_error" -eq 1 ]; then
    # エラーがある場合のみ Claude に表示
    echo -e "\n📋 Quality Check Results:\n$results" >&2
    exit 2
  fi
  # 成功時は transcript mode でのみ表示
  echo -e "\n📋 Quality Check Results:\n$results"
fi

exit 0
