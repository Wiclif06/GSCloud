# Publicação da alteração da Task 648

## Rastreabilidade

- [Task 648](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_workitems/edit/648)
- Branch: `feature/648-mensagem-produtor`
- [Pull request 6](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_git/AgroConecta-GS-2026/pullrequest/6)
- Commit integrado: `7092f0e7bf2f9d12bbebbac405618b07dd5c2fe2`
- [Código no GitHub](https://github.com/Wiclif06/GSCloud/blob/7092f0e7bf2f9d12bbebbac405618b07dd5c2fe2/src/main/java/br/com/fiap/citizentech/cloud/CloudVersionController.java)

A alteração modifica o campo `message` de `/version` para `mensagem de acompanhamento do produtor AB#648`. Os campos `application` e `commit` são preservados.

## Pipelines apresentadas

| Evidência | Execução | Resultado mostrado |
|---|---|---|
| CI após merge na main | [CI-20261120.1, execução 10](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=10) | Sucesso; commit `7092f0e7` |
| Testes publicados da CI | [Resultados da execução 10](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=10&view=ms.vss-test-web.build-test-results-tab) | Etapa de publicação JUnit concluída no job |
| Pacote de Release | [Artefatos da execução 10](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=10&view=artifacts&pathAsName=false) | Etapa de publicação de pacote concluída no job |
| Release pelo artefato da CI | [Release-20261120.1, execução 11](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=11) | Sucesso; acionada automaticamente por CI-20261120.1 |

O job da CI mostra seleção do JDK 21, compilação e testes, validação de perfil prod/CRUD/SELECT/restauração, publicação de JUnit e preparação/publicação do pacote. A Release mostra download do artefato, checksum, publicação do JAR e verificação de health, commit e CRUD em nuvem. Os resultados detalhados permanecem no Azure DevOps e dependem do acesso ao projeto privado.

## Registros da gravação

As imagens abaixo foram extraídas do arquivo de demonstração compartilhado pela equipe. Não são execuções adicionais.

- 21:30: [CI após merge](pr6-ci.jpg)
- 22:00: [Job da CI](pr6-ci-job.jpg)
- 23:30: [Release automática](pr6-release.jpg)
- 24:40: [Resposta de versão e commit](pr6-version.jpg)
- 25:15: [Health UP](pr6-health.jpg)

[Gravação compartilhada](https://drive.google.com/file/d/1rYF8QrBoP4zz8mvWbLlZNkwOMcHOt96-/view?usp=sharing)

## Evidência SQL anterior

O arquivo [ensaio-azure-19-11-2026.txt](ensaio-azure-19-11-2026.txt) registra um ensaio anterior de CRUD com consultas SQL nas quatro entidades. Ele não corresponde às operações manuais do trecho final da gravação. A aprovação da CI/Release e esse ensaio anterior não substituem a demonstração direta de SELECT no vídeo solicitado pela disciplina.
