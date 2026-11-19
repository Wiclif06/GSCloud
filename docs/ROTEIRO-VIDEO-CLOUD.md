# Gravação Cloud/DevOps com AgroConecta

Use pelo menos 720p (preferível 1080p), microfone claro, sem cortes e sem aceleração. Narre durante a execução. Não substitua a voz por legendas. Faça antes uma PR de ensaio e resolva todas as permissões de pipeline e conta.

1. Apresente README, grupo e proposta do AgroConecta. Mostre arquitetura com ícones oficiais e explique App Service, ACI, ACR, VNet, NAT, Azure Files, PGvector e RabbitMQ.
2. No Portal Azure, exiba os recursos correspondentes ao provisionamento e o script Azure CLI. Não abra valores secretos.
3. Mostre projeto privado, professor Basic e Project Administrators e as políticas da main.
4. Crie ao vivo uma nova Task: “Atualizar mensagem de acompanhamento do produtor”. Registre critérios: mensagem alterada no código, PR vinculada, CI/Release automáticas, nova versão em nuvem e CRUD/SELECT.
5. Na seção Development da Task, crie branch `feature/ID-mensagem-produtor` com base main. No terminal: `git fetch origin` e `git switch --track origin/feature/ID-mensagem-produtor`.
6. Altere a mensagem em `src/main/java/br/com/fiap/citizentech/cloud/CloudVersionController.java`. Exemplo: “AgroConecta: informação para cuidar de cada cultivo.”. Mostre o diff; não use apenas o README.
7. Faça commit com AB#ID_REAL, push e PR para main com a Task vinculada. Mostre o revisor padrão, aprove e conclua respeitando as políticas.
8. Mostre a CI surgindo automaticamente após o merge. Explique seleção JDK 21, Maven Wrapper, testes unitários e de integração com Testcontainers. Mostre também a validação de perfil prod, CRUD/SELECT e restauração em um PostgreSQL novo, executada antes de publicar o pacote. Abra JUnit e os arquivos do artefato drop: app.jar, commit.txt, checksum, DDL, migrações e relatórios.
9. Mostre a Release automática originada por aquele artefato. Acompanhe download, checksum, deploy do JAR, Flyway ao iniciar, health, comparação do commit e smoke test. Narre cada etapa durante a espera.
10. Abra /version na URL HTTPS real e confira a frase alterada e o commit da CI. Mostre /actuator/health e Swagger da aplicação publicada.
11. Execute CRUD nas quatro entidades com as pausas de SELECT indicadas abaixo. Mostre o banco diretamente no ACI, e não apenas respostas GET/Swagger.
12. Demonstre também os módulos relevantes já construídos pelo grupo, conforme DEMONSTRACAO-FUNCIONAL.md. Não apresente uma resposta de teste como orientação real de IA; configure a chave se for demonstrar essa funcionalidade.
13. Volte à Task: mostre branch, commits, PR e histórico; conclua a tarefa em Closed. Faça snapshot final do banco e mantenha o ambiente disponível.

## Comandos da alteração

Substitua ID_REAL e a branch pelos criados ao vivo:

```powershell
git fetch origin
git switch --track origin/feature/ID_REAL-mensagem-produtor
# Edite CloudVersionController.java e salve.
git diff
git add src/main/java/br/com/fiap/citizentech/cloud/CloudVersionController.java
git commit -m 'feat: mensagem ao produtor AB#ID_REAL'
git push -u origin HEAD
```

## CRUD e SELECT

```powershell
$infra = Get-Content infra-output.json -Raw | ConvertFrom-Json
./scripts/smoke-test.ps1 -BaseUrl $infra.APP_URL -PauseForSql -ResourceGroup $infra.RESOURCE_GROUP -ContainerGroup $infra.CONTAINER_GROUP
```

O script mantém senha/JWT em memória e imprime somente etapas e IDs. Não faça Write-Output das variáveis de autenticação. Em cada pausa, a consulta roda por psql no container PostgreSQL em nuvem. Confirme que o contexto da tela mostra o ACI real do grupo. Se necessário, conecte pelo Portal ao container postgres e execute `/usr/local/bin/agro-evidence FARM_ID CROP_ID SENSOR_ID ACTIVITY_ID`.

| Tabela | CREATE | READ | UPDATE | DELETE |
|---|---|---|---|---|
| farms | ID e nome inicial | Linha persistida | Mesmo ID, nome novo | SELECT vazio |
| crop_areas | ID e farm_id | Relação com propriedade | Nome/área alterados | SELECT vazio |
| sensors | ID e crop_area_id | Dados do dispositivo | Status INACTIVE | SELECT vazio |
| field_activities | ID e cultivo | Registro persistido | Quantidade 25 | SELECT vazio |

São 16 momentos de conferência. O script exclui atividades e sensores antes da área e da propriedade, respeitando as FKs. O usuário sintético permanece registrado. Não exponha password_hash ou tokens nas consultas.

## Preparação final do vídeo/PDF

Assista à gravação inteira já publicada no YouTube, como não listado. Teste o link em janela anônima. Confira áudio, resolução, continuidade, execução completa da CI/Release, alteração publicada, SELECTs e vínculos no Boards. Verifique o acesso do professor novamente. Preencha os links reais no PDF ou execute o gerador. A apresentação presencial exige que todos compreendam o projeto, o fluxo DevOps e as limitações da infraestrutura.
