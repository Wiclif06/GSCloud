# Gravação de Cloud e DevOps

O ambiente está na organização RM563254, projeto AgroConecta-GS-2026. A gravação deve ser contínua, narrada, sem cortes ou aceleração e com pelo menos 720p. Faça a criação da Task, a alteração Java e o merge durante a gravação.

## Preparação

Abra o README, o desenho macro, o Portal Azure, Boards, Repos, Pipelines, Swagger e /version. Confira o microfone e use resolução que permita ler os resultados. Deixe a conta do representante Felipe RM563901 disponível para aprovar a PR. A conta do Lucas pode abrir a PR; a aprovação obrigatória será feita pelo Felipe. Não remova o representante, não desative políticas e não use bypass.

## Sequência ao vivo

1. Apresente os integrantes, a proposta e a arquitetura do README.
2. Mostre o grupo rg-agro563901gs e os recursos criados pelos scripts: App Service, ACR, ACI, identidade, VNet, NAT e armazenamento. Não abra segredos.
3. No Boards, crie uma nova Task chamada Atualizar a mensagem de acompanhamento do produtor. Descreva os critérios: alteração Java, PR revisada pelo representante, CI e Release automáticas, mensagem e commit em nuvem e CRUD/SELECT nas quatro entidades. Atribua o responsável e inicie o trabalho.
4. Em Development da Task, crie a branch feature/ID-mensagem-produtor, baseada na main. Use o ID numérico real da Task.
5. Edite src/main/java/br/com/fiap/citizentech/cloud/CloudVersionController.java na branch. Troque somente a mensagem por AgroConecta: informação para cuidar de cada cultivo. Mostre o diff. Preserve application, commit e o contrato da API.
6. Faça commit com a mensagem feat: mensagem de acompanhamento do produtor AB#ID. Abra PR para main e confirme a Task vinculada e Felipe como revisor Required.
7. Na conta do Felipe, revise a alteração e aprove a PR. Conclua respeitando as políticas. Acompanhe a CI surgindo depois do merge; não a inicie manualmente para substituir o gatilho.
8. Explique cada tarefa da CI, os testes Maven e Testcontainers, a validação de perfil prod, CRUD/SQL e recuperação. Mostre a aba Tests e o artefato drop.
9. Acompanhe a Release disparada automaticamente por essa execução da CI. Mostre que ela baixa o mesmo artefato, confere checksum, publica o JAR e verifica health, commit e CRUD.
10. Abra https://app-agro563901gs.azurewebsites.net/version e mostre a nova frase e o commit publicado. Mostre também health e Swagger.
11. Execute o CRUD abaixo. Explique cada resposta e cada SELECT no PostgreSQL do ACI. Depois de atualizar, mostre o valor novo; depois de excluir, mostre zero linhas. São 16 conferências, envolvendo farms, crop_areas, sensors e field_activities.
12. Volte à Task criada ao vivo, mostre histórico, branch, commits, PR e os vínculos. Conclua a Task depois de atender os critérios.
13. Gere o snapshot final e mantenha o ambiente disponível para correção e apresentação.

## CRUD com os endereços da equipe

Execute na raiz do repositório com PowerShell 7.4 ou superior e Azure CLI autenticado:

```powershell
./scripts/gravar-crud-azure.ps1
```

Cada pausa executa o SQL no PostgreSQL pelo Azure CLI. A tela informa o grupo e os IDs. Narre o resultado e pressione Enter para a próxima operação. O script cria e limpa somente seus dados de negócio sintéticos. O cadastro do usuário de teste permanece sem fazendas.

Caso prefira o Portal, use o container postgres do ACI e o comando /usr/local/bin/agro-evidence FARM_ID CROP_ID SENSOR_ID ACTIVITY_ID com os IDs exibidos. Não substitua os SELECTs por respostas GET. A aba Conectar pode depender da conectividade do navegador; o caminho Azure CLI já foi conferido.

## Snapshot final

```powershell
./scripts/backup-banco.ps1 -ResourceGroup rg-agro563901gs -ContainerGroup aci-agro563901gs
```

## PDF e publicação

O PDF em entrega/AgroConecta_rm563901.pdf já contém a organização https://dev.azure.com/RM563254/. Depois de publicar o vídeo no YouTube, revise toda a gravação, confira no mínimo 720p e áudio claro, teste o acesso ao link e preencha o único campo restante. Confira nomes, RMs, links e o comprovante de envio no Portal do Aluno.
