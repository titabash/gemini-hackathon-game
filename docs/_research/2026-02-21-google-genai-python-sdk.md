# google-genai Python SDK 調査レポート

## 調査情報
- **調査日**: 2026-02-21
- **調査者**: spec agent

## バージョン情報
- **パッケージ名**: `google-genai` (PyPI)
- **現在使用中**: 未導入
- **最新バージョン**: v1.64.0 (2026-02-19 リリース)
- **推奨バージョン**: v1.64.0
- **Python要件**: >= 3.10
- **ライセンス**: Apache-2.0

**重要**: 旧パッケージ `google-generativeai` は非推奨。必ず `google-genai` を使用すること。

## インストール

```bash
pip install google-genai

# 高速 async クライアントが必要な場合
pip install google-genai[aiohttp]
```

## 破壊的変更
- 旧 SDK (`google-generativeai`) からの移行: `genai.configure(api_key=...)` / `genai.GenerativeModel(...)` パターンは使用不可
- 新 SDK は `from google import genai` + `client = genai.Client()` パターン

---

## 1. クライアント初期化

### Gemini Developer API（API Key 認証）

```python
from google import genai

# 環境変数 GEMINI_API_KEY または GOOGLE_API_KEY を自動読み取り
client = genai.Client()

# 明示的にAPI Keyを指定
client = genai.Client(api_key="YOUR_API_KEY")
```

### Vertex AI

```python
client = genai.Client(
    vertexai=True,
    project="my-project-id",
    location="us-central1",
)
```

---

## 2. 基本的なテキスト生成

```python
from google import genai

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Why is the sky blue?",
)
print(response.text)
```

---

## 3. GenerateContentConfig の全パラメータ

```python
from google import genai
from google.genai import types

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Your prompt here",
    config=types.GenerateContentConfig(
        # システム指示
        system_instruction="you are a helpful assistant",

        # 生成パラメータ
        temperature=0.7,        # 0.0-2.0 (モデルによる)
        top_p=0.95,
        top_k=20,
        max_output_tokens=4096,
        stop_sequences=["\n"],
        seed=42,

        # レスポンスモダリティ
        response_modalities=["TEXT"],  # ["TEXT"], ["IMAGE"], ["TEXT", "IMAGE"]

        # 構造化出力
        response_mime_type="application/json",
        response_json_schema=MyPydanticModel.model_json_schema(),
        # または response_schema=types.Schema(...) (SDK ネイティブ型)

        # 安全設定
        safety_settings=[
            types.SafetySetting(
                category="HARM_CATEGORY_HATE_SPEECH",
                threshold="BLOCK_ONLY_HIGH",
            ),
        ],

        # ツール
        tools=[get_current_weather],  # Python関数、またはdict

        # 画像生成設定
        image_config=types.ImageConfig(
            aspect_ratio="16:9",  # "1:1","2:3","3:2","3:4","4:3","4:5","5:4","9:16","16:9","21:9"
            image_size="2K",      # "1K","2K","4K" (大文字Kのみ)
        ),
    ),
)
```

### system_instruction の使用例

```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Tell me a story in 100 words.",
    config=types.GenerateContentConfig(
        system_instruction="you are a story teller for kids under 5 years old",
        max_output_tokens=400,
    ),
)
```

### safety_settings の使用例

```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="say something bad",
    config=types.GenerateContentConfig(
        safety_settings=[
            types.SafetySetting(
                category="HARM_CATEGORY_HATE_SPEECH",
                threshold="BLOCK_ONLY_HIGH",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_HARASSMENT",
                threshold="BLOCK_ONLY_HIGH",
            ),
        ],
    ),
)
```

**利用可能な category 値:**
- `HARM_CATEGORY_HATE_SPEECH`
- `HARM_CATEGORY_HARASSMENT`
- `HARM_CATEGORY_SEXUALLY_EXPLICIT`
- `HARM_CATEGORY_DANGEROUS_CONTENT`

**利用可能な threshold 値:**
- `BLOCK_NONE`
- `BLOCK_ONLY_HIGH`
- `BLOCK_MEDIUM_AND_ABOVE`
- `BLOCK_LOW_AND_ABOVE`

---

## 4. 構造化出力 (Structured Output) with Pydantic

### 方法1: response_json_schema (推奨)

Pydantic モデルの `.model_json_schema()` を渡す方法。最も柔軟。

