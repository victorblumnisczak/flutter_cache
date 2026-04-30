# ANALISE.md — Cache, Latência e Responsividade

**Disciplina:** Desenvolvimento para Dispositivos Móveis II  
**Professor:** Jefferson Rodrigo Speck  
**Grupo 2:** Victor, Davi, Jordan, João Vitor, Ruan

---

## Seção 1 — Problemas identificados no projeto original

O arquivo `lib/main.dart` original concentrava toda a lógica em um único arquivo de 305 linhas e exibia 11 problemas intencionais, documentados abaixo com localização e impacto.

| # | Localização (main.dart) | Problema | Impacto observável |
|---|------------------------|----------|--------------------|
| 1 | Linhas 80–120 (`loadProducts`) | UI acessa a API diretamente via `http.get` dentro do widget | Acoplamento total entre camada visual e infraestrutura; impossível testar, reutilizar ou trocar a fonte de dados |
| 2 | Linha 93 | `Future.delayed(2s)` na UI | Toda interação do usuário espera 2s sem justificativa arquitetural — custo de rede simulado misturado com lógica de apresentação |
| 3 | Sem `ProductMemoryCache` | Toda navegação refaz a chamada remota | Latência de 2s+ a cada carregamento, mesmo quando os dados não mudaram |
| 4 | Sem `ProductLocalCache` | Fechar e reabrir o app perde todos os dados | Primeira abertura sempre mostra tela de loading |
| 5 | Linhas 190–205 (`Image.network`) | Imagens sem cache explícito, sem placeholder | Imagens piscam a cada scroll, são baixadas repetidamente, experiência visual degradada |
| 6 | Linhas 122–134 (`openDetails`) | `await loadProducts()` após retornar da tela de detalhes | Cada visita a um produto dispara uma nova requisição completa de 2s ao voltar |
| 7 | Linhas 150–155 (build) | `if (isLoading) return CircularProgressIndicator()` | Loading bloqueia e apaga a lista inteira, mesmo quando havia conteúdo carregado anteriormente |
| 8 | Linhas 70–72 | Estados via `bool isLoading`, `String? errorMessage`, `List<Product> products` | Combinações ambíguas (ex: `isLoading=false, products=[], errorMessage=null` é idle ou empty?) |
| 9 | Linhas 158–177 | Não distingue lista vazia de "ainda carregando" | Usuário não sabe se não há produtos ou se ainda estão carregando |
| 10 | Todo o arquivo | Sem `abstract class` para repositório | Não há contrato testável; mock impossível; troca de fonte requer reescrita da UI |
| 11 | Linhas 81–84, 107–110, 115–118 | Três chamadas `setState` em sequência no mesmo fluxo | Potencial para renders desnecessários e estados intermediários inconsistentes |

---

## Seção 2 — Mudanças realizadas

### 2.1 Extração do modelo `Product`
- **O que foi feito:** Moveu a classe `Product` de `main.dart` para `lib/models/product.dart` e adicionou os métodos `toMap()`, `toJson()` e `factory fromJson()`.
- **Onde:** `lib/models/product.dart`
- **Por quê:** Conformidade com a separação de responsabilidades. O modelo de domínio não deve depender de nenhuma camada de infraestrutura ou UI. A adição de `toMap()`/`toJson()` é requisito para serialização no cache local (Seção 2.1 da apostila sobre persistência).

### 2.2 Isolamento do acesso à rede em `ProductApi`
- **O que foi feito:** Criou `ProductApi` com o método `fetchProducts()`, movendo o `http.get` e o delay artificial para fora da UI.
- **Onde:** `lib/data/product_api.dart`
- **Por quê:** A apostila (Seção 1.1) enfatiza que a UI nunca deve conhecer detalhes de transporte. O delay foi mantido intencionalmente para que o ganho do cache fique evidente na demonstração — agora ele representa o custo real de rede, não um custo de UI.

### 2.3 Cache em memória com TTL
- **O que foi feito:** Implementou `ProductMemoryCache` com `getIfValid()` (respeita TTL), `save()` e `rawProducts` (acesso ao dado obsoleto para SWR).
- **Onde:** `lib/data/product_memory_cache.dart`
- **Por quê:** Conforme Seção 1.3 da apostila, cache em RAM é a camada mais rápida — acesso imediato, sem I/O. O TTL de 5 minutos foi escolhido como equilíbrio entre freshness e economia de rede para um catálogo de produtos que não muda a cada minuto.

### 2.4 Cache persistente via SharedPreferences
- **O que foi feito:** Implementou `ProductLocalCache` serializando a lista como `List<String>` JSON e o timestamp como ISO 8601.
- **Onde:** `lib/data/product_local_cache.dart`
- **Por quê:** Seção 1.4 da apostila descreve cache persistente como requisito para que o app funcione offline e reduza a latência percebida na reabertura. SharedPreferences é adequado para listas pequenas (30 produtos).

