# 자가완결 HTML 시안 작성 레시피 (HTML Mockup Recipe)

> 외부 의존 0, 인라인 CSS/SVG만. 브라우저로 열기만 하면 보이게. `Write`로 만들어 `SendUserFile`로 전달.

---

## 1. 뼈대 (복붙 시작점)

```html
<!doctype html>
<html lang="ko"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>이슈 #NNN · 시안</title>
<style>
  :root{
    /* 프로젝트 테마 토큰 근사 — 실제 themes.css 값 확인해서 채울 것 */
    --background:#fff; --card:#fff; --muted:#f4f4f5;
    --foreground:#0a0a0b; --muted-foreground:#71717a; --border:#e9e9ec;
    --primary:#2563eb;   /* 1차 액션에만 */
  }
  *{box-sizing:border-box}
  body{margin:0;background:#ececed;color:var(--foreground);
    font-family:-apple-system,BlinkMacSystemFont,"Pretendard","Segoe UI",Roboto,sans-serif}
  .num{font-variant-numeric:tabular-nums;letter-spacing:-.02em}  /* 숫자는 항상 */
</style></head>
<body><!-- 콘텐츠 --></body></html>
```

---

## 2. 폰 프레임 (모바일 시안)

```css
.phone{width:300px;aspect-ratio:300/640;background:var(--background);
  border-radius:40px;border:1px solid var(--border);overflow:hidden;position:relative;
  display:flex;flex-direction:column;box-shadow:0 10px 30px rgba(0,0,0,.07)}
.statusbar{height:30px;display:flex;justify-content:space-between;align-items:center;
  padding:0 18px;font-size:11px;font-weight:700}
.sheet{position:absolute;left:0;right:0;bottom:0;background:var(--card);
  border-radius:24px 24px 0 0;border-top:1px solid var(--border);
  box-shadow:0 -8px 30px -12px rgba(0,0,0,.18);padding:0 16px}     /* 떠 있는 레이어 */
.grip{height:6px;width:48px;border-radius:999px;background:rgba(113,113,122,.4);margin:8px auto}
```
- 접힘/펼침 등 **상태별로 폰을 여러 개** 나란히.
- 배경 본문을 흐린 placeholder(`opacity:.4` 회색 블록)로 깔면 "시트가 떠 있는" 느낌이 산다.

---

## 3. 인라인 SVG 차트 (차트 라이브러리 금지)

**스파크라인(선)**:
```html
<svg viewBox="0 0 120 32" preserveAspectRatio="none" style="width:120px;height:32px">
  <polyline points="0,28 24,24 48,16 72,18 96,9 120,4"
    fill="none" stroke="#0a0a0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="120" cy="4" r="2.6" fill="#0a0a0b"/>
</svg>
```
**영역(area, gradient fill)**:
```html
<svg viewBox="0 0 240 56" preserveAspectRatio="none">
  <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#0a0a0b" stop-opacity=".14"/>
    <stop offset="1" stop-color="#0a0a0b" stop-opacity="0"/></linearGradient></defs>
  <path d="M0,42 L40,37 L120,23 L240,7 L240,56 L0,56 Z" fill="url(#g)"/>
  <polyline points="0,42 40,37 120,23 240,7" fill="none" stroke="#0a0a0b" stroke-width="2"/>
</svg>
```
**막대(bar)**: `flex` + 높이 %로. 오늘만 `background:var(--foreground)`로 강조.

> 실제 구현에서도 차트 라이브러리 대신 인라인 SVG 컴포넌트(예: `Sparkline.tsx`)를 쓰는 경우가 많으니, 시안의 SVG가 그대로 구현 힌트가 된다.

---

## 4. 큰 숫자 + 변화율 (모노톤 강조)

```html
<div class="c" style="text-align:center">
  <div class="num" style="font-size:30px;font-weight:850;line-height:1">1,284</div>
  <div style="font-size:10.5px;color:var(--muted-foreground);font-weight:700">방문자</div>
  <div class="num" style="font-size:10px;font-weight:800;color:var(--foreground)">▲24%</div>
</div>
```
- 강조 = **크기·굵기**(색 아님). 파랑은 1차 액션 버튼에만.
- 변화율 = `▲`/`▼` 기호. 상승 진하게(`text-foreground`), 하락 흐리게(`muted`). (또는 사용자가 원하면 초록/빨강 약하게)

---

## 5. 여러 안(A/B) 비교 + 빈 상태

- 한 페이지에 **레이아웃 2~3안**을 좌우로. 각 안 아래 근거 2줄.
- **빈/초기 상태**를 별도 폰으로 같이(데이터 0인 신규 사용자). "첫 ~를 기다려요 · 공유" 같은 행동 유도 CTA.

---

## 6. 유지/신규/변경 색태그 (AS-IS/TO-BE)

```css
.hl-new{outline:2px solid #86efac;outline-offset:3px;border-radius:14px}  /* 신규 */
.hl-chg{outline:2px solid #fcd34d;outline-offset:3px;border-radius:14px}  /* 변경 */
/* 유지: outline 없음 */
```
범례를 페이지 상단에 칩으로 표시.

---

## 7. 미리보기 (선택) & 전달

- 가능하면 로컬 서버로 스샷:
  ```bash
  cd {폴더} && (python3 -m http.server 8777 &)   # http://localhost:8777/파일.html
  ```
  단 브라우저 자동화가 `file://` 차단·타임아웃 잦음 → **안 되면 그냥 파일 전달**.
- **전달**: `SendUserFile`로 `.html` 파일을 보낸다(사용자가 브라우저로 직접 연다).

---

## 8. 버전 관리

- 파일명에 버전: `mobile-bottom-...-v2.html`, `-v3.html` …
- 피드백마다 새 버전. 큰 방향 전환(레이아웃 정정 등)일수록 이전 버전 남겨 비교.
