# Verificação do ambiente Cloud

## Publicação da Task 648

A versão demonstrada na gravação utiliza o commit 7092f0e7bf2f9d12bbebbac405618b07dd5c2fe2, integrado pela PR 6. A CI-20261120.1 (execução 10) e a Release-20261120.1 (execução 11) aparecem concluídas com sucesso. A Release é acionada pela CI correspondente.

Consulte as [evidências e links da publicação](docs/evidencias/PR6.md). O código desse commit está sincronizado no GitHub. A documentação e o PDF podem ter commits posteriores sem alterar o JAR publicado.

## Histórico de verificação anterior

Os resultados numéricos abaixo pertencem ao ensaio anterior, no commit indicado. Não representam uma nova medição da execução 10 nem comprovam por si só o CRUD manual no vídeo.

Conferência realizada em 19/11/2026 no projeto AgroConecta-GS-2026. A compilação implantada na conferência corresponde ao commit `9d7418d5536db4a213cb18cbea3e99387ae5ee75`.

| Verificação | Resultado | Evidência |
|---|---|---|
| Compilação Java 21 e JAR | Aprovada | CI-20261119.2, execução 2 |
| Suíte Maven com Testcontainers | 183 testes, 182 aprovados, 1 ignorado, zero falhas e erros | O teste ignorado é GeminiManualTests, que depende de chamada manual ao provedor |
| Perfil prod e migrações | Aprovados | Etapa de validação de containers na CI |
| CRUD com SELECT em Docker | 16 operações aprovadas | Quatro entidades, com valores conferidos após atualizar e exclusão confirmada por SQL |
| Restauração em Docker | Aprovada | Snapshot restaurado em PostgreSQL novo e aplicação recuperada |
| Resultados JUnit publicados | 186 testes, 185 aprovados, 1 ignorado, zero falhas | Suíte Maven e três verificações adicionais de preparação |
| Artefato drop | Publicado | app.jar, SHA256SUMS, commit.txt, scripts, migrações e testes |
| Release automática | Aprovada | Release-20261119.1, execução 3, disparada pela CI 2 e consumindo seu artefato |
| API em nuvem | UP e commit conferido | Health e /version no App Service |
| CRUD e SELECT no Azure | 16 operações aprovadas | Ensaio direto no PostgreSQL do ACI com dados sintéticos e limpeza dos registros de negócio ao final |
| Banco e broker | Running | postgres e rabbitmq no ACI privado, imagens do ACR da equipe |
| Snapshots PostgreSQL | Em operação | Registro de snapshots no volume de backup e comando de snapshot executado no ACI |
| Professor | Basic e Project Administrators configurados | Configurações da organização e do projeto |

## Execuções verificadas

- [CI 2](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=2)
- [Testes publicados](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=2&view=ms.vss-test-web.build-test-results-tab)
- [Artefato da CI](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=2&view=artifacts&pathAsName=false)
- [Release 3](https://dev.azure.com/RM563254/AgroConecta-GS-2026/_build/results?buildId=3)
- [Ensaio SQL no ACI](docs/evidencias/ensaio-azure-19-11-2026.txt)

## Executar a demonstração

Use PowerShell 7.4 ou superior com Azure CLI autenticado na assinatura da equipe:

```powershell
./scripts/gravar-crud-azure.ps1
```

O script executa as quatro operações nas quatro entidades e apresenta os SELECTs diretamente no PostgreSQL em nuvem, com pausas para explicação. Não imprime senha nem JWT. Usa dados sintéticos exclusivos e remove os registros de negócio criados ao terminar; o usuário de teste permanece sem fazendas vinculadas.

## Persistência

Os snapshots lógicos são periódicos, em Azure Files. Alterações posteriores ao último snapshot podem ser perdidas. O teste de recuperação aprovado recria o banco descartável em Docker; não foi feita recriação destrutiva do banco Azure para esta conferência. A existência de snapshots não representa alta disponibilidade nem perda zero.

## Registro anterior

Os arquivos testes-locais.json e verificacao-arquivos.json, em docs, registram a etapa anterior à implantação. A contagem de 46 testes independentes de Docker pertence àquela verificação local. Os resultados de CI e Azure acima correspondem à implantação real de 19/11/2026.
