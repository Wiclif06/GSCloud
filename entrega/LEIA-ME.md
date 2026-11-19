# PDF para o portal

O documento reúne a identificação do grupo, os integrantes e a arquitetura. Os campos da organização Azure DevOps e do vídeo no YouTube são preenchíveis e devem receber os links da implantação.

Para gerar o documento definitivo, instale Python 3 e execute na raiz do pacote:

```powershell
python -m pip install reportlab
$org = Read-Host 'URL real da organização Azure DevOps'
$video = Read-Host 'URL real do vídeo no YouTube'
python entrega/gerar-entrega.py --org $org --video $video
```

O arquivo AgroConecta_rm563901.pdf será gerado nesta pasta, com os integrantes e links clicáveis. O script verifica o formato das URLs; confira manualmente a abertura, a disponibilidade do vídeo e as permissões do professor. Não envie o modelo com campos vazios.

Alternativa: preencha os dois campos do modelo em um leitor de PDF que salve formulários. Reabra o arquivo salvo para conferir o conteúdo. A versão gerada pelo script é preferível porque inclui os links clicáveis.
