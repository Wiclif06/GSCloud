# Publicação AgroConecta no Azure

Execute na raiz do pacote, em PowerShell 7.4 ou superior. Para a sequência guiada, preencha config/implantacao.local.json e use scripts/iniciar-azure.ps1, conforme ANTES-DO-AZURE.md. Confira assinatura, região, quotas e permissões antes do provisionamento.

## 1. Pré-requisitos

JDK 21; Git; Azure CLI atual com extensão azure-devops; PowerShell 7. Para executar a suíte completa: Docker em funcionamento. O Microsoft-hosted agent ubuntu-latest da CI é a opção configurada para os testes com containers.

```powershell
./scripts/validar-containers.ps1
az login
az account list -o table
```

Se não houver Docker na máquina local, ainda é possível compilar e rodar os testes independentes, conforme VALIDACAO.md. A integração completa é executada com Docker.

## 2. Segredos e provisionamento

Crie segredos diferentes, aleatórios, com pelo menos 32 caracteres. Carregue sem imprimir:

```powershell
$env:POSTGRES_PASSWORD = Read-Host 'Senha PostgreSQL (32+ caracteres)' -MaskInput
$env:RABBITMQ_PASSWORD = Read-Host 'Senha RabbitMQ (32+ caracteres)' -MaskInput
$env:JWT_SECRET = Read-Host 'Segredo JWT (32+ caracteres)' -MaskInput
$subscription = Read-Host 'ID da assinatura Azure'
$prefix = Read-Host 'Prefixo único: 6 a 18 caracteres, letras minúsculas, números e hífen'
./scripts/provisionar-azure.ps1 -SubscriptionId $subscription -Prefix $prefix
$infra = Get-Content infra-output.json -Raw | ConvertFrom-Json
```

O padrão de região é eastus. Altere `-Location` se houver restrição na assinatura. O prefixo também gera nomes de Storage Account e ACR: precisa ser único globalmente. A conta deve ter permissão de criar recursos e de atribuir AcrPull à identidade gerenciada (Owner ou Contributor com permissão de atribuição RBAC adequada). Se o provedor não estiver registrado, registre Microsoft.Web, Microsoft.ContainerInstance, Microsoft.ContainerRegistry, Microsoft.ManagedIdentity, Microsoft.Storage e Microsoft.Network na assinatura.

Recursos criados:

| Recurso | Uso |
|---|---|
| Resource Group | Agrupa somente recursos da GS |
| App Service Plan B1 Linux / Web App Java 21 | API Spring Boot |
| VNet com duas subnets delegadas | Integração do App Service e grupo ACI privado |
| NAT Gateway + Public IP Standard | Saída de rede do ACI, conforme requisito da plataforma |
| ACR Basic + identidade gerenciada com AcrPull | Imagens PostgreSQL/PGvector e RabbitMQ |
| Grupo ACI privado | Banco PostgreSQL 16 e RabbitMQ 4.1 |
| Storage Account Standard LRS / Azure Files | Snapshots lógicos do PostgreSQL |

O script executa `az acr build` dos Dockerfiles e cria o grupo de containers. O armazenamento transacional do PostgreSQL fica no container; a share recebe pg_dump, evitando usar diretamente SMB como PGDATA. Veja ARQUITETURA-CLOUD.md para a recuperação e a janela de perda possível.

O script não recria um grupo ACI existente. Para retomar um provisionamento interrompido, use os mesmos parâmetros e segredos com `-ResumeProvisioning`. Isso reaplica configurações e preserva o grupo ACI já existente. Se o grupo ACI estiver em estado Failed ou sem IP privado, inspecione a causa no Portal antes de prosseguir; não exclua dados existentes sem backup. Depois do primeiro provisionamento, alterações de código são feitas pela Release.

O arquivo local infra-output.json contém nomes/endereço sem segredos e fica fora do Git. PG/broker não têm endpoint público. Não abra 5432 ou 5672 na internet. As configurações do App Service mantêm DB_URL/DB_USERNAME/DB_PASSWORD, RABBITMQ_HOST/USERNAME/PASSWORD, JWT_SECRET e o perfil prod.

### Habilitar a orientação Gemini original

