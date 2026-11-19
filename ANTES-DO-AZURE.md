# Validação e implantação

As etapas a seguir validam a aplicação e configuram os recursos do AgroConecta no Azure.

## 1. Validar a aplicação e os containers

Com JDK 21, PowerShell 7.4+ e Docker com engine Linux em funcionamento, abra a raiz do pacote:

```powershell
./scripts/validar-containers.ps1
```

O comando executa a suíte Maven completa, constrói as mesmas imagens de banco/broker usadas no Azure, sobe o JAR com perfil prod e confere:

- migrações Flyway versionadas;
- health da aplicação;
- CRUD de quatro entidades com SELECT e valores conferidos no PostgreSQL;
- snapshot do banco, remoção apenas do container de teste e restauração em PGDATA vazio;
- recuperação do histórico Flyway e da aplicação.

O relatório JUnit fica em target/cloud-reports. O ambiente de teste usa um nome exclusivo, porta local aleatória e segredos descartáveis; é removido no final. A execução não cria recursos Azure. A CI executa essa mesma verificação antes de publicar o artefato. Docker Linux é um pré-requisito dessa verificação.

## 2. Informar os dados do ambiente

```powershell
Copy-Item config/implantacao.example.json config/implantacao.local.json
```

Edite o arquivo local com ID da assinatura, prefixo único, região, URL da organização, nome do projeto, e-mail da conta do representante e e-mail confirmado do professor. O arquivo não aceita campos de senha ou API key e está no .gitignore. Use segredos diferentes, aleatórios e com 32 ou mais caracteres para PostgreSQL, RabbitMQ e JWT.

## 3. Ordem única quando for iniciar o Azure

```powershell
az login
./scripts/iniciar-azure.ps1 -Etapa Infraestrutura
./scripts/iniciar-azure.ps1 -Etapa DevOps
```

O provisionamento pede os segredos em entrada mascarada quando não estiverem no ambiente. Guarde-os no gestor de senhas da equipe para reutilizar em uma eventual retomada. A etapa DevOps mostra os comandos do primeiro push, com URL e ID da Task reais. Faça esse primeiro push antes de proteger a branch.

Depois:

```powershell
./scripts/iniciar-azure.ps1 -Etapa Politicas
./scripts/iniciar-azure.ps1 -Etapa Pipelines
```

Configure sc-agroconecta-azure, Variable Group/Environment agroconecta-prod e as autorizações conforme docs/AZURE.md. Faça uma PR de ensaio para disparar a CI e a Release automaticamente. O cadastro/atualização de pipelines não as executa manualmente para simular a demonstração.

## 4. Gravação e documento final

Siga docs/ROTEIRO-VIDEO-CLOUD.md, mostrando as etapas reais sem cortes. Os links da organização e do vídeo serão preenchidos depois da publicação. Use entrega/gerar-entrega.py para montar o PDF final; não envie o modelo com os campos vazios.

O script de teste de restauração utiliza volume Docker local. A montagem da share no ACI, o acesso à conta e a recuperação em Azure precisam ser conferidos no ensaio real. O backup continua sendo por snapshots; ele não se transforma em armazenamento transacional síncrono ou garantia de perda zero.
