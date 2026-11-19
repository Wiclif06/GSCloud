# Relatório de verificação

Data: 17/11/2026. Base do código: `5930f02f21d367bb3ea4b19d16d74d7719b7fbe8`.

| Verificação | Resultado | Escopo |
|---|---|---|
| Compilação Java 21 e JAR | Aprovada | Aplicação e fontes de testes |
| Testes independentes de Docker | 46 aprovados | 11 classes; 0 falhas, 0 erros e 0 ignorados |
| Sintaxe PowerShell e shell | Aprovada | Scripts do pacote |
| YAML, JSON e caminhos | Aprovada | Arquivos de pipeline, configuração e exemplos |
| Políticas em simulação de CLI | Aprovada | Três políticas, repetição sem duplicatas e autoaprovação |
| Documento PDF | Conferido | Layout, integrantes e campos de formulário |
| Integração e restauração Docker | Não executadas | Docker indisponível no ambiente de verificação |
| Implantação e validação Azure | Não executadas | Dependem da assinatura e organização da equipe |

## Testes locais

```powershell
./mvnw.cmd '-Dtest=JwtPropertiesTests,AiConfigurationTests,RagAndPromptTests,OutboxUnitTests,ProfileValidationTests,RainfallCalculatorTests,SensorHealthTests,WaterIndicatorsTests,WaterRiskCalculatorTests,JobGuidanceTests,CloudVersionControllerTests' package
```

Os testes cobrem configuração, contexto RAG, JWT, outbox, orientação, perfis, chuva, saúde de sensores, indicadores hídricos, cálculo de risco e versão da aplicação. Resultados por classe: [testes-locais.json](docs/testes-locais.json).

## Verificação completa

```powershell
./scripts/validar-containers.ps1
```

Requer JDK 21, PowerShell 7.4+ e Docker Linux. Executa Maven completo, aplicação com perfil prod, migrações, CRUD com SELECT e recuperação de snapshot em banco novo. Relatórios: `target/surefire-reports` e `target/cloud-reports`.

A CI executa essa sequência antes de publicar o artefato. A montagem de Azure Files, a conectividade privada, as permissões e o funcionamento dos serviços devem ser conferidos no ensaio de implantação. A verificação estática está registrada em [verificacao-arquivos.json](docs/verificacao-arquivos.json).
