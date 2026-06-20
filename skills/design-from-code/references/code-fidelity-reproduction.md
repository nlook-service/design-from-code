# 실제 컴포넌트를 충실히 재현하는 법 (Code-Fidelity Reproduction)

> 이 스킬의 심장. "현재 디자인에 맞게" 정확도는 **Playwright 캡처가 아니라 실제 소스코드를 읽어** 나온다.
> 목표: 시안 HTML이 실제 컴포넌트와 **아이콘·라벨·간격·색까지 같아 보이게** 만든다.

---

## 0. 왜 코드를 읽나 (Playwright 아님)

- 스크린샷은 "보이는 결과"만 준다. **클래스명·조건부 렌더·상태별 분기·정확한 라벨**은 코드에만 있다.
- 라이브 앱 캡처(Playwright)는 환경 의존(서버 기동·로그인·뷰포트)이라 자주 깨진다. 실제로 이번 작업도 Playwright는 전부 타임아웃으로 실패했고, **소스 정독만으로 픽셀 일치 시안**을 만들었다.
- 결론: **1순위 = 소스 정독.** Playwright 실제 캡처는 *검증/대조*용 보조(가능하면 좋고, 없어도 됨).

---

## 1. 절차 (5스텝)

### STEP 1 — 컴포넌트 파일 찾기
```bash
find apps/books/src -iname "*BrandStudio*"            # 후보 파일
grep -rln "하단바\|BottomBar\|StudioBar" apps/books/src
```

### STEP 2 — 렌더 함수/구조 골격 파악
컴포넌트는 보통 작은 `renderXxx` 헬퍼로 반복 UI를 그린다. 이걸 먼저 찾는다.
```bash
grep -n "renderSeg\|renderProfile\|leftSegs\|rightSegs\|ModuleCard\|return (" \
  apps/books/src/components/mobile/MobileBrandStudioBar.tsx | head
```
→ "peek는 `leftSegs.map(renderSeg)` + ＋FAB + `rightSegs.map(renderSeg)` 구조" 같은 골격을 얻는다.

### STEP 3 — 렌더 함수 본문 정독 (★핵심)
`sed`로 함수 본문을 그대로 읽어 **Tailwind 클래스·아이콘·라벨·조건부 스타일**을 추출한다.
```bash
sed -n '/const renderSeg/,/^  );$/p' \
  apps/books/src/components/mobile/MobileBrandStudioBar.tsx
```
실제로 얻은 것:
```tsx
const renderSeg = (s) => (
  <button className={cn(
    'flex flex-1 flex-col items-center gap-0.5 rounded-xl py-1.5 text-[10px]',
    s.active ? 'font-bold text-foreground' : 'font-medium text-muted-foreground'  // ← 활성=색 아닌 굵기
  )}>
    <s.icon className="h-5 w-5" strokeWidth={s.active ? 2.5 : 2} />               // ← 아이콘 크기/굵기
    <span className="truncate">{s.label}</span>
  </button>
);
```
→ **읽어낸 사실**: 세로(아이콘 위/라벨 아래), 아이콘 `h-5 w-5`, 텍스트 `text-[10px]`, **배경/색 없음·활성만 `font-bold text-foreground`**(모노톤), 둥근 `rounded-xl`.

### STEP 4 — 정확한 라벨·아이콘·기본값 확인
라벨이 i18n이면 locale에서 실제 문자열을, 슬롯 기본값이면 상수에서 확인.
```bash
grep -n "DEFAULT_PEEK_SLOTS\|EDITABLE_KEYS" .../MobileBrandStudioBar.tsx
sed -n '52,60p' apps/books/src/locales/ko/mobileStudio.json    # 실제 라벨
```
→ peek 기본 = `글·캘린더·＋·통계·프로필`, 모듈 제목 = "최근 글"·"이번 주", 푸터 = `ABOUT|PRIVACY|TERMS`.
**여기서 절대 라벨을 지어내지 않는다.** 실제 문자열만 쓴다.

### STEP 5 — HTML/CSS로 1:1 번역
Tailwind 클래스를 같은 의미의 CSS로 옮긴다. **클래스→CSS 매핑 치트시트**(아래 §2) 사용.
```html
<!-- renderSeg → HTML -->
<div class="seg on"><svg .../>글</div>
<style>
  .seg{flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;
       border-radius:12px;padding:5px 0;font-size:10px;font-weight:500;color:var(--muted-foreground)}
  .seg.on{font-weight:800;color:var(--foreground)}   /* 활성=색 아닌 굵기, 코드 그대로 */
  .seg svg{width:20px;height:20px;stroke:currentColor;fill:none;stroke-width:2}
</style>
```

