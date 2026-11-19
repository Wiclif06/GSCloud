# Requisitos e evidências

A matriz relaciona os requisitos da disciplina aos arquivos e às evidências da implantação.

| Nº | Requisito | Implementação/conferência |
|---|---|---|
| 01 | Projeto privado/Git | configurar-devops.ps1; conferir acesso real |
| 02 | Boards com branch, commit e PR | Task Development + AB#ID + Work items da PR |
| 03 | main protegida e revisor RM | proteger-main.ps1; conta real RM563901 |
| 04 | Build após merge via PR | trigger main + políticas sem bypass |
| 05 | Autoaprovação permitida | políticas e opção do revisor incluído |
| 06 | Release automática pelo artefato | azure-release.yml resource AgroConecta-CI |
| 07 | Aplicação em nuvem | App Service Linux Java 21 |
| 08 | Banco em modalidade permitida | PostgreSQL/PGvector em ACI, imagens ACR |
| 09 | Infraestrutura versionada | scripts/ e dockerfiles/ |
| 10 | DDL no caminho exigido | scripts/script-bd.sql; migrações Flyway originais |
| 11 | Azure CLI em scripts | scripts/provisionar-azure.ps1 |
| 12 | Dockerfiles em dockerfiles | postgres.Dockerfile e rabbitmq.Dockerfile |
| 13 | YAML CI na raiz | azure-pipeline.yml |
| 14 | JSON/Swagger | Swagger existente + README, requests/ e postman/ |
| 15 | Variáveis de ambiente | env da CI/Release e configurações seguras dos serviços |
| 16 | Arquitetura macro | docs/arquitetura-cloud.png e .svg no README |
| 17 | Testes automáticos | clean verify + prod/CRUD/SELECT/restauração + publicação JUnit na CI |

## Pontuação

Arquitetura: 10; Boards/Repos: 10; Build: 25; Release: 25; apresentação presencial: 30. Entrega técnica: 70 pontos. Apresentação presencial: 30 pontos.

## Conferência antes do envio

- [ ] Aplicação AgroConecta completa no Azure Repos privado, usando a mesma solução das outras disciplinas.
- [ ] Professor com Basic, convite aceito e Project Administrators; acesso a Boards, Repos e Pipelines.
- [ ] Recursos criados por Azure CLI e correspondentes ao desenho.
- [ ] PostgreSQL em container ACI/ACR, com dados e migrações aplicadas.
- [ ] Snapshots e recuperação ensaiados; não recriar grupo de banco no deploy da API.
- [ ] main protegida e nova branch vinculada à Task.
- [ ] Mudança em CloudVersionController.java, commit AB# e PR revisada/vinculada.
- [ ] CI automática após merge, suíte completa aprovada e resultados/pacote publicados.
- [ ] Release automática pelo artefato, mesmo JAR, Flyway, health e commit confirmados.
- [ ] Variáveis de ambiente sem valores secretos no código ou no vídeo.
- [ ] CRUD de cada entidade de negócio demonstrada, com SELECT direto em nuvem após as operações.
- [ ] Mostrar também os módulos originais usados pela equipe; incluindo perfis, leituras, jobs e alertas.
- [ ] Vídeo narrado, contínuo, sem aceleração, 720p ou superior, incluindo as etapas das pipelines.
- [ ] /version em nuvem com alteração visível e commit esperado.
- [ ] Task concluída com links, histórico, branch, commit e PR.
- [ ] YouTube acessível e vídeo assistido integralmente após publicar.
- [ ] PDF com grupo, nomes/RMs e links reais da organização e vídeo, abrindo corretamente.
- [ ] Recursos e acesso mantidos até o término da avaliação/apresentação.
- [ ] Todos os integrantes revisaram o código e conseguem responder às perguntas presenciais.

O roteiro demonstra quatro tabelas com CRUD completo (farms, crop_areas, sensors, field_activities), superando o mínimo de duas tabelas da gravação. As demais tabelas da aplicação têm semântica de autenticação, histórico, auditoria, processamento ou vetores; não se deve inventar endpoints de DELETE para remover trilhas e infringir as regras de negócio. Demonstre seus fluxos existentes e respectivas consultas quando fizerem parte da apresentação, conforme orientação do professor.