```python
from google import genai
from google.genai import types
from pydantic import BaseModel, Field
from typing import List, Optional

class Ingredient(BaseModel):
    name: str = Field(description="Name of the ingredient.")
    quantity: str = Field(description="Quantity of the ingredient, including units.")

class Recipe(BaseModel):
    recipe_name: str = Field(description="The name of the recipe.")
    prep_time_minutes: Optional[int] = Field(description="Optional time in minutes.")
    ingredients: List[Ingredient]
    instructions: List[str]

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Extract the recipe from this text: ...",
    config={
        "response_mime_type": "application/json",
        "response_json_schema": Recipe.model_json_schema(),
    },
)

# Pydantic モデルとしてパース
recipe = Recipe.model_validate_json(response.text)
print(recipe)
```

### 方法2: response_json_schema に Pydantic クラスを直接渡す

```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Your prompt",
    config=types.GenerateContentConfig(
        response_mime_type="application/json",
        response_json_schema=Recipe,  # Pydantic クラスを直接渡すことも可能
    ),
)
```

### 方法3: response_schema (SDK ネイティブ型)

```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Your prompt",
    config=types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=types.Schema(
            type="OBJECT",
            properties={
                "name": types.Schema(type="STRING"),
                "age": types.Schema(type="INTEGER"),
            },
            required=["name", "age"],
        ),
    ),
)
```

### ストリーミング + 構造化出力

```python
from pydantic import BaseModel
from typing import Literal

class Feedback(BaseModel):
    sentiment: Literal["positive", "neutral", "negative"]
    summary: str

response_stream = client.models.generate_content_stream(
    model="gemini-2.5-flash",
    contents="The new UI is incredibly intuitive...",
    config={
        "response_mime_type": "application/json",
        "response_json_schema": Feedback.model_json_schema(),
    },
)

full_text = ""
for chunk in response_stream:
    text = chunk.candidates[0].content.parts[0].text
    full_text += text
    print(text, end="")

feedback = Feedback.model_validate_json(full_text)
```

---

## 5. Async API

### 基本パターン: `client.aio.models.generate_content`

```python
from google import genai
from google.genai.types import GenerateContentConfig

client = genai.Client()

# await で非同期呼び出し
response = await client.aio.models.generate_content(
    model="gemini-2.5-flash",
    contents="Tell me a story in 300 words.",
)
print(response.text)
```

### GenerateContentConfig 付き

```python
from google.genai.types import GenerateContentConfig, HttpOptions

client = genai.Client(http_options=HttpOptions(api_version="v1"))

response = await client.aio.models.generate_content(
    model="gemini-2.5-flash",
    contents="Compose a song about a time-traveling squirrel.",
    config=GenerateContentConfig(
        response_modalities=["TEXT"],
        temperature=0.8,
        system_instruction="You are a creative songwriter.",
    ),
)
print(response.text)
```

### Context Manager パターン

```python
async with genai.Client().aio as aclient:
    response = await aclient.models.generate_content(
        model="gemini-2.5-flash",
        contents="Hello",
    )
    print(response.text)
```

### 明示的クローズ

```python
aclient = genai.Client().aio
try:
    response = await aclient.models.generate_content(
        model="gemini-2.5-flash",
        contents="Hello",
    )
finally:
    await aclient.aclose()
```

### Async ストリーミング

```python
async for chunk in await client.aio.models.generate_content_stream(
    model="gemini-2.5-flash",
    contents="Write a long story...",
):
    print(chunk.text, end="")
```

---

## 6. 画像生成

### モデル一覧

| モデル | 用途 | 品質 |
|--------|------|------|
| `gemini-2.5-flash-image` | 高速画像生成・編集 | 速度重視 |
| `gemini-3-pro-image-preview` | 高品質画像生成・編集 | 品質重視 |

### テキストから画像生成

```python
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents="Create a picture of a cat sitting on a rainbow",
)

for part in response.parts:
    if part.text is not None:
        print(part.text)
    elif part.inline_data is not None:
        image = part.as_image()
        image.save("generated_image.png")
```

### 画像編集（テキスト + 画像 -> 画像）

```python
from PIL import Image

image = Image.open("cat.png")

response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=["Add a birthday hat to this cat", image],
)

for part in response.parts:
    if part.text is not None:
        print(part.text)
    elif part.inline_data is not None:
        image = part.as_image()
        image.save("edited_image.png")
```

### 高品質画像生成（Gemini 3 Pro Image）

```python
response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents="A Da Vinci style anatomical sketch of a butterfly",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
        image_config=types.ImageConfig(
            aspect_ratio="1:1",   # "1:1","2:3","3:2","3:4","4:3","4:5","5:4","9:16","16:9","21:9"
            image_size="4K",      # "1K","2K","4K"
        ),
    ),
)

for part in response.parts:
    if part.text is not None:
        print(part.text)
    elif part.inline_data is not None:
        image = part.as_image()
        image.save("butterfly.png")
```

### Async 画像生成

