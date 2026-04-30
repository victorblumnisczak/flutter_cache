# Flutter Problemático - Catálogo com Latência e Sem Cache

Projeto didático propositalmente ruim para identificação e correção de problemas de:

- latência percebida
- baixa responsividade
- ausência de cache de dados
- ausência de cache explícito de imagens
- acoplamento entre UI e infraestrutura
- recarregamento desnecessário

## API usada

Este projeto consome a API pública DummyJSON:
- `GET https://dummyjson.com/products?limit=30`

## Dependências

```yaml
http: ^1.2.1
shared_preferences: ^2.3.0   # cache persistente em disco
cached_network_image: ^3.4.0 # cache de imagens
```

## Como executar

```bash
flutter pub get
flutter run
```

## Documentação da refatoração

A análise completa dos problemas encontrados, as mudanças realizadas e a justificativa técnica de cada decisão estão em **[ANALISE.md](ANALISE.md)**.

O `ANALISE.md` cobre:
1. Problemas identificados no projeto original (11 problemas mapeados)
2. Mudanças realizadas (com localização e justificativa)
3. Estratégia de cache adotada (Stale-While-Revalidate)
4. Modelagem de estados explícitos (6 estados)
5. Tabela comparativa Antes vs. Depois
6. Trade-offs e limitações reconhecidos
7. Integrantes do Grupo 2

---

# Atividade Prática: Análise e Evolução de Aplicação Flutter

Esta atividade propõe a análise de um projeto Flutter construído propositalmente com limitações arquiteturais e problemas de comportamento relacionados a **latência**, **responsividade** e **ausência de estratégias adequadas de cache**.

A proposta consiste em examinar o sistema, identificar os problemas existentes e desenvolver uma versão estruturalmente mais adequada, justificando tecnicamente as decisões adotadas ao longo da evolução da aplicação.

## Acesso ao Projeto

O projeto-base da atividade está disponível neste repositório.

A partir dele, deve-se observar o comportamento da aplicação, analisar suas limitações e realizar as modificações consideradas necessárias.

## Objetivo da Atividade

O foco da atividade está em compreender que a qualidade de uma aplicação não depende apenas de seu funcionamento correto, mas também de sua organização interna e de sua forma de responder às interações do usuário.

Assim, a proposta não se limita a fazer o sistema "funcionar", mas a examinar **como ele se comporta**, quais decisões prejudicam sua qualidade e quais mudanças podem torná-lo mais adequado do ponto de vista arquitetural e da experiência de uso.

## Proposta de Trabalho

Ao realizar esta atividade, espera-se que sejam desenvolvidas as seguintes ações:

1. Executar o projeto original e observar seu comportamento em uso.
2. Identificar os problemas arquiteturais e funcionais presentes na aplicação.
3. Registrar quais limitações afetam latência, responsividade, organização do código e experiência do usuário.
4. Evoluir o projeto para uma versão mais adequada.
5. Descrever com clareza as mudanças realizadas.
6. Justificar tecnicamente por que essas mudanças melhoram o sistema.
7. Apresentar o resultado final de forma organizada.

## Resultado Esperado

Como resultado, espera-se uma versão modificada da aplicação acompanhada de uma análise objetiva dos problemas encontrados, de uma descrição das mudanças implementadas e de uma justificativa técnica que relacione cada alteração aos problemas identificados no projeto original.

## Critério Central de Análise

A análise da atividade deve considerar principalmente a capacidade de:

* compreender os problemas existentes no projeto original;
* reconhecer impactos arquiteturais e de experiência do usuário;
* propor e implementar melhorias coerentes;
* explicar tecnicamente as mudanças realizadas.

> Esta atividade não se limita à implementação de código. Seu propósito é desenvolver análise, diagnóstico, evolução arquitetural e argumentação técnica sobre decisões de projeto em aplicações interativas.
