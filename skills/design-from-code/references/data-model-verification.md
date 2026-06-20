# 데이터 모델 끝까지 검증하는 법 (Data-Model Verification)

> "이 숫자가 정확히 무엇을 세는가?"를 **코드로** 확정한다. 추측으로 설계하면 100% 틀린다.
> 화면에 통계/숫자를 노출하는 설계라면, 시안을 그리기 *전에* 이 단계를 끝낸다.

---

## 1. 추적 경로 (백엔드 기준)

```
라우터 등록  →  핸들러(인증·스코프 도출)  →  유즈케이스(필터)  →  리포지토리(WHERE 절)  →  스키마(컬럼·귀속)
```

각 단계에서 읽을 것:
- **라우터**: 엔드포인트 경로·메서드·인증 미들웨어.
- **핸들러**: 누구로 스코프하나? (userID? 토큰?) 어떤 파라미터(days, doc)?
- **유즈케이스**: 무엇으로 필터하나? userID→username 변환 등.
- **리포지토리**: 실제 SQL `WHERE` 절. **무엇을 포함/제외**하나.
- **스키마**: 그 통계가 *누구 콘텐츠*에 귀속되나? (author_id? username? doc_uuid?)

---

## 2. 실전 명령

```bash
# 엔드포인트 등록 위치
grep -rn "analytics/summary\|/analytics" server/internal --include="*.go" | grep -iE "Get|Post|route"

# 핸들러 정독 (인증·스코프)
sed -n '1,60p' server/internal/analytics/handler/summary_handler.go

# 유즈케이스 (필터 도출)
sed -n '1,60p' server/internal/analytics/usecase/summary.go

# 리포지토리 WHERE 절 (핵심)
grep -nE "WHERE|Username|device_type|is_self|COUNT|GROUP BY" \
  server/internal/analytics/repository/analytics_query_repository.go

# 스키마 (귀속 컬럼)
sed -n '1,80p' server/entgo/schema/analytics_event.go
```

병렬 조사가 필요하면 `Agent(subagent_type: Explore)`에게 "끝까지 추적하라" 프롬프트(→ `prompt-templates.md`)로 위임.

---

## 3. 반드시 한 줄로 확정할 질문

| 질문 | 이번 사례 답(예) |
|------|------------------|
| 누구 기준 스코프? | `WHERE username=$1` — 소유자 핸들 (author_id 없음, username 문자열 귀속) |
| 무엇을 포함/제외? | `device_type<>'bot'` (봇 제외) + `is_self=false` (본인 제외) |
| 무슨 범위를 합치나? | `doc` 없으면 **홈(/@user) + 모든 글(/@user/post) 합산** |
| 시계열/변화율 데이터 있나? | `daily[]`(일별 visitors) 있음 → days=14로 받아 최근7/이전7 분할 |
| 고유 vs 연인원? | `unique_visitors = COUNT(DISTINCT visitor_id)` |

→ **확정 산출물(한 줄)**: "방문자 = 내 공개표면 전체 고유 방문자, 봇·본인 제외, 홈+모든 글 합산."

---

## 4. "데이터가 없어 보임" 진단

숫자가 0으로 보일 때, **추적 누락인지 실제 데이터 없음인지** 구분:
- 비콘 발화 조건 확인(동의 게이트 `isAnalyticsAllowed()` 등) — 미동의면 미수집.
- 엔드포인트가 커밋/배포됐는지(`git log -- <파일>`).
- 실제로 유입이 없는지(신규 사용자) — 이 경우 **빈 상태 디자인**으로 해결(추적 문제 아님).

---

## 5. 시계열·변화율을 "없는 데이터로 지어내지 마라"

- 어떤 지표는 일별 시계열이 있고(방문자 `daily[]`), 어떤 건 없다(좋아요).
- 시계열이 없는 지표는 **그래프 탭을 비활성**하거나 "합계+변화"만 노출한다. **가짜 평탄 그래프 금지**(정직성).
- 변화율 = 이번 기간 합 vs 직전 동일기간 합. 데이터가 한쪽뿐이면 변화율 생략.

---

## 6. 신규 데이터가 필요하면 → 계약부터 정의

지표 하나가 기존 API에 없으면(예: 좋아요 합계), **엔드포인트 계약(JSON)부터 확정**하고 구현을 위임한다.
```
GET /api/analytics/likes-summary?days=N  (소유자 인증)
→ { "total": 342, "current": 57, "previous": 41 }
  total=전 기간, current=최근 N일, previous=그 앞 N일(변화율용)
```
계약이 있으면 프론트/백엔드를 병렬로 진행할 수 있다.