```python
response = await client.aio.models.generate_content(
    model="gemini-2.5-flash-image",
    contents="Generate a landscape painting",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
        image_config=types.ImageConfig(
            aspect_ratio="16:9",
            image_size="2K",
        ),
    ),
)
```

---

## 7. 利用可能なモデル名

### 推奨モデル（最新）

| モデルID | 用途 |
|----------|------|
| `gemini-3-flash-preview` | 汎用テキスト & マルチモーダル |
| `gemini-3-pro-preview` | コーディング & 複雑な推論 |
| `gemini-3.1-pro-preview` | 最新の高度な推論 |
| `gemini-2.5-flash` | 推論タスクのコスパ最良 |
| `gemini-2.5-flash-lite` | 最速・最安 |
| `gemini-2.5-pro` | 最高性能の複雑タスク |
| `gemini-2.5-flash-image` | 高速画像生成 |
| `gemini-3-pro-image-preview` | 高品質画像生成 |

### 特殊モデル

| モデルID | 用途 |
|----------|------|
| `gemini-2.5-flash-native-audio-preview-12-2025` | リアルタイム音声/動画 |
| `gemini-2.5-flash-preview-tts` | テキスト音声合成 |
| `gemini-2.5-pro-preview-tts` | 高品質テキスト音声合成 |
| `gemini-embedding-001` | ベクトル埋め込み |
| `veo-3.0-generate-001` | 高忠実度ビデオ |
| `veo-3.1-generate-preview` | 映画品質ビデオ |

### 非推奨（使用禁止）

- `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-pro`
- `gemini-2.0-flash`, `gemini-2.0-flash-lite`（サンセット予定）

---

## 8. Thinking/Reasoning 設定

### Gemini 3 モデル向け

```python
config=types.GenerateContentConfig(
    thinking_config=types.ThinkingConfig(
        thinking_level=types.ThinkingLevel.HIGH
        # MINIMAL (Flash のみ), LOW, MEDIUM (Flash のみ), HIGH (デフォルト)
    ),
)
```

### Gemini 2.5 モデル向け

```python
config=types.GenerateContentConfig(
    thinking_config=types.ThinkingConfig(
        thinking_budget=0  # 0: 無効, 最小128 (Pro), 最小1 (Flash)
    ),
)
```

---

## 9. マルチモーダル入力

### PIL Image

```python
from PIL import Image

image = Image.open("photo.jpg")
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[image, "Describe this image."],
)
```

### バイナリデータ

```python
from google.genai import types

with open("audio.mp3", "rb") as f:
    audio_bytes = f.read()

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Part.from_bytes(data=audio_bytes, mime_type="audio/mp3"),
        "Transcribe this audio.",
    ],
)
```

### ファイルAPI（大容量ファイル）

```python
my_file = client.files.upload(file="video.mp4")
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[my_file, "Summarize this video."],
)
client.files.delete(name=my_file.name)
```

---

## 10. Function Calling

```python
from google.genai import types

def get_current_weather(city: str) -> str:
    """Returns weather for a city."""
    return f"Weather for {city}: Sunny, 25C"

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What is the weather in Tokyo?",
    config=types.GenerateContentConfig(
        tools=[get_current_weather],
    ),
)

if response.function_calls:
    for call in response.function_calls:
        print(f"Function: {call.name}, Args: {dict(call.args)}")
```

---

## 11. チャット（マルチターン）

```python
chat = client.chats.create(model="gemini-2.5-flash")
response1 = chat.send_message("Hello, who are you?")
response2 = chat.send_message("What did I just say?")

for message in chat.get_history():
    print(f"{message.role}: {message.parts[0].text}")
```

---

## プロジェクトへの統合に関する注意

### 現在の backend-py 依存関係との互換性
- Python 3.13 を使用中 -> google-genai は >= 3.10 なので互換性あり
- httpx を既に使用中 -> google-genai のデフォルト HTTP クライアントと同じ
- Pillow を既に使用中 -> 画像生成の出力処理に利用可能

### インストールコマンド (uv)

```bash
cd /Users/tknr/Development/gemini-hackathon-game/backend-py/app
uv add google-genai
```

---

## 参考リンク
- [PyPI - google-genai](https://pypi.org/project/google-genai/)
- [GitHub - googleapis/python-genai](https://github.com/googleapis/python-genai)
- [公式ドキュメント](https://googleapis.github.io/python-genai/)
- [Structured Output ガイド](https://ai.google.dev/gemini-api/docs/structured-output)
- [画像生成ガイド](https://ai.google.dev/gemini-api/docs/image-generation)
- [モデル一覧](https://ai.google.dev/gemini-api/docs/models)
- [Migration ガイド](https://ai.google.dev/gemini-api/docs/migrate)
- [Codegen Instructions](https://github.com/googleapis/python-genai/blob/main/codegen_instructions.md)
