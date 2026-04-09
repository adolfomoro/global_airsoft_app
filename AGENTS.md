# GLOBAL AIRSOFT APP - REGRAS OBRIGATORIAS

## Escopo
Este projeto e um aplicativo de producao de alto nivel.

Toda implementacao deve priorizar:
- Confiabilidade
- Seguranca
- Previsibilidade
- Performance

## Regras Inegociaveis

### 1. Qualidade de Producao
- Nao implementar nada "provisorio" em codigo final.
- Cada linha deve ser revisada pensando em falhas reais de codigo, plataforma e comportamento do usuario.
- Qualquer risco de bug deve ser tratado antes de concluir a tarefa.

### 2. Arquitetura Obrigatoria
- Seguir Clean Architecture.
- Seguir organizacao Feature-First.
- Usar Riverpod para gerenciamento de estado e injecao de dependencias.

### 3. Prevencao de Bugs e Excecoes
- Evitar estados invalidos e nulos sem tratamento.
- Nao introduzir loops infinitos, recursao sem limite, ou fluxos sem condicao de parada.
- Nao criar sequencias de chamadas que possam gerar dependencia ciclica.
- Tratar erros explicitamente (falhas de rede, IO, parsing, permissao, timeout, plataforma).
- Garantir fallback seguro para qualquer operacao critica.

### 4. Seguranca e Robustez
- Nao expor dados sensiveis em logs.
- Validar entradas externas e dados vindos de APIs/plataformas.
- Nao confiar em valores dinamicos sem validacao.
- Minimizar superficie de falha e efeitos colaterais.

### 5. Performance Obrigatoria
- Evitar trabalho desnecessario na UI thread.
- Reduzir rebuilds desnecessarios e recomputacoes caras.
- Preferir operacoes eficientes em memoria e CPU.
- Planejar para escalabilidade sem degradar experiencia do usuario.

### 6. Consistencia de Implementacao
- Codigo deve ser legivel, testavel, coeso e com responsabilidades claras.
- Evitar acoplamento alto entre camadas.
- Manter contratos de dominio estaveis e explicitamente tipados.

### 7. Reuso e Anti-Duplicacao Obrigatorios
- Nunca repetir codigo sem necessidade.
- Toda linha nova, principalmente logica reutilizavel, deve acender alerta de reuso.
- Antes de implementar, procurar se ja existe solucao equivalente no projeto.
- Se existir, reutilizar o componente/funcao existente.
- Se nao existir, criar de forma refatorada, modular e reutilizavel para uso futuro em outros pontos.

### 8. Criterio de Entrega
- Uma tarefa so e considerada pronta quando estiver robusta para producao.
- Nao pode haver brechas conhecidas para:
	- Bug funcional
	- Bug de plataforma
	- Comportamento inesperado do usuario

### 9. Documentacao e Idioma de Codigo
- Gerar documentacao somente quando for explicitamente solicitada pelo solicitante ou quando for extremamente importante para operacao, seguranca, manutencao critica ou continuidade do projeto.
- Fora desses casos, nao gerar documentacao adicional.
- Todo codigo tecnico deve estar em ingles (nomes de variaveis, funcoes, classes, arquivos, constantes, providers e contratos).
- Essa regra de ingles permanece obrigatoria ate a implementacao formal do sistema de traducao de UI (i18n/l10n).

### 10. Estabilidade e Warnings Zero
- O aplicativo deve manter baseline de estabilidade maxima, sem instabilidades conhecidas, crashes previsiveis ou comportamentos nao deterministas aceitos.
- Warnings do analyzer/linter devem ser tratados como bloqueadores de entrega e corrigidos antes de concluir qualquer tarefa.
- Nao considerar tarefa pronta enquanto houver warnings ou risco conhecido de instabilidade em fluxo critico.

### 11. Ciclo de Vida de Qualquer Implementacao (Obrigatorio)
- Toda feature, modulo, servico, provider, controller, stream, listener, integracao de plataforma e recurso compartilhado deve possuir ciclo de vida explicitamente definido: criacao, uso, atualizacao, descarte e recuperacao em falha.
- Nenhum componente pode depender de ordem implicita, efeito colateral oculto ou inicializacao acidental para funcionar.
- Qualquer acesso a APIs de plataforma, bindings, plugins, canais nativos, storage local, preferencias, servicos de sistema ou dependencias que exijam contexto Flutter deve ocorrer somente apos a inicializacao explicita do binding apropriado.
- Em apps Flutter, `WidgetsFlutterBinding.ensureInitialized()` deve ser executado no inicio do `main()` antes de qualquer operacao assincrona critica de startup que dependa de plataforma.
- Nao assumir inicializacao implicita por efeito colateral de `runApp()` quando houver pre-carregamento de dependencias no startup.
- Toda alocacao de recurso que exige limpeza (subscriptions, streams, controllers, timers, handles nativos, caches, conexoes e observers) deve possuir estrategia de descarte/cleanup deterministica e testavel.
- Fluxos de reentrada, retomada de app, hot restart/rebuild, reconexao de rede e mudanca de estado de plataforma devem manter comportamento previsivel, sem duplicidade de listeners, vazamento de memoria ou estado invalido.
- A ordem de bootstrap deve ser deterministicamente valida e testavel: inicializar binding, carregar dependencias criticas, validar estado inicial, aplicar fallback seguro, e somente entao iniciar a UI.
- Erros em qualquer fase do ciclo de vida (inicializacao, execucao, atualizacao, descarte) devem ser tratados explicitamente com fallback seguro e sem falhas silenciosas.

## Instrucao Permanente para Agentes
Sempre considerar este documento e [AGENTS.txt](AGENTS.txt) como regras principais antes de propor, gerar ou alterar codigo neste projeto.
