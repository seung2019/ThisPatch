# Schema Registry 필드 정의

> TODO: Phase 1 아키텍처 확정 (작업 1-2, 1-3) 후 채우기

## 필드 구조

```go
type FieldDef struct {
    Name     string   // "proc.name", "fd.rip"
    Type     FieldType
    Semantic Sem      // SemanticType — 상관분석 dispatch용
    Path     string   // 직접 접근: "Info.Pid"
    Resolver func(*Event, []string) (Value, bool)  // cross-event: proc.aname[N]
}
```

## SemanticType 목록

> TODO: ~50개 정의 예정

| Sem | 의미 |
|-----|------|
| SemPID | 프로세스 ID |
| SemProcName | 프로세스 이름 |
| SemFilePath | 파일 경로 |
| SemIPv4 | IPv4 주소 |
| SemPort | 포트 번호 |
| SemPackageName | npm/pypi 패키지명 |
| SemPublisherAge | 패키지 게시자 나이(일) |
| SemContainerID | 컨테이너 ID |
| SemK8sPodName | K8s Pod 이름 |
| ... | ... |

## 필드 목록

> TODO: proc.*, fd.*, container.*, supply_chain.* ~50개 정의 예정