---

## 2. Tailwind → CSS 매핑 치트시트

| Tailwind | CSS |
|---|---|
| `flex flex-col items-center` | `display:flex;flex-direction:column;align-items:center` |
| `gap-0.5` / `gap-2` | `gap:2px` / `gap:8px` (×4px) |
| `h-5 w-5` / `h-12 w-12` | `height/width:20px` / `48px` (×4px) |
| `text-[10px]` / `text-sm` / `text-xl` | `font-size:10px` / `14px` / `20px` |
| `font-medium/bold/extrabold` | `font-weight:500/700/800` |
| `rounded-xl` / `rounded-2xl` / `rounded-full` | `border-radius:12px / 16px / 50%` |
| `p-3` / `px-4 py-1.5` | `padding:12px` / `padding:6px 16px` |
| `bg-primary text-primary-foreground` | `background:var(--primary);color:#fff` |
| `text-foreground` / `text-muted-foreground` | `color:var(--foreground)` / `var(--muted-foreground)` |
| `border border-border` | `border:1px solid var(--border)` |
| `bg-muted/60` | `background:rgba(244,244,245,.6)` (테마 muted + alpha) |
| `tabular-nums` | `font-variant-numeric:tabular-nums` |
| `shadow-md` | `box-shadow:0 4px 10px rgba(0,0,0,.15)` |

> 디자인 토큰(`--foreground`, `--primary` 등)은 프로젝트 테마 CSS에서 실제 값을 확인해 `:root`에 근사치로 넣는다. 모노톤 프로젝트면 모노톤으로.

---

## 3. 아이콘 처리

- 실제 컴포넌트는 보통 아이콘 라이브러리(lucide 등) 사용. 시안에선 **간단한 인라인 SVG**로 같은 실루엣만 흉내내면 충분.
- 핵심은 **크기·굵기·모노톤 여부**를 코드에서 읽은 대로 맞추는 것(`h-5 w-5` → `width:20px`, `strokeWidth=2`).
```html
<svg viewBox="0 0 24 24" style="width:20px;height:20px;stroke:currentColor;fill:none;stroke-width:2">
  <path d="M4 20h16M6 16l9-9 3 3-9 9H6z"/>  <!-- 펜(글) 아이콘 근사 -->
</svg>
```

---

## 4. AS-IS / TO-BE 2열 구성

- **AS-IS** = STEP 1~5로 재현한 *현재 그대로*.
- **TO-BE** = AS-IS를 복제한 뒤 **바뀌는 부분만** 교체. 나머지는 손대지 않음을 코드로 증명.
- 각 블록에 색 태그: 🟦 유지(`outline` 없음) / 🟩 신규(`outline:2px solid #86efac`) / 🟨 변경(`outline:2px solid #fcd34d`).
- **배치 제약**은 별도 다이어그램 박스(위→아래 스택)로도 그려 합의. (예: "메뉴는 시트 최상단 고정, 신규는 그 아래" — 이번 작업에서 사용자가 이 위/아래를 정정함)

---

## 5. 흔한 실수

- ❌ 라벨을 지어냄("대시보드", "내 정보") → ✅ 실제 i18n 문자열만.
- ❌ 활성 상태를 색(파랑)으로 칠함 → ✅ 코드가 `font-bold text-foreground`면 **굵기/명도**로(모노톤 보존).
- ❌ ＋버튼을 둥근 사각형으로 → ✅ 코드가 `rounded-full`이면 **원형**.
- ❌ 모듈 순서를 임의로 → ✅ JSX에 나온 순서 그대로(최근 글 → 이번 주 → 지표 → 푸터).
- ❌ 조건부 UI(음악 플레이어 행 등) 누락 → ✅ `musicActive &&` 같은 분기도 시안에 주석으로라도 표시.

---

## 6. (선택) Playwright 실제 캡처로 대조

소스 정독으로 만든 시안을 **실제 앱 스크린샷과 겹쳐 검증**하면 가장 확실하다. 단 환경 의존이 크다.
```bash
# dev 서버 기동 후, 모바일 뷰포트로 실제 컴포넌트 캡처 → 시안과 픽셀 대조
```
- 이번 작업에선 Playwright가 `file://` 차단·frame detached·timeout으로 전부 실패 → **소스 정독만으로 충분**했다.
- 즉 Playwright는 **있으면 보조, 없으면 생략**. 1순위는 항상 소스 정독.