Opcional para o CRUD e cálculos determinísticos, necessário para demonstrar a orientação real de IA:

```powershell
$env:GOOGLE_API_KEY = Read-Host 'Chave Gemini da equipe' -MaskInput
# Adicione -EnableAi à chamada de provisionamento inicial.
```

Para habilitar a integração, configure GOOGLE_API_KEY e APP_AI_ENABLED=true no App Service de forma segura e reinicie a aplicação; confira a ingestão do corpus e a chamada real seguindo o README original. Use os mesmos parâmetros/segredos se optar por -ResumeProvisioning -EnableAi. Os provedores de teste ficam restritos à suíte de testes.

## 3. Organização, projeto e professor

Crie ou selecione a organização real no Azure DevOps. Depois:

```powershell
$org = Read-Host 'URL real da organização: https://dev.azure.com/...'
$reviewer = Read-Host 'E-mail da conta do representante RM563901'
$professor = Read-Host 'E-mail confirmado do professor de Cloud'
./scripts/configurar-devops.ps1 -Organization $org -ReviewerEmail $reviewer -ProfessorEmail $professor
```

Se necessário, autentique a extensão por `az devops login --organization $org`, fornecendo o PAT no prompt seguro. O script cria AgroConecta-GS-2026 privado/Git, registra uma Task e solicita convite Basic (`express` na CLI). Não confunda acesso ao Azure DevOps com acesso à assinatura Azure.

Confira na interface:

- Organization settings > Users: professor com **Basic**, convite aceito.
- Project settings > Permissions > Project Administrators > Members: professor incluído.
- Professor consegue abrir Boards, Repos e Pipelines do projeto privado. Stakeholder não atende à rubrica.

## 4. Bootstrap e main protegida

O script informa a URL real e o ID da tarefa. Execute os comandos de primeiro push com esses dados. Exemplo, substituindo o ID e a URL:

```powershell
git init -b main
git add .
git commit -m 'feat: AgroConecta Cloud AB#ID_REAL'
git remote add origin URL_REAL_DO_AZURE_REPOS
git push -u origin main
```

Depois execute o comando de `scripts/proteger-main.ps1` que foi exibido, com ID real do repositório e e-mail do representante. Confira em Repos > Branches > main > Branch policies:

1. Require a minimum number of reviewers: 1 e obrigatório.
2. Allow requestors to approve their own changes: marcado para a simulação permitida.
3. Prohibit the most recent pusher from approving: desmarcado para a simulação.
4. Check for linked work items: Required.
5. Automatically included reviewers: conta do representante RM563901, Required, todos os arquivos. O script também aplica a autoaprovação dessa política pela configuração REST; confira o valor na interface.
6. Não conceda bypass de políticas à equipe.

Crie a branch de demonstração a partir do Development da nova Task, para o vínculo ficar explícito. Commits usam AB#ID e a PR deve conter a Task em Work items.

Build Validation deve permanecer desativada neste fluxo: a rubrica pede Build depois do merge via PR. O YAML usa trigger em main e pr:none. Com as políticas sem bypass, o push direto na main fica bloqueado; cada merge dispara a CI.

## 5. Conexão, Library e Environment

Project settings > Service connections > New > Azure Resource Manager. Prefira Workload Identity Federation, assinatura da equipe e Resource Group criado pelo script. Nome exato: **sc-agroconecta-azure**. A identidade precisa de Contributor no Resource Group para a publicação do App Service. Autorize a Release a utilizar a conexão.

Pipelines > Library: crie **agroconecta-prod**, contendo:

| Variável | Valor |
|---|---|
| RESOURCE_GROUP | valor real de infra-output.json |
| WEBAPP_NAME | valor real de infra-output.json |

As credenciais do banco/broker/JWT ficam nas configurações de ambiente dos serviços criados pelo script; a pipeline de Release não precisa repetir esses segredos. Caso acrescente segredos à Library, marque-os como Secret e mapeie-os explicitamente por env. Nunca os escreva no YAML.

Pipelines > Environments: crie **agroconecta-prod**, sem recurso, e autorize a Release. Resolva também a autorização do Variable Group e da pipeline resource `ci`. Não coloque aprovação manual no ambiente da demonstração, pois o fluxo precisa rodar automaticamente.

