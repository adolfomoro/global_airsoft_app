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

## Instrucao Permanente para Agentes
Sempre considerar este documento e [AGENTS.txt](AGENTS.txt) como regras principais antes de propor, gerar ou alterar codigo neste projeto.
