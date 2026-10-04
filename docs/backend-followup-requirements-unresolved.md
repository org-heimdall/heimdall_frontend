# 백엔드 미해결 후속 요구사항

기존 [`backend-followup-requirements.md`](./backend-followup-requirements.md)는 이미 정리된
호환성·운영 보강 항목을 보존한다. 이 문서는 현재 새 백엔드에서 아직 해결되지 않았거나
추가 확인이 필요한 항목만 별도로 관리한다.

## 1. AI 판정·FactCheck 결과 품질

### 1.1 FactCheck target 중복 제거

현재 Analyzer 프롬프트에는 검증 가능한 사실 주장 우선, 예측·규범·질문 제외,
턴당 FactCheck 상한 규칙이 이미 반영되어 있다. 남은 문제는 서로 다른 턴이나 재시도에서
의미상 같은 주장이 중복 target으로 저장될 수 있다는 점이다.

- 같은 내용의 target은 문장 정규화·claim hash·component 참조로 한 번만 만든다.

## 2. 재현가능성·비용 측정

현재 백엔드는 호출별 모델명, token usage, cached token, 응답 시간, 재시도·실패 로그를
남기고 있다. 이 로그 자체는 해결된 항목이므로 추가 구현 요구사항으로 보지 않는다.

남은 작업은 동일 시나리오를 여러 번 실행해 다음 결과가 허용 오차 안에서 재현되는지
측정하고 기록하는 것이다.

- 승자와 패자 일치
- 양측 점수의 오차 범위
- FactCheck target 집합 유사도
- 동일 target의 verdict 일치율
- Judge가 제시하는 강점·약점의 핵심 항목 일치

모델·프롬프트·입력·추론 설정을 고정하고 결과가 다르면 prompt, target 선정 규칙, mapper를
조정해 반복한다. 실제 비용은 로그의 token usage와 실행 시점 모델 가격표로 계산해
Analyzer·FactCheck·Judge별 평균 비용과 장애 빈도를 별도로 기록한다.

## 3. 토론 단계별 발언 시간

| 단계 | 발언자 1명당 제한 시간 |
|---|---:|
| 입론(`OPENING`) | 90초(1분 30초) |
| 반론 및 질문(`REBUTTAL_QUESTION`) | 180초(3분) |
| 최종 발언(`CLOSING`) | 90초(1분 30초) |

단계별 제한은 현재 턴 응답, 만료 판정, 다음 턴 전환, 전체 `expiresAt`, timeout scheduler,
재접속 타이머에 동일하게 적용한다. 전역 180초 하나로 모든 단계를 처리하지 않는다.

## 4. 커뮤니티 입장 시 토론 의사와 방장 시작 권한

- 신규 참여자의 기본 `debateIntent`는 `OPEN_TO_DEBATE`(“토론할래요”)다.
- 사용자가 `PREPARING`(“준비할래요”)을 선택하면 재입장 후에도 유지한다.
- 방장은 `PREPARING`이어도 명시적으로 `토론하기`를 누르면 초대를 생성할 수 있다.

## 5. 점수 근거와 개선 피드백 분리

점수 카드 하단 설명은 총점이 산출된 근거에 대한 내용이다. 현재는 참가자별 개선 피드백을 재사용하고 있다. 판정 결과에 별도의 점수 근거 필드를 추가한다.

```json
{
  "sideATotalScore": 71,
  "sideBTotalScore": 63,
  "sideAScoreReason": "주장의 연결성과 근거 제시를 기준으로 산출한 점수입니다.",
  "sideBScoreReason": "반론의 명확성과 사실 근거를 기준으로 산출한 점수입니다.",
  "sideAFeedback": "주요 통계의 출처와 적용 범위를 더 구체적으로 제시해 주세요.",
  "sideBFeedback": "상대의 핵심 질문에 먼저 답한 뒤 추가 반론을 제시해 주세요."
}
```

- `side*ScoreReason`는 총점·세부 점수의 산출 이유를 설명한다.
- `side*Feedback`은 강점과 다음 토론의 개선점을 설명한다.
- 두 필드는 서로 다른 문장으로 생성하고, 실제 transcript·논증 관계·FactCheck·점수에 근거한다.
- 프론트 점수 카드에는 `side*ScoreReason`, 개선 피드백 카드에는 `side*Feedback`을 매핑한다.