### 2.5 Repositório com contrato abstrato
- **O que foi feito:** Criou `ProductRepository` (abstract class) com `Stream<ProductFetchResult> getProducts()` e `ProductRepositoryImpl` com a implementação Stale-While-Revalidate.
- **Onde:** `lib/repository/`
- **Por quê:** O contrato abstrato permite trocar a implementação (mock, teste, outra API) sem alterar a UI. Conforme Seção 1.6 da apostila, o padrão Repository é o ponto natural de orquestração das camadas de cache.

### 2.6 Modelagem de estados explícitos
- **O que foi feito:** Criou `ProductListStatus` (enum com 6 estados) e `ProductListState` (classe imutável com `copyWith`).
- **Onde:** `lib/state/product_list_state.dart`
- **Por quê:** Conforme Tabela 1 da Seção 1.3 da apostila, estados implícitos via booleanos criam combinações impossíveis de rastrear. Estados explícitos eliminam ambiguidade e permitem que a UI reaja de forma precisa.

### 2.7 Controller com ChangeNotifier
- **O que foi feito:** `ProductListController` consome o Stream do repositório via `await for` e emite estados atômicos.
- **Onde:** `lib/controllers/product_list_controller.dart`
- **Por quê:** Separa lógica de negócio da UI. Um único `_emit()` garante que não haja estados intermediários inconsistentes (resolve o problema #11).

### 2.8 Refatoração da `ProductListPage`
- **O que foi feito:** A page agora usa `ListenableBuilder`, `RefreshIndicator`, `CachedNetworkImage` e um `_SourceIndicator` visual que mostra de onde vêm os dados (memória/disco/rede).
- **Onde:** `lib/pages/product_list_page.dart`
- **Por quê:** A UI deve ser puramente reativa ao estado. O indicador de fonte torna a estratégia de cache visível ao avaliador.

### 2.9 Refatoração de `ProductDetailPage`
- **O que foi feito:** Substituiu `Image.network` por `CachedNetworkImage` com placeholder e errorWidget. Removeu a "Observação didática" de recarga.
- **Onde:** `lib/pages/product_detail_page.dart`
- **Por quê:** Imagens em `PageView` piscavam a cada deslize. `CachedNetworkImage` mantém as imagens em disco após o primeiro download.

### 2.10 Reescrita do `main.dart`
- **O que foi feito:** Reduzido a wiring: instancia as dependências, compõe o grafo de objetos e chama `runApp`.
- **Onde:** `lib/main.dart`
- **Por quê:** `main.dart` deve ser o ponto de composição, não de lógica. Conforme Seção 1.7 da apostila, a injeção manual de dependências (sem container) é suficiente para projetos de escopo limitado.

---

## Seção 3 — Estratégia de cache adotada

### Por que Stale-While-Revalidate?

A apostila (Seção 1.6) descreve três estratégias principais:

| Estratégia | Comportamento | Problema para este cenário |
|------------|--------------|---------------------------|
| **Cache-First** | Serve sempre o cache; só vai à rede se cache expirou | Dados podem ficar obsoletos por muito tempo sem que o usuário perceba |
| **Network-First** | Sempre tenta a rede primeiro; cache só em falha | A latência artificial de 2s é sentida em toda navegação — não aproveita o cache |
| **Stale-While-Revalidate (SWR)** | Serve o cache imediatamente + atualiza em background | Usuário vê conteúdo instantaneamente; dado fresco chega sem bloquear |

**Escolha: SWR.** Para catálogos de produtos (feeds que mudam com pouca frequência), exibir dados ligeiramente obsoletos por alguns segundos é aceitável. O ganho em responsividade percebida é alto: o usuário vê a lista imediatamente, e a atualização silenciosa garante que o dado fique fresco sem exigir interação.

### Fluxo da implementação

```
getProducts()
│
├── Cache em memória válido (TTL ok)?
│   ├── SIM → emite (source: memory) → revalida em background → emite (source: remote)
│   └── NÃO ↓
│
├── Cache local (disco) tem dados?
│   ├── SIM → emite (source: local) + popula memória
│   └── NÃO ↓ (sem emissão intermediária)
│
└── Busca remota
    ├── OK → atualiza memória + disco → emite (source: remote, isFresh: true)
    └── ERRO + havia cache → silencioso (controller mantém dados existentes)
          ERRO + sem cache → propaga exceção → status: error
```

### TTL de 5 minutos

Escolhido como padrão conservador para um catálogo de produtos públicos (DummyJSON). Em produção, o TTL seria calibrado com base na frequência de atualização do backend. Valores menores (ex: 1 min) aumentam freshness mas penalizam bateria e dados móveis.

### Invalidação

- **Automática:** TTL expira em 5 min → próxima chamada ignora memória e vai ao disco/rede.
- **Manual:** `forceRefresh: true` (pull-to-refresh ou botão) pula o cache de memória mas ainda usa disco como conteúdo intermediário, evitando tela em branco.

### Cache de imagens

`CachedNetworkImage` gerencia um cache em disco gerenciado pelo `flutter_cache_manager`. Cada URL de imagem é baixada uma única vez e servida do disco nas chamadas subsequentes. Isso complementa o cache de dados: mesmo que a lista seja recarregada da rede, as imagens não são baixadas novamente.

---

## Seção 4 — Modelagem de estados explícitos

Conforme Tabela 1 da Seção 1.3 da apostila, estados de tela devem ser modelados de forma exaustiva para eliminar combinações ambíguas.

| Estado | Condição de entrada | Comportamento na UI |
|--------|--------------------|--------------------|
| `idle` | Estado inicial antes de qualquer carga | Tela vazia (transitório, raramente visível) |
| `loading` | Primeira carga sem dados em cache | Spinner centralizado, sem conteúdo anterior |
| `success` | Dados carregados (cache ou rede) | Lista visível, indicador de fonte no AppBar |
| `error` | Falha na rede sem nenhum dado disponível | Mensagem de erro + botão "Tentar novamente" |
| `empty` | Sucesso, mas API retornou lista vazia | Mensagem "Nenhum produto encontrado" |
| `refreshing` | Atualização em background com dados já exibidos | Lista visível + `LinearProgressIndicator` no topo |

A transição `loading → success` nunca exibe conteúdo obsoleto. A transição `refreshing → success` preserva a lista e apenas atualiza os dados — o usuário não percebe interrupção.

O estado `error` só ocorre quando **não há dados de cache disponíveis**. Se houver cache, a falha de rede resulta em `success` com uma mensagem discreta (banner amarelo), não em substituição da lista por uma tela de erro.

---

## Seção 5 — Antes vs. Depois

| Aspecto | Original | Refatorado | Ganho técnico |
|---------|----------|------------|---------------|
| **Acoplamento UI/API** | `http.get` dentro do widget | `ProductApi` isolado; UI só conhece `ProductRepository` | Testabilidade; troca de fonte sem alterar UI |
| **Cache em memória** | Inexistente | `ProductMemoryCache` com TTL de 5 min | Lista aparece instantaneamente em navegações subsequentes |
| **Cache persistente** | Inexistente | `ProductLocalCache` via SharedPreferences | Reabertura do app exibe dados do disco antes da rede |
| **Cache de imagens** | `Image.network` sem cache | `CachedNetworkImage` com placeholder e errorWidget | Sem piscar no scroll; download único por imagem |
| **Recarga ao voltar de detalhes** | Sempre (`await loadProducts()`) | Nunca (cache em memória serve a lista) | Elimina 2s+ de espera desnecessária |
| **Loading bloqueante** | Substitui a lista inteira | `LinearProgressIndicator` no topo durante refresh | Lista permanece visível durante atualizações |
| **Modelagem de estados** | 3 booleanos soltos | Enum com 6 estados + classe imutável | Sem combinações ambíguas; UI sempre determinística |
| **Recuperabilidade offline** | Sem cache → tela de erro | Cache local → lista do disco + mensagem discreta | App funcional sem internet se já foi aberto antes |

---

## Seção 6 — Trade-offs e limitações

### SharedPreferences para cache local
SharedPreferences serializa tudo como strings em um arquivo XML/plist. É adequado para 30 produtos, mas não escala para listas grandes (centenas de itens com campos ricos). Em produção, usaríamos **Hive**, **Isar** ou **Drift** — bancos de dados locais com suporte a queries, índices e migrações de schema.

### TTL fixo
O TTL de 5 minutos é simples e previsível, mas não é event-driven. Se o backend atualizar um produto durante o TTL, o cliente só verá a mudança quando o TTL expirar ou o usuário fizer pull-to-refresh. Em produção, complementaríamos com WebSockets ou push notifications para invalidação proativa.

### Ausência de paginação
A API é chamada com `?limit=30`, retornando todos os produtos de uma vez. Catálogos reais têm milhares de itens e exigem paginação (scroll infinito ou paginação explícita). Isso está fora do escopo desta atividade, mas seria a próxima evolução natural.

### Injeção manual de dependências
O wiring em `main.dart` é feito manualmente. Para projetos maiores, um container de DI (como `get_it`) facilitaria o gerenciamento do ciclo de vida e tornaria o grafo de dependências mais explícito. Para o escopo desta atividade, a injeção manual é suficiente e mais didática.

### Sem testes automatizados
Conforme as restrições da atividade, não foram adicionados testes. O design com `abstract class ProductRepository` permite mockar facilmente a camada de dados em testes futuros — o repositório pode ser substituído por um `FakeProductRepository` que retorna dados estáticos.

---

## Seção 7 — Integrantes do grupo

**Grupo 2:**
- Victor
- Davi
- Jordan
- João Vitor
- Ruan