## 6. Criar as duas pipelines

Use scripts/criar-pipelines.ps1 com organização, projeto e ID real do repositório, ou a interface Existing Azure Pipelines YAML file:

| Nome exato | Caminho |
|---|---|
| AgroConecta-CI | /azure-pipeline.yml |
| AgroConecta-Release | /azure-release.yml |

Configure default branch como **refs/heads/main** nas duas pipelines. A Release referencia source: AgroConecta-CI, baixa drop daquela execução, verifica SHA256, publica app.jar e espera health UP e /version com o commit esperado. O Flyway faz as migrações ao iniciar o JAR. A Release não recompila e não recria a infraestrutura.

O teste manual Gemini não roda na CI sem opt-in; os demais testes, inclusive Testcontainers, rodam pelo `clean verify`. Em seguida, scripts/validar-containers.ps1 -SkipMaven valida o perfil prod, as migrações, CRUD com SELECT e restauração de snapshot usando o mesmo JAR e Dockerfiles do pacote. Essa etapa também precisa passar antes da publicação do artefato. O Azure DevOps precisa ter paralelismo de agentes disponível. Se a organização não tiver concessão, solicite a habilitação ou configure um agente próprio Linux com JDK 21, Docker, Bash, Azure CLI e PowerShell 7, alterando pool por PR.

## 7. Ensaio, SELECT e backup

Faça uma Task/branch/PR de ensaio e confira o fluxo inteiro. No vídeo, crie outra Task e faça uma alteração no texto de CloudVersionController.java. Mostre a alteração já publicada em /version e o commit real do JAR.

Para o CRUD e SELECT:

```powershell
$infra = Get-Content infra-output.json -Raw | ConvertFrom-Json
./scripts/smoke-test.ps1 -BaseUrl $infra.APP_URL -PauseForSql -ResourceGroup $infra.RESOURCE_GROUP -ContainerGroup $infra.CONTAINER_GROUP
```

O script consulta diretamente o banco por Azure CLI exec. Se o terminal/cliente não conseguir abrir a sessão interativa do ACI, use Portal > Container group > Containers > postgres > Connect e execute `/usr/local/bin/agro-evidence FARM_ID CROP_ID SENSOR_ID ACTIVITY_ID` com os IDs exibidos. O utilitário imprime o SQL e os resultados sem mostrar senha ou hash de usuário.

Após a gravação:

```powershell
./scripts/backup-banco.ps1 -ResourceGroup $infra.RESOURCE_GROUP -ContainerGroup $infra.CONTAINER_GROUP
```

Confira latest.sql e latest.utc na share postgres-backups do Storage Account. Não exponha credenciais na interface. O banco mantém snapshots periódicos; alterações posteriores ao último snapshot podem ser perdidas. Não apague os recursos antes da correção e da apresentação.

## Diagnóstico

| Falha | Conferência |
|---|---|
| ACR Tasks não autorizado | Quota/recursos da assinatura para az acr build; permissão de build no registry |
| ACI não puxa imagem | Identidade atribuída, AcrPull no ACR, propagação RBAC e imagem gs2026 existente |
| ACI privado sem saída | NAT Gateway associado à subnet containers e região compatível |
| API não conecta PG/broker | IP privado real, integração VNet, estado dos containers e segredos iguais aos do provisionamento |
| Aplicação não sobe | Logs App Service, JWT_SECRET, perfil prod e migrações Flyway |
| CI falha em Testcontainers | Docker ativo e acessível no agente; imagem pgvector/pgvector:pg16 e rabbitmq:4.1-management disponíveis |
| Release não dispara | Nome AgroConecta-CI, default branch, trigger da resource e permissões |
| CRUD retorna 401 | JWT deve ser emitido pelo login da aplicação publicada; não reutilize token antigo |
| PR não conclui | Work item, revisor padrão e duas configurações de autoaprovação; ou outro integrante abre a PR e o representante aprova |
| Snapshot falha | Share montada em /backup, acesso ao Storage Account e espaço livre |

O ambiente deve passar por esse ensaio completo antes de gerar o PDF final.
